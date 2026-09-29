import 'dart:typed_data';

/// A single audio track, either read from file tags or guessed from its
/// filename when tags are missing or unreadable.
class Song {
  final String path;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final Uint8List? artwork;
  final DateTime dateAdded;

  const Song({
    required this.path,
    required this.title,
    required this.artist,
    this.album = '',
    this.duration = Duration.zero,
    this.artwork,
    required this.dateAdded,
  });

  /// Builds a song purely from its filename, used when tag reading fails
  /// or a file has no tags at all. Filenames like "Artist - Title.mp3" are
  /// split into artist and title. Underscores/dashes become spaces and a
  /// trailing numeric id some downloaders append (e.g. "..._mp3_25895")
  /// is stripped, so "ayra_starr_wizkid_gimme_dat_mp3_25895" reads as
  /// "Ayra Starr Wizkid Gimme Dat" instead of the raw filename.
  factory Song.fromPathFallback(String path) {
    final file = path.split(RegExp(r'[\\/]')).last;
    final dot = file.lastIndexOf('.');
    final rawName = dot > 0 ? file.substring(0, dot) : file;

    var cleaned = rawName.replaceAll(RegExp(r'[_]+'), ' ').trim();
    cleaned = cleaned.replaceAll(
        RegExp(r'\s+(mp3|m4a|wav|flac)\s*\d*$', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+\d{3,}$'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    if (cleaned.isEmpty) cleaned = rawName;

    final parts = cleaned.split(' - ');
    if (parts.length >= 2) {
      return Song(
        path: path,
        artist: _titleCase(parts.first.trim()),
        title: _titleCase(parts.sublist(1).join(' - ').trim()),
        dateAdded: DateTime.now(),
      );
    }
    return Song(
      path: path,
      title: _titleCase(cleaned),
      artist: 'Unknown artist',
      dateAdded: DateTime.now(),
    );
  }

  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }

  @override
  bool operator ==(Object other) => other is Song && other.path == path;

  @override
  int get hashCode => path.hashCode;
}
