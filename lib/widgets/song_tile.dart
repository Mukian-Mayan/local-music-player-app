import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../services/library_service.dart';
import '../services/player_service.dart';

/// One row in a song list: artwork, title/artist, duration, favorite
/// toggle and a "more" button that opens the details sheet. Swipe to
/// remove from the library entirely.
class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    required this.queue,
    required this.index,
    required this.onMore,
  });

  final Song song;
  final List<Song> queue;
  final int index;
  final VoidCallback onMore;

  String _fmtDuration(Duration d) {
    if (d == Duration.zero) return '';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryService>();
    final player = context.watch<PlayerService>();
    final isCurrent = player.current == song;
    final scheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(song.path),
      direction: DismissDirection.endToStart,
      background: Container(
        color: scheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      onDismissed: (_) => library.removeSong(song),
      child: ListTile(
        onTap: () => player.playQueue(queue, index),
        onLongPress: onMore,
        leading: _Artwork(song: song, isCurrent: isCurrent),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isCurrent ? scheme.primary : null,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle:
            Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (song.duration != Duration.zero)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(_fmtDuration(song.duration),
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            IconButton(
              icon: Icon(
                library.isFavorite(song)
                    ? Icons.favorite
                    : Icons.favorite_border,
                size: 20,
              ),
              color: library.isFavorite(song) ? Colors.redAccent : null,
              onPressed: () => library.toggleFavorite(song),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: onMore,
            ),
          ],
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.song, required this.isCurrent});
  final Song song;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 46,
        height: 46,
        child: song.artwork != null
            ? Image.memory(song.artwork!, fit: BoxFit.cover)
            : Container(
                color: scheme.primaryContainer,
                child: Icon(
                  isCurrent ? Icons.equalizer : Icons.music_note,
                  color: scheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
      ),
    );
  }
}
