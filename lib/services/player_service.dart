import 'dart:async';
import 'package:media_kit/media_kit.dart';
import '../models/playback_history.dart';
import 'database_service.dart';
import 'stream_proxy_server.dart';

class PlayerService {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  PlayerService._internal();

  final Player _player = Player();
  Timer? _progressTimer;

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
      if (history != null) {
        final savedPosition = Duration(milliseconds: history.positionInMs);
        if (savedPosition > Duration.zero) {
          await _player.seek(savedPosition);
        }
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
    // 简化版本，暂不保存进度
  }

  Future<void> savePlaybackHistory(
    String path,
    String fileName,
    int serverId,
  ) async {
    final proxyUrl = StreamProxyServer().getSmbProxyUrl(path);
    final position = _player.state.position;

    final existingHistory = await DatabaseService.getPlaybackHistory(proxyUrl);
    
    if (existingHistory != null) {
      existingHistory.positionInMs = position.inMilliseconds;
      await DatabaseService.savePlaybackHistory(existingHistory);
    } else {
      final newHistory = PlaybackHistory()
        ..fileUrl = proxyUrl
        ..positionInMs = position.inMilliseconds;
      await DatabaseService.savePlaybackHistory(newHistory);
    }
  }

  Future<void> dispose() async {
    _progressTimer?.cancel();
    await _player.dispose();
    await StreamProxyServer().stop();
  }
}
