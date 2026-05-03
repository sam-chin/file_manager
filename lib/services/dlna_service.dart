import 'package:dlna_dart/dlna_dart.dart';

class DlnaService {
  // 0.0.8 版本的 DLNAManager
  final DLNAManager _manager = DLNAManager();
  final List<DLNADevice> _discoveredDevices = [];

  List<DLNADevice> get devices => List.unmodifiable(_discoveredDevices);

  void init() {
    // 这里的 callback 接收的是 List<DLNADevice>
    _manager.setRefershCallback((devices) {
      _discoveredDevices.clear();
      _discoveredDevices.addAll(devices);
      
      for (var device in devices) {
        // 访问 info 属性
        print("找到设备: ${device.info.friendlyName}");
      }
    });
  }

  Future<void> startSearch() async {
    _manager.startSearch();
  }

  Future<void> stopSearch() async {
    _manager.stop();
  }

  Future<void> cast(dynamic device, String url, String title) async {
    // 检查具体 device 是否为 DLNADevice 类型
    if (device is DLNADevice) {
      await device.play(url, title: title);
    }
  }
}
