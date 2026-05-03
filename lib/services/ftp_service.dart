// lib/services/ftp_service.dart
import 'dart:async';
import 'package:ftpconnect/ftpconnect.dart';
import '../models/file_item.dart';
import '../models/server_record.dart';

class FtpService {
  static final FtpService _instance = FtpService._internal();
  factory FtpService() => _instance;
  FtpService._internal();

  FTPConnect? _client;
  int? _connectedServerId;

  /// AppService 统一调用入口，自动管理连接
  Future<List<FileItem>> listFiles(ServerRecord server, String path) async {
    if (_client == null || _connectedServerId != server.id) {
      await _disconnect();
      await _connect(server);
    }

    try {
      final ftpPath = path.isEmpty ? '/' : path;
      final items = await _client!
          .listDirectoryContent(ftpPath)
          .timeout(const Duration(seconds: 30));

      final result = items
          .where((e) => e.name != '.' && e.name != '..')
          .map((e) {
            final isDir = e.type == FTPEntryType.DIR;
            final filePath =
                path.isEmpty ? e.name : '$path/${e.name}';
            return FileItem(
              name: e.name,
              path: filePath,
              size: e.size ?? 0,
              modifiedTime: e.modifyDate ?? DateTime.now(),
              type: isDir ? FileType.folder : _inferType(e.name),
              isDirectory: isDir,
            );
          })
          .toList();

      result.sort((a, b) {
        if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
        return a.name.compareTo(b.name);
      });

      return result;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _connect(ServerRecord server) async {
    _client = FTPConnect(
      server.host,
      port: server.port > 0 ? server.port : 21,
      user: server.username ?? 'anonymous',
      pass: server.encryptedPassword ?? '',
      passiveMode: true,
      showLog: false,
    );
    await _client!.connect().timeout(const Duration(seconds: 30));
    _connectedServerId = server.id;
  }

  Future<void> _disconnect() async {
    try {
      await _client?.disconnect();
    } catch (_) {}
    _client = null;
    _connectedServerId = null;
  }

  FileType _inferType(String name) {
    final ext = name.contains('.')
        ? name.substring(name.lastIndexOf('.') + 1).toLowerCase()
        : '';
    if (['mp4', 'mkv', 'mov', 'avi', 'webm', 'm4v', 'iso'].contains(ext)) {
      return FileType.video;
    }
    if (['mp3', 'flac', 'wav', 'm4a', 'aac', 'ogg'].contains(ext)) {
      return FileType.audio;
    }
    if (['jpg', 'jpeg', 'png', 'heic', 'webp', 'gif', 'bmp'].contains(ext)) {
      return FileType.image;
    }
    return FileType.unknown;
  }
}
