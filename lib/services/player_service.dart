import 'dart:async';
import 'package:media_kit/media_kit.dart';

class PlayerService {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  PlayerService._internal();

  Player? _player;
  final List<String> _subtitleExtensions = ['.srt', '.ass', '.ssa', '.smi'];
  final StreamController<void> _playerStateController =
      StreamController.broadcast();

  bool get isInitialized => _player != null;
  Stream<void> get playerStateStream => _playerStateController.stream;
  Player? get player => _player;

  Duration get position => _player?.state.position ?? Duration.zero;
  Duration get duration => _player?.state.duration ?? Duration.zero;
  bool get isPlaying => _player?.state.playing ?? false;
  double get volume => _player?.state.volume ?? 1.0;
  double get rate => _player?.state.rate ?? 1.0;

  Stream<Duration> get positionStream =>
      _player?.stream.position ?? const Stream.empty();
  Stream<Duration> get durationStream =>
      _player?.stream.duration ?? const Stream.empty();
  Stream<bool> get playingStream =>
      _player?.stream.playing ?? const Stream.empty();
  Stream<double> get volumeStream =>
      _player?.stream.volume ?? const Stream.empty();

  Future<void> initialize() async {
    if (_player != null) return;

    try {
      MediaKit.ensureInitialized();
      _player = Player(
        configuration: const PlayerConfiguration(
          title: 'Media Manager',
          libass: true,
        ),
      );
      _playerStateController.add(null);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> open(String url) async {
    if (_player == null) {
      await initialize();
    }

    try {
      await _player!.open(Media(url), play: false);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> play() async {
    if (_player == null) return;
    try {
      await _player!.play();
    } catch (e) {}
  }

  Future<void> pause() async {
    if (_player == null) return;
    try {
      await _player!.pause();
    } catch (e) {}
  }

  Future<void> playOrPause() async {
    if (_player == null) return;
    try {
      if (_player!.state.playing) {
        await _player!.pause();
      } else {
        await _player!.play();
      }
    } catch (e) {}
  }

  Future<void> stop() async {
    if (_player == null) return;
    try {
      await _player!.stop();
    } catch (e) {}
  }

  Future<void> seek(Duration position) async {
    if (_player == null) return;
    try {
      await _player!.seek(position);
    } catch (e) {}
  }

  Future<void> seekRelative(Duration delta) async {
    if (_player == null) return;
    try {
      final newPosition = _player!.state.position + delta;
      final clampedPosition = Duration(
        microseconds: newPosition.inMicroseconds.clamp(
          0,
          _player!.state.duration.inMicroseconds,
        ),
      );
      await _player!.seek(clampedPosition);
    } catch (e) {}
  }

  Future<void> setVolume(double volume) async {
    if (_player == null) return;
    try {
      final clampedVolume = volume.clamp(0.0, 100.0);
      await _player!.setVolume(clampedVolume);
    } catch (e) {}
  }

  Future<void> setRate(double rate) async {
    if (_player == null) return;
    try {
      final clampedRate = rate.clamp(0.25, 4.0);
      await _player!.setRate(clampedRate);
    } catch (e) {}
  }

  List<String> findSubtitles(String videoPath) {
    final subtitles = <String>[];
    final basePath = videoPath.substring(0, videoPath.lastIndexOf('.'));

    for (final ext in _subtitleExtensions) {
      subtitles.add('$basePath$ext');
    }

    return subtitles;
  }

  Future<void> dispose() async {
    if (_player == null) return;

    try {
      await _player!.dispose();
      _player = null;
      await _playerStateController.close();
    } catch (e) {}
  }
}
