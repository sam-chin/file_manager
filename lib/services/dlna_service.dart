// lib/services/dlna_service.dart
// 使用 dlna_dart 0.0.8 的正确 API
// 注意：setRefershCallback 是原包的拼写（不是 setRefreshCallback）

import 'package:dlna_dart/dlna_dart.dart';

class DlnaService {
  final DLNAManager _manager = DLNAManager();
  final List<dynamic> _devices = [];

  List<dynamic> get devices => List.unmodifiable(_devices);

  Future<void> startSearch({
    void Function(List<dynamic> devices)? onDevicesChanged,
  }) async {
    _devices.clear();

    // 0.0.8 API: setRefershCallback（原包拼写错误，保留）
    _manager.setRefershCallback((deviceList) {
      _devices.clear();
      _devices.addAll(deviceList);
      onDevicesChanged?.call(List.unmodifiable(_devices));
    });

    _manager.startSearch();
  }

  Future<void> stopSearch() async {
    _manager.stop();
    _devices.clear();
  }

  // device 为 dynamic，因为 0.0.8 不导出具体类型
  Future<void> cast(dynamic device, String url, String title) async {
    try {
      await device.play(url, title: title);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> pause(dynamic device) async {
    try {
      await device.pause();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> stop(dynamic device) async {
    try {
      await device.stop();
    } catch (e) {
      rethrow;
    }
  }
}
