import 'package:media_kit/media_kit.dart';

class PlayerService {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  PlayerService._internal();

  final Player _player = Player();
  final List<String> _subtitleExtensions = ['.srt', '.ass', '.ssa'];

  Player get player => _player;

  Future<void> initialize() async {
    MediaKit.ensureInitialized();
  }

  Future<void> play(String url) async {
    await _player.open(Media(url));
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

  Future<void> setPlaybackRate(double rate) async {
    await _player.setRate(rate);
  }

  Stream<Duration> get positionStream => _player.stream.position;
  Stream<Duration> get durationStream => _player.stream.duration;
  Stream<bool> get playingStream => _player.stream.playing;
  Stream<double> get volumeStream => _player.stream.volume;

  Duration get position => _player.state.position;
  Duration get duration => _player.state.duration;
  bool get isPlaying => _player.state.playing;
  double get volume => _player.state.volume;

  List<String> findSubtitles(String videoPath) {
    final subtitles = <String>[];
    final basePath = videoPath.substring(0, videoPath.lastIndexOf('.'));
    for (final ext in _subtitleExtensions) {
      subtitles.add('$basePath$ext');
    }
    return subtitles;
  }

  void dispose() {
    _player.dispose();
  }
}
