import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/library_service.dart';
import '../services/player_service.dart';
import '../widgets/seek_ring.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final library = context.watch<LibraryService>();
    final song = player.current;
    final scheme = Theme.of(context).colorScheme;

    if (song == null) {
      return Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('Nothing playing')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now playing'),
        actions: [
          IconButton(
            icon: Icon(
                library.isFavorite(song) ? Icons.favorite : Icons.favorite_border),
            color: library.isFavorite(song) ? Colors.redAccent : null,
            onPressed: () => library.toggleFavorite(song),
          ),
          PopupMenuButton<Duration?>(
            icon: Icon(
                player.sleepEndsAt == null ? Icons.bedtime_outlined : Icons.bedtime),
            tooltip: 'Sleep timer',
            onSelected: player.setSleepTimer,
            itemBuilder: (_) => const [
              PopupMenuItem(value: Duration(minutes: 15), child: Text('15 minutes')),
              PopupMenuItem(value: Duration(minutes: 30), child: Text('30 minutes')),
              PopupMenuItem(value: Duration(minutes: 60), child: Text('60 minutes')),
              PopupMenuItem(value: null, child: Text('Off')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: song.artwork != null
                      ? Image.memory(song.artwork!, fit: BoxFit.cover)
                      : Container(
                          color: scheme.primaryContainer,
                          child: Icon(Icons.music_note,
                              size: 96, color: scheme.onPrimaryContainer),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Text(song.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(song.artist, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 24),

              StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (_, snap) {
                  final pos = snap.data ?? Duration.zero;
                  final dur = player.duration ?? Duration.zero;
                  final progress = dur.inMilliseconds == 0
                      ? 0.0
                      : pos.inMilliseconds / dur.inMilliseconds;
                  final maxMs =
                      dur.inMilliseconds <= 0 ? 1.0 : dur.inMilliseconds.toDouble();
                  return Column(
                    children: [
                      SeekRing(
                        progress: progress,
                        size: 200,
                        child: IconButton.filled(
                          iconSize: 40,
                          padding: const EdgeInsets.all(18),
                          icon: Icon(player.isPlaying ? Icons.pause : Icons.play_arrow),
                          onPressed: player.togglePlay,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Slider(
                        value: pos.inMilliseconds.toDouble().clamp(0.0, maxMs),
                        max: maxMs,
                        onChanged: (v) => player.seek(Duration(milliseconds: v.round())),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [Text(_fmt(pos)), Text(_fmt(dur))],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shuffle),
                    color: player.shuffle ? scheme.primary : null,
                    onPressed: player.toggleShuffle,
                  ),
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.skip_previous),
                    onPressed: player.previous,
                  ),
                  IconButton(
                    icon: const Icon(Icons.replay_10),
                    onPressed: () => player.seekRelative(const Duration(seconds: -10)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10),
                    onPressed: () => player.seekRelative(const Duration(seconds: 10)),
                  ),
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.skip_next),
                    onPressed: player.next,
                  ),
                  IconButton(
                    icon: Icon(player.repeat == PlayerRepeat.one
                        ? Icons.repeat_one
                        : Icons.repeat),
                    color: player.repeat == PlayerRepeat.off ? null : scheme.primary,
                    onPressed: player.cycleRepeat,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(player.volume == 0 ? Icons.volume_off : Icons.volume_up),
                  Expanded(
                      child: Slider(value: player.volume, onChanged: player.setVolume)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Speed '),
                  PopupMenuButton<double>(
                    tooltip: 'Playback speed',
                    onSelected: player.setSpeed,
                    child: Chip(label: Text('${player.speed}x')),
                    itemBuilder: (_) => [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                        .map((s) => PopupMenuItem(value: s, child: Text('${s}x')))
                        .toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
