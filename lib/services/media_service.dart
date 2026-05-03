import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../models/file_item.dart';

enum MediaCategory { audio, video, image, none }

class MediaService extends ChangeNotifier {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  final Player _player = Player();
  
  Player get player => _player;
  
  List<FileItem> playlist = [];
  int currentIndex = 0;
  MediaCategory category = MediaCategory.none;
  bool isPlaying = false;
  double progress = 0.0;

  FileItem? get currentFile {
    if (playlist.isEmpty || currentIndex >= playlist.length) return null;
    return playlist[currentIndex];
  }

  String get currentName => currentFile?.name ?? '';
  bool get hasNext => currentIndex < playlist.length - 1;
  bool get hasPrevious => currentIndex > 0;

  Duration get playerDuration => _player.state.duration;
  Duration get playerPosition {
    final duration = _player.state.duration.inMilliseconds;
    return Duration(milliseconds: (duration * progress).toInt());
  }

  // 更新：接收当前文件和整个目录的文件列表
  void open(FileItem file, List<FileItem> allFiles) {
    // 过滤出支持的媒体格式
    playlist = allFiles.where((f) => _isMedia(f.path)).toList();
    currentIndex = playlist.indexWhere((f) => f.path == file.path);
    if (currentIndex < 0) {
      playlist = [file];
      currentIndex = 0;
    }
    
    _updateCategory();
    _startPlaying();
    _setupListeners();
    notifyListeners();
  }

  void _updateCategory() {
    if (currentFile == null) {
      category = MediaCategory.none;
      return;
    }
    String path = currentFile!.path.toLowerCase();
    if (path.endsWith('.mp4') || path.endsWith('.mkv') || path.endsWith('.mov') || 
        path.endsWith('.avi') || path.endsWith('.flv') || path.endsWith('.wmv')) {
      category = MediaCategory.video;
    } else if (path.endsWith('.mp3') || path.endsWith('.flac') || path.endsWith('.wav') || 
               path.endsWith('.m4a') || path.endsWith('.aac')) {
      category = MediaCategory.audio;
    } else if (path.endsWith('.jpg') || path.endsWith('.png') || path.endsWith('.gif') || 
               path.endsWith('.webp') || path.endsWith('.bmp')) {
      category = MediaCategory.image;
    } else {
      category = MediaCategory.none;
    }
  }

  void _startPlaying() {
    if (currentFile == null) return;
    if (category == MediaCategory.audio || category == MediaCategory.video) {
      _player.open(Media(currentFile!.path));
      _player.play();
      isPlaying = true;
    } else {
      isPlaying = false;
    }
  }

  bool _isMedia(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.mp4') || p.endsWith('.mkv') || p.endsWith('.mov') || 
           p.endsWith('.avi') || p.endsWith('.flv') || p.endsWith('.wmv') ||
           p.endsWith('.mp3') || p.endsWith('.flac') || p.endsWith('.wav') || 
           p.endsWith('.m4a') || p.endsWith('.aac') ||
           p.endsWith('.jpg') || p.endsWith('.png') || p.endsWith('.gif') || 
           p.endsWith('.webp') || p.endsWith('.bmp');
  }

  void _setupListeners() {
    _player.stream.playing.listen((playing) {
      isPlaying = playing;
      notifyListeners();
    });
    _player.stream.position.listen((position) {
      final duration = _player.state.duration.inMilliseconds;
      if (duration > 0) {
        progress = position.inMilliseconds / duration;
      }
      notifyListeners();
    });
  }

  void next() {
    if (hasNext) {
      currentIndex++;
      _updateCategory();
      _startPlaying();
      notifyListeners();
    }
  }

  void previous() {
    if (hasPrevious) {
      currentIndex--;
      _updateCategory();
      _startPlaying();
      notifyListeners();
    }
  }

  void togglePlay() {
    if (isPlaying) {
      _player.pause();
      isPlaying = false;
    } else {
      _player.play();
      isPlaying = true;
    }
    notifyListeners();
  }

  void seek(double value) {
    final duration = _player.state.duration;
    final position = Duration(milliseconds: (duration.inMilliseconds * value).toInt());
    _player.seek(position);
  }

  void close() {
    _player.stop();
    category = MediaCategory.none;
    playlist = [];
    currentIndex = 0;
    isPlaying = false;
    progress = 0.0;
    notifyListeners();
  }

  // 兼容旧接口
  void openFile(FileItem file, {List<FileItem>? folderFiles}) {
    if (folderFiles != null) {
      open(file, folderFiles);
    } else {
      open(file, [file]);
    }
  }

  void openUrl(String url, {String? title, bool isVideo = false}) {
    final file = FileItem(
      name: title ?? url.split('/').last,
      path: url,
      size: 0,
      isDirectory: false,
      type: isVideo ? FileItemType.video : FileItemType.unknown,
    );
    open(file, [file]);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
