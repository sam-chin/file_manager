import 'dart:io';
import 'dart:async';
// 确保这是唯一的 smb 导入
import 'package:smb_connect/smb_connect.dart' as smb;

class FileEntity {
  final String name;
  final String path;
  final int size;
  final bool isDirectory;

  FileEntity({
    required this.name,
    required this.path,
    required this.size,
    this.isDirectory = false,
  });
}

class SmbService {
  // 使用 smb 前缀避免类型冲突，或者直接使用 dynamic 规避编译期找不到类型的问题
  dynamic _connection;
  String? _connectedHost;
  String? _connectedShare;
  String? _connectedDomain;
  String? _connectedUsername;
  String? _connectedPassword;

  bool get isConnected => _connection != null;
  String? get connectedHost => _connectedHost;
  String? get connectedShare => _connectedShare;

  Future<bool> connect({
    required String host,
    required String share,
    String? domain,
    String? username,
    String? password,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      await disconnect();

      // 0.0.9 正确的初始化逻辑
      final config = smb.Configuration();
      final auth = smb.NtlmPasswordAuthenticator(
        domain: domain ?? '',
        username: username ?? 'guest',
        password: password ?? '',
      );

      // 在 0.0.9 中，通常是通过 SmbClient 或 SmbFile 开启上下文
      _connection = smb.SmbClient(host, share, auth);

      // 模拟连接尝试（该库通常是懒加载连接，通过访问根目录测试）
      await (_connection as smb.SmbClient).connect().timeout(timeout);

      _connectedHost = host;
      _connectedShare = share;
      _connectedDomain = domain;
      _connectedUsername = username;
      _connectedPassword = password;

      return true;
    } catch (e) {
      print('SMB Connect Error: $e');
      return false;
    }
  }

  Future<List<FileEntity>> listFiles(
    String path, {
    bool recursive = false,
    bool filterVideos = false,
  }) async {
    if (_connection == null) throw StateError("SMB Not Connected");

    final List<FileEntity> result = [];
    try {
      final files = await (_connection as smb.SmbClient).listFiles(path);
      
      for (final file in files) {
        final filePath = path.isEmpty ? file.name : '$path/${file.name}';
        final entity = FileEntity(
          name: file.name,
          path: filePath,
          size: file.isDirectory ? 0 : file.fileSize,
          isDirectory: file.isDirectory,
        );

        if (!filterVideos || entity.isDirectory || _isVideoFile(entity.name)) {
          result.add(entity);
        }

        if (recursive && entity.isDirectory) {
          try {
            final subFiles = await listFiles(
              filePath,
              recursive: true,
              filterVideos: filterVideos,
            );
            result.addAll(subFiles);
          } catch (_) {}
        }
      }

      result.sort((a, b) {
        if (a.isDirectory != b.isDirectory) {
          return a.isDirectory ? -1 : 1;
        }
        return a.name.compareTo(b.name);
      });

      return result;
    } catch (e) {
      print('SMB List Files Error: $e');
      return [];
    }
  }

  Future<FileEntity?> getFileInfo(String path) async {
    if (_connection == null) throw StateError("SMB Not Connected");

    try {
      final parentPath = _getParentPath(path);
      final fileName = _getFileName(path);

      final files = await (_connection as smb.SmbClient).listFiles(parentPath);
      
      for (final file in files) {
        if (file.name == fileName) {
          return FileEntity(
            name: file.name,
            path: path,
            size: file.isDirectory ? 0 : file.fileSize,
            isDirectory: file.isDirectory,
          );
        }
      }

      return null;
    } catch (e) {
      print('SMB Get File Info Error: $e');
      return null;
    }
  }

  Future<Stream<List<int>>> openInputStream(String path) async {
    if (_connection == null) throw Exception("SMB Not Connected");
    // 适配 0.0.9 的读取流方法
    return (_connection as smb.SmbClient).openFileRead(path);
  }

  Future<void> disconnect() async {
    if (_connection != null) {
      try {
        await (_connection as smb.SmbClient).disconnect();
      } catch (e) {
        print('SMB Disconnect Error: $e');
      }
      _connection = null;
      _connectedHost = null;
      _connectedShare = null;
      _connectedDomain = null;
      _connectedUsername = null;
      _connectedPassword = null;
    }
  }

  bool _isVideoFile(String fileName) {
    final lower = fileName.toLowerCase();
    const videoExtensions = ['mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm', 'iso', 'm4v'];
    for (final ext in videoExtensions) {
      if (lower.endsWith('.$ext')) {
        return true;
      }
    }
    return false;
  }

  String _getParentPath(String path) {
    if (!path.contains('/')) return '';
    return path.substring(0, path.lastIndexOf('/'));
  }

  String _getFileName(String path) {
    if (!path.contains('/')) return path;
    return path.substring(path.lastIndexOf('/') + 1);
  }
}
