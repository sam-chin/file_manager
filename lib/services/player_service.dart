import 'dart:async';
import 'package:media_kit/media_kit.dart';
import 'database_service.dart';
import 'stream_proxy_server.dart';

class PlayerService {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  PlayerService._internal();

  final Player _player = Player();
  Timer? _progressTimer;
  Duration _lastSavedPosition = Duration.zero;

  Player get player => _player;
  Stream<bool> get playingStream => _player.stream.playing;
  Stream<Duration> get positionStream => _player.stream.position;
  Stream<Duration> get durationStream => _player.stream.duration;
  Duration get position => _player.state.position;
  Duration get duration => _player.state.duration;

  Future<void> initialize() async {
    await StreamProxyServer().start();
    _setupProgressTracking();
  }

  void _setupProgressTracking() {
    _player.stream.playing.listen((playing) {
      if (playing) {
        _progressTimer?.cancel();
        _progressTimer = Timer.periodic(const Duration(seconds: 5), (_) {
          _saveProgress();
        });
      } else {
        _progressTimer?.cancel();
        _saveProgress();
      }
    });
  }

  Future<void> playVideo(String path, {String? fileName, int? serverId}) async {
    final proxyUrl = StreamProxyServer().getSmbProxyUrl(path);
    final media = Media(proxyUrl);
    
    await _player.open(media);
    
    if (fileName != null && serverId != null) {
      final history = await DatabaseService.getPlaybackHistory(proxyUrl);
      if (history != null && history.position > Duration.zero) {
        await _player.seek(history.position);
      }
    }
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  Future<void> setRate(double rate) async {
    await _player.setRate(rate);
  }

  Future<void> _saveProgress() async {
    final currentPosition = _player.state.position;
    final currentDuration = _player.state.duration;
    
    if (currentPosition != _lastSavedPosition && currentDuration > Duration.zero) {
      _lastSavedPosition = currentPosition;
    }
  }

  Future<void> savePlaybackHistory(
    String path,
    String fileName,
    int serverId,
  ) async {
    final proxyUrl = StreamProxyServer().getSmbProxyUrl(path);
    final position = _player.state.position;
    final duration = _player.state.duration;

    final existingHistory = await DatabaseService.getPlaybackHistory(proxyUrl);
    
    if (existingHistory != null) {
      existingHistory.position = position;
      existingHistory.duration = duration;
      existingHistory.lastPlayed = DateTime.now();
      existingHistory.playCount++;
      await DatabaseService.savePlaybackHistory(existingHistory);
    } else {
      final newHistory = PlaybackHistory()
        ..fileUrl = proxyUrl
        ..fileName = fileName
        ..serverId = serverId
        ..position = position
        ..duration = duration
        ..lastPlayed = DateTime.now()
        ..playCount = 1;
      await DatabaseService.savePlaybackHistory(newHistory);
    }
  }

  Future<void> dispose() async {
    _progressTimer?.cancel();
    await _player.dispose();
    await StreamProxyServer().stop();
  }
}
