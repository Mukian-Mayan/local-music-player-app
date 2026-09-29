import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/now_playing_screen.dart';
import '../services/player_service.dart';
import '../theme.dart';
import 'glass_panel.dart';

/// Floating glass bar shown above the bottom nav whenever a song is
/// loaded. Tapping it opens the full Now Playing screen.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final song = player.current;
    if (song == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GlassPanel(
        borderRadius: BorderRadius.circular(18),
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => const NowPlayingScreen(),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<Duration>(
                  stream: player.positionStream,
                  builder: (_, snap) {
                    final pos = snap.data?.inMilliseconds ?? 0;
                    final dur = player.duration?.inMilliseconds ?? 0;
                    return ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(18)),
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        value: dur == 0 ? 0 : (pos / dur).clamp(0.0, 1.0),
                        backgroundColor: Colors.transparent,
                        color: AppColors.accent,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: song.artwork != null
                          ? Image.memory(song.artwork!, fit: BoxFit.cover)
                          : Container(
                              color: AppColors.accent.withValues(alpha: 0.16),
                              child: const Icon(Icons.music_note,
                                  color: AppColors.accent, size: 20),
                            ),
                    ),
                  ),
                  title: Text(song.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(song.artist,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                            player.isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: player.togglePlay,
                      ),
                      IconButton(
                          icon: const Icon(Icons.skip_next),
                          onPressed: player.next),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
