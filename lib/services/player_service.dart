import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';

/// Named PlayerRepeat (not RepeatMode) because Flutter's Material library
/// already defines a RepeatMode, which caused an ambiguous-import error.
enum PlayerRepeat { off, all, one }

/// Owns the audio engine and the current play queue. The queue is handed
/// in by whichever screen started playback (library, favorites or a
/// playlist), so next/previous/shuffle/repeat all operate over that list.
class PlayerService extends ChangeNotifier {
  PlayerService() {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onCompleted();
      }
      notifyListeners();
    });
  }

  final AudioPlayer _player = AudioPlayer();

  List<Song> _queue = [];
  List<int> _order = []; // play order as indexes into _queue
  int _pos = -1; // position inside _order

  bool shuffle = false;
  PlayerRepeat repeat = PlayerRepeat.off;
  double speed = 1.0;
  double volume = 1.0;
  String? error;

  Timer? _sleepTimer;
  DateTime? sleepEndsAt;

  Song? get current =>
      (_pos >= 0 && _pos < _order.length) ? _queue[_order[_pos]] : null;
  bool get isPlaying => _player.playing;
  bool get hasSong => current != null;
  List<Song> get queue => _queue;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Duration? get duration => _player.duration;

  /// Starts playing [songs] at [startIndex]. Called from the library,
  /// favorites or a playlist screen with whatever list the user tapped in.
  Future<void> playQueue(List<Song> songs, int startIndex) async {
    if (songs.isEmpty) return;
    _queue = songs;
    _order = List.generate(_queue.length, (i) => i);
    var pos = startIndex.clamp(0, _queue.length - 1);
    if (shuffle) {
      _order.shuffle();
      _order.remove(pos);
      _order.insert(0, pos);
      pos = 0;
    }
    await _load(pos);
  }

  Future<void> togglePlay() async {
    if (!hasSong) return;
    if (_player.playing) {
      await _player.pause();
    } else {
      _player.play();
    }
    notifyListeners();
  }

  Future<void> next() async {
    if (_order.isEmpty) return;
    await _load(_pos < _order.length - 1 ? _pos + 1 : 0);
  }

  Future<void> previous() async {
    if (_order.isEmpty) return;
    if (_player.position > const Duration(seconds: 3) || _pos <= 0) {
      await _player.seek(Duration.zero);
    } else {
      await _load(_pos - 1);
    }
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> seekRelative(Duration delta) async {
    final d = _player.duration ?? Duration.zero;
    var target = _player.position + delta;
    if (target < Duration.zero) target = Duration.zero;
    if (target > d) target = d;
    await _player.seek(target);
  }

  void toggleShuffle() {
    shuffle = !shuffle;
    final currentSong = current;
    _order = List.generate(_queue.length, (i) => i);
    if (shuffle) {
      _order.shuffle();
      if (currentSong != null) {
        final idx = _queue.indexOf(currentSong);
        _order.remove(idx);
        _order.insert(0, idx);
        _pos = 0;
      }
    } else if (currentSong != null) {
      _pos = _queue.indexOf(currentSong);
    }
    notifyListeners();
  }

  void cycleRepeat() {
    repeat = PlayerRepeat.values[(repeat.index + 1) % PlayerRepeat.values.length];
    notifyListeners();
  }

  Future<void> setSpeed(double value) async {
    speed = value;
    await _player.setSpeed(value);
    notifyListeners();
  }

  Future<void> setVolume(double value) async {
    volume = value;
    await _player.setVolume(value);
    notifyListeners();
  }

  void setSleepTimer(Duration? after) {
    _sleepTimer?.cancel();
    if (after == null) {
      sleepEndsAt = null;
    } else {
      sleepEndsAt = DateTime.now().add(after);
      _sleepTimer = Timer(after, () async {
        await _player.pause();
        sleepEndsAt = null;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  Future<void> _load(int pos) async {
    _pos = pos;
    error = null;
    final song = current;
    if (song == null) return;
    notifyListeners();
    try {
      await _player.setFilePath(song.path);
      await _player.setSpeed(speed);
      await _player.setVolume(volume);
      _player.play();
    } catch (e) {
      error = 'Could not play "${song.title}"';
    }
    notifyListeners();
  }

  Future<void> _onCompleted() async {
    if (repeat == PlayerRepeat.one) {
      await _player.seek(Duration.zero);
      _player.play();
    } else if (_pos < _order.length - 1) {
      await _load(_pos + 1);
    } else if (repeat == PlayerRepeat.all) {
      await _load(0);
    } else {
      await _player.pause();
      await _player.seek(Duration.zero);
    }
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}
