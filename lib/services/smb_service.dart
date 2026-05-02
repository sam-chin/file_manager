import 'dart:async';
import 'package:smb_connect/smb_connect.dart';
import '../models/file_item.dart';

class SmbService {
  // 核心：判断是否为目录的位掩码 (0x10)
  static const int ATTR_DIRECTORY = 0x10;

  SmbClient? _client;
  String? _currentUrl;

  bool get isConnected => _client != null;

  Future<bool> connect({
    required String host,
    required String share,
    String? domain,
    String? username,
    String? password,
  }) async {
    try {
      // 构建 SMB URL
      final auth = NtlmPasswordAuthenticator(
        domain: domain ?? "",
        username: username ?? "guest",
        password: password ?? "",
      );

      // 使用官方示例的连接方式
      final config = PropertiesConfiguration({});
      _currentUrl = "smb://$host/$share";
      _client = SmbClient(_currentUrl!, config, auth);
      return true;
    } catch (e) {
      print("SMB Connect Error: $e");
      return false;
    }
  }

  Future<List<FileItem>> listFiles(String url) async {
    try {
      if (_client == null) {
        throw Exception("Not connected");
      }

      List<SmbFile> files = await _client!.list();

      return files.map((entity) {
        // 关键：通过位运算判断是否为文件夹
        bool isDir = (entity.attributes & ATTR_DIRECTORY) != 0;
        
        // 构建完整路径
        final fullPath = url.isEmpty ? entity.name : "$url/${entity.name}";
        
        return FileItem(
          name: entity.name,
          path: fullPath,
          // 注意：是 fileSize 而不是 size
          size: entity.fileSize,
          // 注意：是 lastWriteTime 而不是 modifiedTime
          modifiedTime: DateTime.fromMillisecondsSinceEpoch(entity.lastWriteTime),
          isDirectory: isDir,
          type: isDir ? FileType.folder : _inferType(entity.name),
        );
      }).toList();
    } catch (e) {
      print("SMB List Error: $e");
      rethrow;
    }
  }

  FileType _inferType(String name) {
    final parts = name.split('.');
    if (parts.length < 2) return FileType.unknown;
    
    final ext = parts.last.toLowerCase();
    if (['mp4', 'mkv', 'mov', 'avi', 'webm', 'm4v', 'iso'].contains(ext)) {
      return FileType.video;
    }
    if (['mp3', 'flac', 'wav', 'm4a', 'aac', 'ogg'].contains(ext)) {
      return FileType.audio;
    }
    if (['jpg', 'jpeg', 'png', 'heic', 'webp', 'gif', 'bmp'].contains(ext)) {
      return FileType.image;
    }
    if (['pdf', 'doc', 'docx', 'txt', 'xlsx', 'pptx'].contains(ext)) {
      return FileType.document;
    }
    return FileType.unknown;
  }

  Future<void> disconnect() async {
    _client = null;
  }
}
