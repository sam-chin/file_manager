import 'dart:async';
import 'package:dlna_dart/dlna.dart';

class DlnaService {
  final DLNAManager _searcher = DLNAManager();
  StreamSubscription? _subscription;
  
  // 存储发现的设备映射 <ID, 设备对象>
  Map<String, DLNADevice> devices = {};

  Future<void> startSearch() async {
    // 对应示例：searcher.start()
    final manager = await _searcher.start(reusePort: true);
    
    // 对应示例：m.devices.stream.listen
    _subscription?.cancel();
    _subscription = manager.devices.stream.listen((deviceMap) {
      devices = deviceMap;
      devices.forEach((key, value) {
        print("发现设备: ${value.info.friendlyName}");
      });
    });
  }

  Future<void> cast(DLNADevice device, String url, String title) async {
    // 0.0.8 投屏通常使用 play 方法
    await device.play(url, title: title);
  }

  void stop() {
    _subscription?.cancel();
    _searcher.stop();
  }
}