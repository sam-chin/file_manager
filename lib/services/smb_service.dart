import 'dart:async';
import 'package:smb_connect/smb_connect.dart';
import '../models/file_item.dart';
import '../models/server_record.dart';

class SmbService {
  SmbConnect? _connection;

  // 必须添加这个 Getter，否则 AppService 会报错
  SmbConnect? get connection => _connection;

  Future<void> connect(ServerRecord server) async {
    try {
      // 这里的 host 逻辑支持了你要求的端口功能
      String host = server.port == 445 ? server.ip : "${server.ip}:${server.port}";

      _connection = await SmbConnect.connectAuth(
        host: host,
        domain: "",
        username: server.username,
        password: server.password,
      ).timeout(const Duration(seconds: 15));

      // 强制握手激活
      await _connection!.listShares();
    } catch (e) {
      _connection = null;
      rethrow;
    }
  }

  Future<void> close() async {
    try {
      await _connection?.close();
      _connection = null;
    } catch (_) {}
  }

  Future<List<FileItem>> list(String path) async {
    if (_connection == null) return [];
    var folder = await _connection!.file(path);
    var files = await _connection!.listFiles(folder);
    
    return files.map((f) {
      final bool isDir = f.isDirectory();
      return FileItem(
        name: f.path.split('/').last.isEmpty ? f.path : f.path.split('/').last,
        path: f.path,
        size: f.size,
        isDirectory: isDir,
        type: isDir ? FileItemType.folder : FileItemType.video,
      );
    }).toList();
  }

  Future<void> delete(String path) async {
    if (_connection == null) return;
    var f = await _connection!.file(path);
    await _connection!.delete(f);
  }
}
