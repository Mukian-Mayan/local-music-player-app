import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/playlist.dart';
import '../models/song.dart';

enum SortMode { titleAsc, artistAsc, recentlyAdded }

/// Owns the music library: automatic device scanning, tag reading,
/// favorites, playlists, search and sort. All of it is persisted except
/// the scanned song list itself, which is rebuilt (quickly) on each scan.
class LibraryService extends ChangeNotifier {
  final List<Song> library = [];
  final Set<String> _favoritePaths = {};
  final List<Playlist> playlists = [];

  bool isScanning = false;
  String? scanError;
  String searchQuery = '';
  SortMode sortMode = SortMode.titleAsc;

  static const _favKey = 'favorite_paths';
  static const _playlistKey = 'playlists_json';

  // Common public folders on Android where music typically lives. Direct
  // path access to these (rather than the MediaStore API) is simpler and
  // works on most real devices once permission is granted, but isn't
  // guaranteed on every device or Android version -- hence the manual
  // "Add songs" fallback everywhere in the UI.
  static const _scanRoots = [
    '/storage/emulated/0/Music',
    '/storage/emulated/0/Download',
    '/storage/emulated/0/Downloads',
    '/storage/emulated/0/Recordings',
  ];

  bool isFavorite(Song s) => _favoritePaths.contains(s.path);
  List<Song> get favorites => library.where(isFavorite).toList();

  List<Song> get visibleLibrary {
    var list = library.where((s) {
      if (searchQuery.isEmpty) return true;
      final q = searchQuery.toLowerCase();
      return s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q) ||
          s.album.toLowerCase().contains(q);
    }).toList();

    switch (sortMode) {
      case SortMode.titleAsc:
        list.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case SortMode.artistAsc:
        list.sort((a, b) =>
            a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
      case SortMode.recentlyAdded:
        list.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    }
    return list;
  }

  Future<void> init() async {
    await _loadPrefs();
    await scanLibrary();
  }

  // ---- Persistence ---------------------------------------------------

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _favoritePaths
      ..clear()
      ..addAll(prefs.getStringList(_favKey) ?? const []);

    playlists.clear();
    final raw = prefs.getString(_playlistKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List;
        playlists.addAll(
          decoded.map((e) => Playlist.fromJson(e as Map<String, dynamic>)),
        );
      } catch (_) {
        // Ignore malformed saved data rather than crash startup.
      }
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favKey, _favoritePaths.toList());
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _playlistKey,
      jsonEncode(playlists.map((p) => p.toJson()).toList()),
    );
  }

  // ---- Scanning --------------------------------------------------------

  Future<void> scanLibrary() async {
    isScanning = true;
    scanError = null;
    notifyListeners();

    try {
      var granted = await Permission.audio.request();
      if (!granted.isGranted) {
        granted = await Permission.storage.request();
      }
      if (!granted.isGranted) {
        scanError =
            'Storage permission denied. Grant access in system settings, '
            'or use "Add songs" to pick files manually.';
        isScanning = false;
        notifyListeners();
        return;
      }

      final foundPaths = <String>{};
      for (final rootPath in _scanRoots) {
        final root = Directory(rootPath);
        if (!await root.exists()) continue;
        try {
          await for (final entity
              in root.list(recursive: true, followLinks: false)) {
            if (entity is File) {
              final lower = entity.path.toLowerCase();
              if (supportedFileExtensions.any((ext) => lower.endsWith(ext))) {
                foundPaths.add(entity.path);
              }
            }
          }
        } catch (_) {
          // Skip folders we don't have access to rather than fail the scan.
        }
      }

      final songs = <Song>[];
      for (final path in foundPaths) {
        songs.add(await _readSong(path));
      }

      library
        ..clear()
        ..addAll(songs);

      if (library.isEmpty) {
        scanError =
            'No audio files found in Music or Download folders. '
            'Use "Add songs" to pick files manually.';
      }
    } catch (_) {
      scanError =
          'Could not scan device storage. Use "Add songs" to pick files manually.';
    }

    isScanning = false;
    notifyListeners();
  }

  /// Fallback path for files outside the auto-scanned folders (e.g. picked
  /// from another app's storage). Reuses the same tag-reading logic.
  Future<void> addManualPaths(List<String> paths) async {
    for (final path in paths) {
      if (library.any((s) => s.path == path)) continue;
      library.add(await _readSong(path));
    }
    scanError = null;
    notifyListeners();
  }

  Future<Song> _readSong(String path) async {
    final fallback = Song.fromPathFallback(path);
    try {
      final file = File(path);
      final meta = readMetadata(file, getImage: true);
      final stat = await file.stat();

      Uint8List? artwork;
      if (meta.pictures.isNotEmpty) {
        artwork = _extractArtworkBytes(meta.pictures.first);
      }

      final title = (meta.title != null && meta.title!.trim().isNotEmpty)
          ? meta.title!.trim()
          : fallback.title;
      final artist = (meta.artist != null && meta.artist!.trim().isNotEmpty)
          ? meta.artist!.trim()
          : fallback.artist;

      return Song(
        path: path,
        title: title,
        artist: artist,
        album: meta.album?.trim() ?? '',
        duration: meta.duration ?? Duration.zero,
        artwork: artwork,
        dateAdded: stat.modified,
      );
    } catch (_) {
      return fallback;
    }
  }

  /// The exact field the package uses for a picture's raw bytes isn't
  /// documented, so this tries the likely names at runtime (via `dynamic`)
  /// instead of hard-coding one and risking a compile error if it's wrong.
  /// Worst case, artwork silently falls back to the placeholder icon.
  Uint8List? _extractArtworkBytes(dynamic picture) {
    for (final getter in [
      () => picture.bytes,
      () => picture.data,
      () => picture.imageData,
      () => picture.picture,
    ]) {
      try {
        final value = getter();
        if (value is Uint8List) return value;
        if (value is List<int>) return Uint8List.fromList(value);
      } catch (_) {
        // Try the next candidate name.
      }
    }
    return null;
  }

  // ---- Favorites / removal --------------------------------------------

  void toggleFavorite(Song song) {
    if (!_favoritePaths.remove(song.path)) {
      _favoritePaths.add(song.path);
    }
    notifyListeners();
    _saveFavorites();
  }

  Future<void> removeSong(Song song) async {
    library.removeWhere((s) => s.path == song.path);
    _favoritePaths.remove(song.path);
    for (final p in playlists) {
      p.songPaths.remove(song.path);
    }
    notifyListeners();
    await _saveFavorites();
    await _savePlaylists();
  }

  // ---- Search / sort -----------------------------------------------------

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void setSortMode(SortMode mode) {
    sortMode = mode;
    notifyListeners();
  }

  // ---- Playlists ---------------------------------------------------------

  Playlist createPlaylist(String name) {
    final playlist = Playlist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
    );
    playlists.add(playlist);
    notifyListeners();
    _savePlaylists();
    return playlist;
  }

  void deletePlaylist(String id) {
    playlists.removeWhere((p) => p.id == id);
    notifyListeners();
    _savePlaylists();
  }

  void renamePlaylist(String id, String name) {
    final playlist = playlists.firstWhere((p) => p.id == id);
    playlist.name = name;
    notifyListeners();
    _savePlaylists();
  }

  void addToPlaylist(String id, Song song) {
    final playlist = playlists.firstWhere((p) => p.id == id);
    if (!playlist.songPaths.contains(song.path)) {
      playlist.songPaths.add(song.path);
      notifyListeners();
      _savePlaylists();
    }
  }

  void removeFromPlaylist(String id, Song song) {
    final playlist = playlists.firstWhere((p) => p.id == id);
    playlist.songPaths.remove(song.path);
    notifyListeners();
    _savePlaylists();
  }

  List<Song> songsInPlaylist(Playlist playlist) {
    final result = <Song>[];
    for (final path in playlist.songPaths) {
      for (final s in library) {
        if (s.path == path) {
          result.add(s);
          break;
        }
      }
    }
    return result;
  }
}
