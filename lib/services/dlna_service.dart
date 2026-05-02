import 'package:dlna_dart/dlna_dart.dart';

class DlnaService {
  final DLNAManager _manager = DLNAManager();
  final List<DLNADevice> _discoveredDevices = [];

  List<DLNADevice> get devices => List.unmodifiable(_discoveredDevices);

  void searchDevices() {
    _manager.setRefershCallback((List<DLNADevice> devices) {
      _discoveredDevices.clear();
      _discoveredDevices.addAll(devices);
      
      for (var device in devices) {
        // 关键：属性在 device.info 里面
        print("发现设备: ${device.info.friendlyName}");
        print("控制URL: ${device.info.controlURL}");
      }
    });
    _manager.startSearch();
  }

  void stopSearch() {
    _manager.stop();
  }

  Future<void> castVideo(DLNADevice device, String url, String title) async {
    // 播放视频的调用方式
    await device.play(url, title: title);
  }

  Future<void> pause(DLNADevice device) async {
    await device.pause();
  }

  Future<void> stop(DLNADevice device) async {
    await device.stop();
  }

  Future<void> seek(DLNADevice device, int seconds) async {
    await device.seek(seconds);
  }
}
