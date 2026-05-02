import 'dart:io';
import 'dart:typed_data';
import 'package:smb_connect/smb_connect.dart';

// 定义 UI 通用模型，确保 file_browser_page.dart 不再报错
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
  // 按照示例，保存 SmbConnect 实例
  SmbConnect? _connection;
  String? _currentHost;
  String? _connectedShare;
  String? _connectedDomain;
  String? _connectedUsername;
  String? _connectedPassword;

  bool get isConnected => _connection != null;
  String? get connectedHost => _currentHost;
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

      _currentHost = host;
      _connectedShare = share;
      _connectedDomain = domain;
      _connectedUsername = username;
      _connectedPassword = password;

      // 官方示例 0.0.9 的连接方式
      _connection = await SmbConnect.connectAuth(
        host: host,
        domain: domain ?? "",
        username: username ?? 'guest',
        password: password ?? '',
      );

      // 测试：尝试获取共享列表
      await _connection!.listShares();
      return true;
    } catch (e) {
      print("SMB Connection Failed: $e");
      return false;
    }
  }

  Future<List<FileEntity>> listFiles(
    String path, {
    bool recursive = false,
    bool filterVideos = false,
  }) async {
    if (_connection == null) return [];
    try {
      // 适配示例：先获取文件夹对象，再列出文件
      final fullPath = _connectedShare != null 
          ? "$_connectedShare/$path" 
          : path;
      SmbFile folder = await _connection!.file(fullPath);
      List<SmbFile> files = await _connection!.listFiles(folder);

      final result = files.map((f) => FileEntity(
        name: f.name,
        path: path.isEmpty ? f.name : '$path/${f.name}',
        size: 0, // 0.0.9 版本暂不获取 size
        isDirectory: f.isDirectory(),
      )).toList();

      final filteredResult = <FileEntity>[];
      for (final entity in result) {
        if (!filterVideos || entity.isDirectory || _isVideoFile(entity.name)) {
          filteredResult.add(entity);
        }

        if (recursive && entity.isDirectory) {
          try {
            final subPath = path.isEmpty ? entity.name : '$path/${entity.name}';
            final subFiles = await listFiles(
              subPath,
              recursive: true,
              filterVideos: filterVideos,
            );
            filteredResult.addAll(subFiles);
          } catch (_) {}
        }
      }

      filteredResult.sort((a, b) {
        if (a.isDirectory != b.isDirectory) {
          return a.isDirectory ? -1 : 1;
        }
        return a.name.compareTo(b.name);
      });

      return filteredResult;
    } catch (e) {
      print("SMB List Error: $e");
      return [];
    }
  }

  Future<FileEntity?> getFileInfo(String path) async {
    if (_connection == null) return null;
    try {
      final fullPath = _connectedShare != null 
          ? "$_connectedShare/$path" 
          : path;
      SmbFile file = await _connection!.file(fullPath);

      final fileName = _getFileName(path);
      final parentPath = _getParentPath(path);
      final entityPath = parentPath.isEmpty ? fileName : '$parentPath/$fileName';

      return FileEntity(
        name: fileName,
        path: entityPath,
        size: 0,
        isDirectory: file.isDirectory(),
      );
    } catch (e) {
      print("SMB Get File Info Error: $e");
      return null;
    }
  }

  // 关键：对接代理服务器的流读取
  Future<Stream<Uint8List>> openRead(String path) async {
    if (_connection == null) throw Exception("SMB Not Connected");
    final fullPath = _connectedShare != null 
        ? "$_connectedShare/$path" 
        : path;
    SmbFile file = await _connection!.file(fullPath);
    return await _connection!.openRead(file);
  }

  Future<void> disconnect() async {
    await _connection?.close();
    _connection = null;
    _currentHost = null;
    _connectedShare = null;
    _connectedDomain = null;
    _connectedUsername = null;
    _connectedPassword = null;
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
