import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/library_service.dart';
import 'services/player_service.dart';
import 'services/settings_service.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppRoot());
}

/// Creates the long-lived services once and hands them down via Provider.
/// SettingsService.load() and LibraryService.init() kick off async work
/// (reading prefs, scanning the device) without blocking first paint --
/// screens watch isScanning/scanError to show their own loading states.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late final SettingsService _settings;
  late final LibraryService _library;
  late final PlayerService _player;

  @override
  void initState() {
    super.initState();
    _settings = SettingsService();
    _library = LibraryService();
    _player = PlayerService();
    _settings.load();
    _library.init();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _settings),
        ChangeNotifierProvider.value(value: _library),
        ChangeNotifierProvider.value(value: _player),
      ],
      child: const MusicPlayerApp(),
    );
  }
}

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    return MaterialApp(
      title: 'Music Player',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: const HomeScreen(),
    );
  }
}
