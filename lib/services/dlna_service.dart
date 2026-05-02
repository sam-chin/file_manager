import 'dart:async';
import 'dart:collection';
import 'package:dlna_dart/dlna_dart.dart';
import '../entities/device_entity.dart';

class DlnaService {
  static final DlnaService _instance = DlnaService._internal();
  factory DlnaService() => _instance;
  DlnaService._internal();

  DLNAManager? _dlnaManager;
  DLNARenderer? _currentRenderer;
  final Map<String, DeviceEntity> _discoveredDevices = HashMap();
  final StreamController<List<DeviceEntity>> _devicesController =
      StreamController.broadcast();
  Timer? _refreshTimer;
  bool _isSearching = false;

  bool get isSearching => _isSearching;
  List<DeviceEntity> get devices => List.unmodifiable(_discoveredDevices.values);
  Stream<List<DeviceEntity>> get devicesStream => _devicesController.stream;
  DeviceEntity? get currentDevice => _currentRenderer != null
      ? _rendererToEntity(_currentRenderer!)
      : null;

  Future<void> initialize() async {
    if (_dlnaManager != null) return;

    try {
      _dlnaManager = DLNAManager();
      _dlnaManager!.setDeviceChangeCallback((devices) {
        _onDeviceListChanged(devices);
      });
    } catch (e) {
      _dlnaManager = null;
    }
  }

  Future<void> startSearch({Duration duration = const Duration(seconds: 10)}) async {
    if (_isSearching || _dlnaManager == null) return;

    try {
      _isSearching = true;
      _discoveredDevices.clear();
      _devicesController.add([]);

      await _dlnaManager!.startSearch();

      _refreshTimer?.cancel();
      _refreshTimer = Timer(duration, () {
        stopSearch();
      });
    } catch (e) {
      _isSearching = false;
    }
  }

  Future<void> stopSearch() async {
    if (_dlnaManager == null) return;

    try {
      _refreshTimer?.cancel();
      _refreshTimer = null;
      await _dlnaManager!.stopSearch();
    } finally {
      _isSearching = false;
    }
  }

  Future<bool> selectDevice(DeviceEntity device) async {
    if (_dlnaManager == null) return false;

    try {
      final renderers = _dlnaManager!.getDevices();
      _currentRenderer = renderers.firstWhere(
        (renderer) => _deviceId(renderer) == device.id,
        orElse: () => null,
      );

      if (_currentRenderer != null) {
        return true;
      }
      return false;
    } catch (e) {
      _currentRenderer = null;
      return false;
    }
  }

  Future<void> clearSelectedDevice() async {
    try {
      if (_currentRenderer != null) {
        await _currentRenderer!.stop();
      }
    } finally {
      _currentRenderer = null;
    }
  }

  Future<bool> setVideoUri(String uri) async {
    if (_currentRenderer == null) return false;

    try {
      await _currentRenderer!.setVideoUri(uri);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> play() async {
    if (_currentRenderer == null) return false;

    try {
      await _currentRenderer!.play();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> pause() async {
    if (_currentRenderer == null) return false;

    try {
      await _currentRenderer!.pause();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> stop() async {
    if (_currentRenderer == null) return false;

    try {
      await _currentRenderer!.stop();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> seek(Duration position) async {
    if (_currentRenderer == null) return false;

    try {
      final seconds = position.inSeconds;
      await _currentRenderer!.seek(seconds);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Duration?> getPosition() async {
    if (_currentRenderer == null) return null;

    try {
      final info = await _currentRenderer!.getPositionInfo();
      if (info.relTime != null) {
        return _parseDuration(info.relTime!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Duration?> getDuration() async {
    if (_currentRenderer == null) return null;

    try {
      final info = await _currentRenderer!.getMediaInfo();
      if (info.trackDuration != null) {
        return _parseDuration(info.trackDuration!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Duration? _parseDuration(String durationStr) {
    try {
      final parts = durationStr.split(':');
      if (parts.length == 3) {
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        final seconds = double.tryParse(parts[2]) ?? 0;
        return Duration(
          hours: hours,
          minutes: minutes,
          seconds: seconds.toInt(),
          milliseconds: ((seconds - seconds.toInt()) * 1000).toInt(),
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  void _onDeviceListChanged(List<DLNADevice> devices) {
    for (final device in devices) {
      final entity = _deviceToEntity(device);
      _discoveredDevices[entity.id] = entity;
    }
    _devicesController.add(this.devices);
  }

  DeviceEntity _deviceToEntity(DLNADevice device) {
    return DeviceEntity(
      id: _deviceId(device),
      name: device.friendlyName ?? 'Unknown Device',
      location: device.location ?? '',
      udn: device.udn,
      manufacturer: device.manufacturer,
      modelName: device.modelName,
    );
  }

  DeviceEntity _rendererToEntity(DLNARenderer renderer) {
    return DeviceEntity(
      id: _deviceId(renderer),
      name: renderer.friendlyName ?? 'Unknown Device',
      location: renderer.location ?? '',
      udn: renderer.udn,
      manufacturer: renderer.manufacturer,
      modelName: renderer.modelName,
    );
  }

  String _deviceId(DLNADevice device) {
    return device.udn ?? device.location ?? device.friendlyName ?? '';
  }

  Future<void> dispose() async {
    await stopSearch();
    await clearSelectedDevice();
    await _devicesController.close();
    _discoveredDevices.clear();
    _dlnaManager = null;
  }
}
