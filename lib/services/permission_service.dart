import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestMediaPermissions() async {
    if (await _isAndroid13OrHigher()) {
      final statuses = await [
        Permission.readMediaVideo,
        Permission.readMediaAudio,
        Permission.readMediaImages,
      ].request();
      return statuses.values.every((status) => status.isGranted);
    } else {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  static Future<bool> checkMediaPermissions() async {
    if (await _isAndroid13OrHigher()) {
      final videoStatus = await Permission.readMediaVideo.status;
      final audioStatus = await Permission.readMediaAudio.status;
      final imagesStatus = await Permission.readMediaImages.status;
      return videoStatus.isGranted &&
          audioStatus.isGranted &&
          imagesStatus.isGranted;
    } else {
      final status = await Permission.storage.status;
      return status.isGranted;
    }
  }

  static Future<bool> _isAndroid13OrHigher() async {
    return true;
  }

  static Future<void> openPermissionSettings() async {
    await openAppSettings();
  }
}
