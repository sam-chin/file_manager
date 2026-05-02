import 'dart:async';
import 'package:dlna_dart/dlna.dart';

class DlnaService {
  final DLNAManager _manager = DLNAManager();
  final StreamController<List<DLNADevice>> _deviceController = StreamController.broadcast();

  Stream<List<DLNADevice>> get devicesStream => _deviceController.stream;
  List<DLNADevice> _devices = [];
  DLNADevice? _currentDevice;

  List<DLNADevice> get devices => _devices;
  DLNADevice? get currentDevice => _currentDevice;

  // 启动搜索 (适配示例 start 方法)
  Future<void> startSearch() async {
    final searcher = await _manager.start();
    searcher.devices.stream.listen((deviceMap) {
      // 将 Map 转换为 List 方便 UI 展示
      _devices = deviceMap.values.toList();
      _deviceController.add(_devices);
    });
  }

  // 停止搜索
  void stopSearch() {
    _manager.stop();
  }

  // 选择投屏设备
  Future<bool> selectDevice(DLNADevice device) async {
    try {
      _currentDevice = device;
      return true;
    } catch (e) {
      print('Select Device Error: $e');
      return false;
    }
  }

  // 投屏核心逻辑
  Future<void> castVideo(DLNADevice device, String videoUrl, String title) async {
    try {
      _currentDevice = device;
      // 1. 设置播放地址
      await device.setUrl(videoUrl);
      // 2. 开始播放
      await device.play();
      print('Casting to ${device.info.friendlyName}: $videoUrl');
    } catch (e) {
      print('DLNA Cast Error: $e');
    }
  }

  // 播放控制
  Future<void> play() async {
    if (_currentDevice != null) {
      await _currentDevice!.play();
    }
  }

  Future<void> pause() async {
    if (_currentDevice != null) {
      await _currentDevice!.pause();
    }
  }

  Future<void> stop() async {
    if (_currentDevice != null) {
      await _currentDevice!.stop();
    }
  }

  // 控制指令：快进
  Future<void> seekRelative(DLNADevice device, int seconds) async {
    // 适配示例：获取当前进度并跳转
    final currentTime = await device.position();
    await device.seekByCurrent(currentTime, seconds);
  }

  Future<void> seekTo(DLNADevice device, Duration position) async {
    await device.seek(position.inSeconds);
  }

  Future<void> dispose() async {
    stopSearch();
    await _deviceController.close();
  }
}
