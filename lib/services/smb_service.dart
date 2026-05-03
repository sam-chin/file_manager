import 'dart:async';
import 'package:smb_connect/smb_connect.dart';
import '../models/file_item.dart';

class SmbService {
  SmbConnect? _connection;

  Future<void> connect(String ip, String user, String pass) async {
    await disconnect();
    _connection = await SmbConnect.connectAuth(
      host: ip,
      domain: "",
      username: user,
      password: pass,
    );
  }

  Future<List<FileItem>> getList(String path) async {
    if (_connection == null) throw "SMB 未连接";
    
    SmbFile folder = await _connection!.file(path);
    List<SmbFile> files = await _connection!.listFiles(folder);
    
    return files.map((f) {
      final bool isDir = f.isDirectory();
      return FileItem(
        name: f.path.split('/').last.isEmpty ? f.path : f.path.split('/').last,
        path: f.path,
        size: f.fileSize,
        isDirectory: isDir,
        type: isDir ? FileItemType.folder : _inferType(f.path),
      );
    }).toList();
  }

  // 补全管理功能
  Future<void> mkdir(String path) async => await _connection?.createFolder(path);
  Future<void> delete(String path) async {
    if (_connection == null) return;
    final f = await _connection!.file(path);
    await _connection!.delete(f);
  }
  Future<void> rename(String oldPath, String newPath) async {
    if (_connection == null) return;
    final oldF = await _connection!.file(oldPath);
    await _connection!.rename(oldF, newPath);
  }

  Future<void> disconnect() async {
    await _connection?.close();
    _connection = null;
  }

  FileItemType _inferType(String path) {
    final p = path.toLowerCase();
    if (p.endsWith(".mp4") || p.endsWith(".mkv")) return FileItemType.video;
    if (p.endsWith(".mp3")) return FileItemType.audio;
    return FileItemType.other;
  }
}