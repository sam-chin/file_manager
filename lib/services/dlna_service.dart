import 'dart:async';
import 'package:dlna_dart/dlna_dart.dart';

class DlnaService {
  static final DlnaService _instance = DlnaService._internal();
  factory DlnaService() => _instance;
  DlnaService._internal();

  Dlna? _dlna;
  DlnaDevice? _currentDevice;
  final StreamController<List<DlnaDevice>> _devicesController =
      StreamController.broadcast();
  final List<DlnaDevice> _devices = [];

  Stream<List<DlnaDevice>> get devicesStream => _devicesController.stream;
  List<DlnaDevice> get devices => List.unmodifiable(_devices);

  Future<void> startDiscovery() async {
    _dlna = Dlna();
    _dlna!.search((device) {
      if (!_devices.any((d) => d.uuid == device.uuid)) {
        _devices.add(device);
        _devicesController.add(List.unmodifiable(_devices));
      }
    });
  }

  void stopDiscovery() {
    _dlna?.stop();
  }

  Future<void> selectDevice(DlnaDevice device) async {
    _currentDevice = device;
  }

  Future<void> setUrl(String url) async {
    if (_currentDevice == null) return;
    await _currentDevice!.setUrl(url);
  }

  Future<void> play() async {
    if (_currentDevice == null) return;
    await _currentDevice!.play();
  }

  Future<void> pause() async {
    if (_currentDevice == null) return;
    await _currentDevice!.pause();
  }

  Future<void> stop() async {
    if (_currentDevice == null) return;
    await _currentDevice!.stop();
  }

  Future<void> seek(Duration position) async {
    if (_currentDevice == null) return;
    await _currentDevice!.seek(position);
  }

  Future<Duration?> getPosition() async {
    if (_currentDevice == null) return null;
    return _currentDevice!.position;
  }

  Future<Duration?> getDuration() async {
    if (_currentDevice == null) return null;
    return _currentDevice!.duration;
  }

  void dispose() {
    _devicesController.close();
    stopDiscovery();
  }
}

class DlnaDevice {
  final String uuid;
  final String name;
  final String location;

  DlnaDevice({
    required this.uuid,
    required this.name,
    required this.location,
  });

  Future<void> setUrl(String url) async {}
  Future<void> play() async {}
  Future<void> pause() async {}
  Future<void> stop() async {}
  Future<void> seek(Duration position) async {}
  Future<Duration?> get position async => null;
  Future<Duration?> get duration async => null;
}
