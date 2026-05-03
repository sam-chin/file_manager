import 'dart:async';
import 'package:smb_connect/smb_connect.dart';
import '../models/file_item.dart';
import '../models/server_record.dart';

class SmbService {
  SmbConnect? _connection;

  SmbConnect? get connection => _connection;

  List<String> hiddenPaths = [];

  Future<void> connect(ServerRecord server) async {
    try {
      String host = "${server.ip}:${server.port}";

      _connection = await SmbConnect.connectAuth(
        host: host,
        domain: "WORKGROUP",
        username: server.username.trim(),
        password: server.password,
      ).timeout(const Duration(seconds: 15));

      await _connection!.listShares();
    } catch (e) {
      _connection = null;
      rethrow;
    }
  }

  Future<List<FileItem>> list(String path) async {
    if (_connection == null) return [];

    try {
      var folder = await _connection!.file(path);
      var files = await _connection!.listFiles(folder);

      return files.map((f) {
        final bool isDir = f.isDirectory();
        final String fileName = _extractFileName(f.path);

        return FileItem(
          name: fileName,
          path: f.path,
          size: f.size,
          isDirectory: isDir,
          type: isDir ? FileItemType.folder : _determineType(fileName),
        );
      }).toList();
    } catch (e) {
      print("SMB2 读取列表失败: $e");
      return [];
    }
  }

  Future<List<FileItem>> listFoldersByMedia(String path, FileItemType targetType) async {
    if (_connection == null) return [];
    var folder = await _connection!.file(path);
    var allItems = await _connection!.listFiles(folder);
    List<FileItem> result = [];

    for (var item in allItems) {
      if (hiddenPaths.contains(item.path)) continue;

      if (item.isDirectory()) {
        if (await _hasMediaDeep(item.path, targetType)) {
          result.add(FileItem(
            name: _extractFileName(item.path),
            path: item.path,
            size: 0,
            isDirectory: true,
            type: FileItemType.folder,
          ));
        }
      }
    }
    return result;
  }

  Future<bool> _hasMediaDeep(String path, FileItemType targetType) async {
    try {
      var folder = await _connection!.file(path);
      var files = await _connection!.listFiles(folder);
      return files.any((f) => !f.isDirectory() && _determineType(_extractFileName(f.path)) == targetType);
    } catch (_) {
      return false;
    }
  }

  Future<void> close() async {
    try {
      await _connection?.close();
      _connection = null;
    } catch (_) {}
  }

  String _extractFileName(String path) {
    if (path == "/" || path.isEmpty) return "Root";
    List<String> parts = path.split(RegExp(r'[/\\]'));
    return parts.lastWhere((s) => s.isNotEmpty, orElse: () => path);
  }

  FileItemType _determineType(String name) {
    final n = name.toLowerCase();

    if (n.endsWith('.mp4') || n.endsWith('.mkv') || n.endsWith('.mov') || n.endsWith('.avi')) {
      return FileItemType.video;
    } else if (n.endsWith('.mp3') || n.endsWith('.wav') || n.endsWith('.flac') || n.endsWith('.m4a')) {
      return FileItemType.audio;
    } else if (n.endsWith('.jpg') || n.endsWith('.jpeg') || n.endsWith('.png') || n.endsWith('.gif')) {
      return FileItemType.image;
    }

    return FileItemType.other;
  }

  Future<void> delete(String path) async {
    if (_connection == null) return;
    var f = await _connection!.file(path);
    await _connection!.delete(f);
  }
}
