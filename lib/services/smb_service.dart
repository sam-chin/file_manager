// lib/services/smb_service.dart
// 使用 smb_connect 0.0.9 正确 API

import 'package:smb_connect/smb_connect.dart';
import '../models/file_item.dart';
import '../models/server_record.dart';

class SmbService {
  Future<List<FileItem>> listFiles(ServerRecord server, String path) async {
    SmbConnect? connect;
    try {
      connect = await SmbConnect.connectAuth(
        host: server.host,
        domain: server.domain ?? '',
        username: server.username ?? '',
        password: server.encryptedPassword ?? '',
      );

      final folderPath = path.isEmpty ? '/' : path;
      final folder = await connect.file(folderPath);
      final items = await connect.listFiles(folder);

      final result = items.map((smbFile) {
        final isDir = smbFile.isDirectory();
        final name = _fileName(smbFile.path);
        return FileItem(
          name: name,
          path: smbFile.path,
          size: smbFile.contentLength ?? 0,
          modifiedTime: smbFile.lastModified != null
              ? DateTime.fromMillisecondsSinceEpoch(smbFile.lastModified!)
              : DateTime.now(),
          type: isDir ? FileType.folder : _inferType(name),
          isDirectory: isDir,
        );
      }).toList();

      result.sort((a, b) {
        if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
        return a.name.compareTo(b.name);
      });

      return result;
    } catch (e) {
      rethrow;
    } finally {
      await connect?.close();
    }
  }

  String _fileName(String path) {
    final trimmed =
        path.endsWith('/') ? path.substring(0, path.length - 1) : path;
    final idx = trimmed.lastIndexOf('/');
    return idx == -1 ? trimmed : trimmed.substring(idx + 1);
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
