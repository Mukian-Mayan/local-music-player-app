import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/playlist.dart';
import '../services/library_service.dart';
import '../widgets/glass_scaffold.dart';
import '../widgets/song_detail_sheet.dart';
import '../widgets/song_tile.dart';

/// Shows the songs inside one playlist. Songs are looked up from the live
/// library each time, so removing a song elsewhere removes it here too.
class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key, required this.playlist});
  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryService>();
    final songs = library.songsInPlaylist(playlist);

    return GlassScaffold(
      appBar: AppBar(title: Text(playlist.name)),
      body: SafeArea(
        child: songs.isEmpty
            ? const Center(child: Text('No songs in this playlist yet.'))
            : ListView.builder(
                itemCount: songs.length,
                itemBuilder: (_, i) => SongTile(
                  song: songs[i],
                  queue: songs,
                  index: i,
                  onMore: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => SongDetailSheet(song: songs[i]),
                  ),
                ),
              ),
      ),
    );
  }
}
