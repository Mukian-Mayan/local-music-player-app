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

  /// Builds a song purely from its filename, used when tag reading fails.
  /// Filenames like "Artist - Title.mp3" are split into artist and title.
  factory Song.fromPathFallback(String path) {
    final file = path.split(RegExp(r'[\\/]')).last;
    final dot = file.lastIndexOf('.');
    final name = dot > 0 ? file.substring(0, dot) : file;
    final parts = name.split(' - ');
    if (parts.length >= 2) {
      return Song(
        path: path,
        artist: parts.first.trim(),
        title: parts.sublist(1).join(' - ').trim(),
        dateAdded: DateTime.now(),
      );
    }
    return Song(
      path: path,
      title: name,
      artist: 'Unknown artist',
      dateAdded: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) => other is Song && other.path == path;

  @override
  int get hashCode => path.hashCode;
}
