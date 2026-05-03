// lib/services/dlna_service.dart
// 使用 dlna_dart 0.1.0 的正确 API:
//   DLNAManager().start() → manager
//   manager.devices.stream.listen((Map<String, DLNADevice> deviceMap) {})
//   searcher.stop() 关闭搜索

import 'dart:async';
import 'package:dlna_dart/dlna_dart.dart';

class DlnaService {
  final DLNAManager _searcher = DLNAManager();

  // 已发现的设备（key = UDN，value = DLNADevice）
  final Map<String, DLNADevice> _devices = {};
  StreamSubscription? _subscription;

  Map<String, DLNADevice> get devices => Map.unmodifiable(_devices);

  /// 开始搜索 DLNA 设备，通过 [onDevicesChanged] 回调通知 UI 刷新
  Future<void> startSearch({
    void Function(Map<String, DLNADevice> devices)? onDevicesChanged,
  }) async {
    await stopSearch(); // 先停止上一次搜索

    final manager = await _searcher.start();

    _subscription = manager.devices.stream.listen((deviceMap) {
      _devices
        ..clear()
        ..addAll(deviceMap);
      onDevicesChanged?.call(Map.unmodifiable(_devices));
    });
  }

  Future<void> stopSearch() async {
    await _subscription?.cancel();
    _subscription = null;
    _searcher.stop();
    _devices.clear();
  }

  /// 向指定设备投屏
  /// [device] 从 devices 中取得的 DLNADevice
  /// [url]    媒体资源的 HTTP URL（需要代理服务器提供）
  /// [title]  显示标题
  Future<void> cast(DLNADevice device, String url, String title) async {
    try {
      await device.setUrl(url, title);
      await device.play();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> pause(DLNADevice device) async {
    await device.pause();
  }

  Future<void> stop(DLNADevice device) async {
    await device.stop();
  }
}
