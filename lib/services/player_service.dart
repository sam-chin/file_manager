import 'package:media_kit/media_kit.dart';
import '../models/file_item.dart';

class PlayerService {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  PlayerService._internal();

  final Player _player = Player();
  
  FileItem? currentFile;
  bool isPlaying = false;
  bool isVideo = false;

  Player get player => _player;

  Stream<Duration> get onPositionChanged => _player.stream.position;
  Stream<Duration> get onDurationChanged => _player.stream.duration;
  Stream<bool> get onPlayingChanged => _player.stream.playing;

  Future<void> play(FileItem file, {bool isVideo = false}) async {
    currentFile = file;
    this.isVideo = isVideo;
    await _player.open(Media(file.path));
    await _player.play();
    isPlaying = true;
  }

  Future<void> playUrl(String url, {bool isVideo = false, String? title}) async {
    currentFile = title != null 
        ? FileItem(name: title, path: url, size: 0, isDirectory: false, type: FileItemType.video)
        : null;
    this.isVideo = isVideo;
    await _player.open(Media(url));
    await _player.play();
    isPlaying = true;
  }

  Future<void> pause() async {
    await _player.pause();
    isPlaying = false;
  }

  Future<void> resume() async {
    await _player.play();
    isPlaying = true;
  }

  Future<void> stop() async {
    await _player.stop();
    isPlaying = false;
    currentFile = null;
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void dispose() {
    _player.dispose();
  }
}
