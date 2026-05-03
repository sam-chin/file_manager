import 'dart:async';
import 'package:smb_connect/smb_connect.dart';
import '../models/file_item.dart';
import '../models/server_record.dart';

class SmbService {
  SmbConnect? _connection;

  Future<void> connect(ServerRecord server) async {
    await close();

    try {
      String hostWithPort = "${server.ip}:${server.port}";

      _connection = await SmbConnect.connectAuth(
        host: hostWithPort,
        domain: "",
        username: server.username,
        password: server.password,
      ).timeout(const Duration(seconds: 15));

      if (server.shareName != null && server.shareName!.isNotEmpty) {
        String path = server.shareName!.startsWith('/') ? server.shareName! : "/${server.shareName}";
        var folder = await _connection!.file(path);
        await _connection!.listFiles(folder);
      } else {
        await _connection!.listShares();
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains("SmbAuthException")) {
        throw "认证失败：请检查用户名和密码。SMB1服务器可能需要开启 NTLMv1 支持。";
      } else if (errorMsg.contains("Failed to connect")) {
        throw "无法连接到 ${server.ip}:${server.port}，请检查 IP 和端口是否被防火墙拦截。";
      }
      throw "SMB 错误: $errorMsg";
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
