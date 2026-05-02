import 'dart:async';
import 'dart:collection';
import 'package:dlna_dart/dlna_dart.dart';
import '../entities/device_entity.dart';

class DlnaService {
  static final DlnaService _instance = DlnaService._internal();
  factory DlnaService() => _instance;
  DlnaService._internal();

  DlnaManager? _dlnaManager;
  DlnaDevice? _currentDevice;
  final Map<String, DeviceEntity> _discoveredDevices = HashMap();
  final StreamController<List<DeviceEntity>> _devicesController =
      StreamController.broadcast();
  Timer? _refreshTimer;
  bool _isSearching = false;

  bool get isSearching => _isSearching;
  List<DeviceEntity> get devices => List.unmodifiable(_discoveredDevices.values);
  Stream<List<DeviceEntity>> get devicesStream => _devicesController.stream;
  DeviceEntity? get currentDevice => _currentDevice != null
      ? _dlnaDeviceToEntity(_currentDevice!)
      : null;

  Future<void> initialize() async {
    if (_dlnaManager != null) return;

    try {
      _dlnaManager = DlnaManager();
      _dlnaManager!.setDeviceChangeCallback((newDevices) {
        _onDeviceListChanged(newDevices);
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
      final devices = _dlnaManager!.getDevices();
      _currentDevice = devices.firstWhere(
        (d) => _deviceId(d) == device.id,
        orElse: () => null,
      );

      if (_currentDevice != null) {
        return true;
      }
      return false;
    } catch (e) {
      _currentDevice = null;
      return false;
    }
  }

  Future<void> clearSelectedDevice() async {
    try {
      if (_currentDevice != null) {
        await _currentDevice!.stop();
      }
    } finally {
      _currentDevice = null;
    }
  }

  Future<bool> setVideoUri(String uri) async {
    if (_currentDevice == null) return false;

    try {
      await _currentDevice!.setVideoUri(uri);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> play() async {
    if (_currentDevice == null) return false;

    try {
      await _currentDevice!.play();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> pause() async {
    if (_currentDevice == null) return false;

    try {
      await _currentDevice!.pause();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> stop() async {
    if (_currentDevice == null) return false;

    try {
      await _currentDevice!.stop();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> seek(Duration position) async {
    if (_currentDevice == null) return false;

    try {
      final seconds = position.inSeconds;
      await _currentDevice!.seek(seconds);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Duration?> getPosition() async {
    if (_currentDevice == null) return null;

    try {
      final info = await _currentDevice!.getPositionInfo();
      if (info.relTime != null) {
        return _parseDuration(info.relTime!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Duration?> getDuration() async {
    if (_currentDevice == null) return null;

    try {
      final info = await _currentDevice!.getMediaInfo();
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

  void _onDeviceListChanged(List<DlnaDevice> devices) {
    for (final device in devices) {
      final entity = _dlnaDeviceToEntity(device);
      _discoveredDevices[entity.id] = entity;
    }
    _devicesController.add(this.devices);
  }

  DeviceEntity _dlnaDeviceToEntity(DlnaDevice device) {
    return DeviceEntity(
      id: _deviceId(device),
      name: device.friendlyName ?? 'Unknown Device',
      location: device.location ?? '',
      udn: device.udn,
      manufacturer: device.manufacturer,
      modelName: device.modelName,
    );
  }

  String _deviceId(DlnaDevice device) {
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
