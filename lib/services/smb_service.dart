import 'dart:async';
import 'package:smb_connect/smb_connect.dart';
import '../models/file_item.dart';
import '../models/server_record.dart';

class SmbService {
  // 0.0.9 版本的实现，完全对齐真实 API
  // 不需要任何 Config 或 Auth 类，认证信息直接在 URL 中
  
  Future<List<FileItem>> listFiles(ServerRecord server, String path) async {
    // 构造 URL：smb://user:password@host/share/path
    final String userPart = (server.username ?? '');
    final String passPart = (server.encryptedPassword ?? '');
    final String sharePart = (server.share ?? '');
    
    String authPart = '';
    if (userPart.isNotEmpty || passPart.isNotEmpty) {
      authPart = '$userPart:$passPart@';
    }
    
    final String url = "smb://$authPart${server.host}/$sharePart$path";
    
    // 0.0.9 直接通过 URL 实例化
    final client = SmbClient(url);

    try {
      final List<SmbFile> results = await client.list().timeout(Duration(seconds: 10));
      
      return results.map((entity) {
        // 关键位运算：判断是否为目录
        final bool isDir = (entity.attributes & 0x10) != 0;
        
        return FileItem(
          name: entity.name,
          path: "$path/${entity.name}".replaceAll("//", "/"),
          size: entity.size, // 0.0.9 是 size 不是 fileSize
          isDirectory: isDir,
          modifiedTime: DateTime.fromMillisecondsSinceEpoch(entity.lastModified),
          type: isDir ? FileType.folder : _inferType(entity.name),
        );
      }).toList();
    } catch (e) {
      print("SMB 连接错误: $e");
      rethrow;
    }
  }

  FileType _inferType(String name) {
    final parts = name.split('.');
    if (parts.length < 2) return FileType.unknown;
    
    final ext = parts.last.toLowerCase();
    if (['mp4', 'mkv', 'mov', 'avi', 'webm', 'm4v'].contains(ext)) return FileType.video;
    if (['mp3', 'flac', 'wav', 'm4a', 'aac', 'ogg'].contains(ext)) return FileType.audio;
    if (['jpg', 'jpeg', 'png', 'heic', 'webp', 'gif', 'bmp'].contains(ext)) return FileType.image;
    return FileType.unknown;
  }
}
