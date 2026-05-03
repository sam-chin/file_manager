import 'package:dlna_dart/dlna_dart.dart';

class DlnaService {
  // GitHub 编译：延迟初始化，避免静态初始化错误
  DLNAManager? _manager;
  final List<dynamic> _discoveredDevices = [];

  List<dynamic> get devices => List.unmodifiable(_discoveredDevices);

  void init() {
    _manager = DLNAManager();
    _manager?.setRefershCallback((devices) {
      _discoveredDevices.clear();
      _discoveredDevices.addAll(devices);
      
      for (var device in devices) {
        // 使用动态类型访问，避免编译期找不到类型
        try {
          print("找到设备: ${device.info.friendlyName}");
        } catch (e) {
          print("设备信息读取失败: $e");
        }
      }
    });
  }

  Future<void> startSearch() async {
    if (_manager == null) {
      init();
    }
    _manager?.startSearch();
  }

  Future<void> stopSearch() async {
    _manager?.stop();
  }

  Future<void> cast(dynamic device, String url, String title) async {
    // GitHub 编译：使用动态类型判断，规避类型找不到问题
    try {
      // 尝试直接调用 play 方法
      await device.play(url, title: title);
    } catch (e) {
      print("投屏失败: $e");
      rethrow;
    }
  }
}
