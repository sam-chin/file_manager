import 'dart:async';
// GitHub 编译：使用绝对路径导入插件具体实现
import 'package:smb_connect/src/connect/smb_client.dart';
import 'package:smb_connect/src/connect/smb_file.dart';
import '../models/file_item.dart';
import '../models/server_record.dart';

class SmbService {
  Future<List<FileItem>> listFiles(ServerRecord server, String path) async {
    // 构建 URL：注意处理空值
    final String user = server.username ?? '';
    final String pass = server.encryptedPassword ?? '';
    final String host = server.host;
    final String share = server.share ?? '';
    
    String authPart = '';
    if (user.isNotEmpty || pass.isNotEmpty) {
      authPart = '$user:$pass@';
    }
    
    final String url = "smb://$authPart$host/$share$path";
    
    try {
      // GitHub 编译：先尝试大写 SMBClient
      // 如果报错，再改成小写 SmbClient
      final client = SMBClient(url);
      
      final results = await client.list().timeout(Duration(seconds: 15));
      
      return results.map((entity) {
        final bool isDir = (entity.attributes & 0x10) != 0;
        
        return FileItem(
          name: entity.name,
          path: "$path/${entity.name}".replaceAll("//", "/"),
          // 使用 ?? 0 避免空值报错
          size: entity.size ?? 0,
          isDirectory: isDir,
          // 使用 ?? 0 避免空值报错
          modifiedTime: DateTime.fromMillisecondsSinceEpoch(entity.lastModified ?? 0),
          type: isDir ? FileType.folder : _inferType(entity.name),
        );
      }).toList();
    } catch (e) {
      print("SMB 错误: $e");
      rethrow;
    }
  }

  FileType _inferType(String name) {
    final parts = name.split('.');
    if (parts.length < 2) return FileType.unknown;
    
    final ext = parts.last.toLowerCase();
    if (['mp4', 'mkv', 'mov', 'avi', 'webm', 'm4v'].contains(ext)) {
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
