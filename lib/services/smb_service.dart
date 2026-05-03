import 'dart:async';
import 'package:smb_connect/smb_connect.dart';
import '../models/file_item.dart';
import '../models/server_record.dart';

class SmbService {
  SmbConnect? connection;

  Future<void> connect(ServerRecord server) async {
    try {
      connection = await SmbConnect.connectAuth(
        host: server.ip,
        domain: "",
        username: server.username,
        password: server.password,
      ).timeout(const Duration(seconds: 15));

      if (server.shareName != null && server.shareName!.isNotEmpty) {
        var folder = await connection!.file(server.shareName!);
        await connection!.listFiles(folder);
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains("SmbAuthException")) {
        throw "登录失败：请检查用户名（支持中文）和密码是否正确。";
      } else if (errorMsg.contains("Connection refused")) {
        throw "无法连接：服务器可能未开启 SMB 服务或 IP 错误。";
      }
      throw "错误: $errorMsg";
    }
  }

  Future<List<FileItem>> list(String path) async {
    if (connection == null) return [];
    var folder = await connection!.file(path);
    var files = await connection!.listFiles(folder);
    
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
    if (connection == null) return;
    var f = await connection!.file(path);
    await connection!.delete(f);
  }
}
