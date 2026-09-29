import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../services/library_service.dart';
import '../services/player_service.dart';
import '../theme.dart';
import 'glass_panel.dart';

/// Bottom sheet showing a song's full details (album, duration, file name)
/// plus actions: play, favorite, add to playlist, remove.
class SongDetailSheet extends StatelessWidget {
  const SongDetailSheet({super.key, required this.song});
  final Song song;

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryService>();
    final player = context.read<PlayerService>();
    final scheme = Theme.of(context).colorScheme;

    return GlassPanel(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      blurSigma: 24,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: song.artwork != null
                          ? Image.memory(song.artwork!, fit: BoxFit.cover)
                          : Container(
                              color: AppColors.accent.withValues(alpha: 0.16),
                              child: const Icon(Icons.music_note,
                                  color: AppColors.accent),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(song.title,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        Text(song.artist,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DetailRow(
                  label: 'Album', value: song.album.isEmpty ? '—' : song.album),
              _DetailRow(
                  label: 'Duration',
                  value: song.duration == Duration.zero
                      ? '—'
                      : _fmtDuration(song.duration)),
              _DetailRow(
                  label: 'File',
                  value: song.path.split(RegExp(r'[\\/]')).last),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black),
                    onPressed: () {
                      player.playQueue([song], 0);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => library.toggleFavorite(song),
                    icon: Icon(library.isFavorite(song)
                        ? Icons.favorite
                        : Icons.favorite_border),
                    label:
                        Text(library.isFavorite(song) ? 'Favorited' : 'Favorite'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showAddToPlaylist(context, song),
                    icon: const Icon(Icons.playlist_add),
                    label: const Text('Add to playlist'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      library.removeSong(song);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddToPlaylist(BuildContext context, Song song) {
    final library = context.read<LibraryService>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => GlassPanel(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        blurSigma: 24,
        child: SafeArea(
          top: false,
          child: library.playlists.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child:
                      Text('No playlists yet. Create one from the Playlists tab.'),
                )
              : ListView(
                  shrinkWrap: true,
                  children: library.playlists
                      .map((p) => ListTile(
                            leading: const Icon(Icons.queue_music,
                                color: AppColors.accent),
                            title: Text(p.name),
                            onTap: () {
                              library.addToPlaylist(p.id, song);
                              Navigator.pop(context);
                            },
                          ))
                      .toList(),
                ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 90,
              child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(
              child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
