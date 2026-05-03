import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../models/file_item.dart';

enum MediaCategory { audio, video, image, none }

class MediaService extends ChangeNotifier {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  final Player _audioPlayer = Player();
  
  FileItem? currentFile;
  MediaCategory currentCategory = MediaCategory.none;
  bool isPlaying = false;
  Uint8List? cachedBytes;

  final Set<String> _imgExts = {'.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'};
  final Set<String> _audExts = {'.mp3', '.wav', '.m4a', '.flac', '.ogg', '.aac'};
  final Set<String> _vidExts = {'.mp4', '.mkv', '.mov', '.avi', '.flv', '.wmv', '.webm'};

  String? get currentPath => currentFile?.path;
  String get currentName => currentFile?.name ?? '';

  MediaCategory detectCategory(String path) {
    final lower = path.toLowerCase();
    if (_imgExts.any((ext) => lower.endsWith(ext))) return MediaCategory.image;
    if (_audExts.any((ext) => lower.endsWith(ext))) return MediaCategory.audio;
    if (_vidExts.any((ext) => lower.endsWith(ext))) return MediaCategory.video;
    return MediaCategory.none;
  }

  void openFile(FileItem file) {
    currentFile = file;
    currentCategory = detectCategory(file.path);
    isPlaying = false;
    cachedBytes = null;
    notifyListeners();

    if (currentCategory == MediaCategory.audio) {
      _playAudio(file.path);
    }
  }

  Future<void> _playAudio(String path) async {
    await _audioPlayer.open(Media(path));
    await _audioPlayer.play();
    isPlaying = true;
    notifyListeners();
  }

  Future<void> play() async {
    if (currentFile == null) return;
    if (currentCategory == MediaCategory.audio) {
      await _audioPlayer.play();
      isPlaying = true;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    if (currentCategory == MediaCategory.audio) {
      await _audioPlayer.pause();
      isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    if (currentCategory == MediaCategory.audio) {
      await _audioPlayer.stop();
    }
    currentFile = null;
    currentCategory = MediaCategory.none;
    isPlaying = false;
    cachedBytes = null;
    notifyListeners();
  }

  void close() {
    stop();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
