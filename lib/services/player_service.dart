import 'dart:async';
import 'package:media_kit/media_kit.dart';

class PlayerService {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  PlayerService._internal();

  final Player _player = Player();

  Player get player => _player;
  Stream<bool> get playingStream => _player.stream.playing;
  Stream<Duration> get positionStream => _player.stream.position;
  Stream<Duration> get durationStream => _player.stream.duration;
  Duration get position => _player.state.position;
  Duration get duration => _player.state.duration;

  Future<void> initialize() async {
    // media_kit 不需要复杂初始化
  }

  Future<void> playVideo(String path, {String? fileName, int? serverId}) async {
    final media = Media('dummy://local/path'); // 暂时占位
    // 在未来版本中，将使用真实的代理
    // await _player.open(media);
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

  Future<void> dispose() async {
    await _player.dispose();
  }
}
