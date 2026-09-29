import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../screens/playlist_screen.dart';
import '../services/library_service.dart';
import '../services/settings_service.dart';
import '../widgets/create_playlist_sheet.dart';
import '../widgets/mini_player.dart';
import '../widgets/song_detail_sheet.dart';
import '../widgets/song_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _pickFiles(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );
    if (result == null || !context.mounted) return;
    final paths = result.files.map((f) => f.path).whereType<String>().toList();
    await context.read<LibraryService>().addManualPaths(paths);
  }

  void _openSongDetails(Song song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SongDetailSheet(song: song),
    );
  }

  void _createPlaylist() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const CreatePlaylistSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryService>();
    final settings = context.watch<SettingsService>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Your music'),
          actions: [
            PopupMenuButton<SortMode>(
              tooltip: 'Sort',
              icon: const Icon(Icons.sort),
              onSelected: library.setSortMode,
              itemBuilder: (_) => const [
                PopupMenuItem(value: SortMode.titleAsc, child: Text('By title')),
                PopupMenuItem(value: SortMode.artistAsc, child: Text('By artist')),
                PopupMenuItem(
                    value: SortMode.recentlyAdded, child: Text('Recently added')),
              ],
            ),
            IconButton(
              tooltip: 'Toggle theme',
              icon: Icon(settings.themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined),
              onPressed: settings.toggle,
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'scan') context.read<LibraryService>().scanLibrary();
                if (value == 'add') _pickFiles(context);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'scan', child: Text('Rescan device')),
                PopupMenuItem(value: 'add', child: Text('Add songs manually')),
              ],
            ),
          ],
          bottom: const TabBar(tabs: [
            Tab(text: 'Library'),
            Tab(text: 'Playlists'),
            Tab(text: 'Favorites'),
          ]),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _createPlaylist,
          tooltip: 'New playlist',
          child: const Icon(Icons.playlist_add),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SearchBar(
                hintText: 'Search songs, artists, albums',
                leading: const Icon(Icons.search),
                trailing: library.isScanning
                    ? [
                        const Padding(
                          padding: EdgeInsets.all(10),
                          child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      ]
                    : null,
                onChanged: library.setSearchQuery,
              ),
            ),
            if (library.scanError != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  library.scanError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: TabBarView(children: [
                _LibraryTab(onSongTap: _openSongDetails),
                const _PlaylistsTab(),
                _FavoritesTab(onSongTap: _openSongDetails),
              ]),
            ),
            const MiniPlayer(),
          ],
        ),
      ),
    );
  }
}

class _LibraryTab extends StatelessWidget {
  const _LibraryTab({required this.onSongTap});
  final void Function(Song) onSongTap;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryService>();
    final songs = library.visibleLibrary;

    if (library.isScanning && songs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (songs.isEmpty) {
      return const _EmptyState(
        icon: Icons.library_music_outlined,
        text: 'No songs found yet.\nPull down to rescan, or add songs manually.',
      );
    }

    return RefreshIndicator(
      onRefresh: library.scanLibrary,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: songs.length,
        itemBuilder: (_, i) {
          final song = songs[i];
          return SongTile(
            song: song,
            queue: songs,
            index: i,
            onMore: () => onSongTap(song),
          );
        },
      ),
    );
  }
}

class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab({required this.onSongTap});
  final void Function(Song) onSongTap;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryService>();
    final songs = library.favorites;
    if (songs.isEmpty) {
      return const _EmptyState(
        icon: Icons.favorite_border,
        text: 'No favorites yet.\nTap the heart on a song to save it here.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: songs.length,
      itemBuilder: (_, i) {
        final song = songs[i];
        return SongTile(
          song: song,
          queue: songs,
          index: i,
          onMore: () => onSongTap(song),
        );
      },
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryService>();
    if (library.playlists.isEmpty) {
      return const _EmptyState(
        icon: Icons.queue_music_outlined,
        text: 'No playlists yet.\nTap + to create one.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: library.playlists.length,
      itemBuilder: (_, i) {
        final playlist = library.playlists[i];
        final count = playlist.songPaths.length;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: const Icon(Icons.queue_music),
          ),
          title: Text(playlist.name),
          subtitle: Text('$count song${count == 1 ? '' : 's'}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => library.deletePlaylist(playlist.id),
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PlaylistScreen(playlist: playlist)),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
