import 'dart:io';
import 'dart:typed_data';
import 'package:smb_connect/smb_connect.dart';

// 统一的文件模型，解决 UI 层的 'SmbFileInfo' 类型缺失错误
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
  SmbConnect? _connection;
  String? _connectedHost;
  String? _connectedShare;
  String? _connectedDomain;
  String? _connectedUsername;
  String? _connectedPassword;

  bool get isConnected => _connection != null;
  String? get connectedHost => _connectedHost;
  String? get connectedShare => _connectedShare;

  // 连接方法
  Future<bool> connect({
    required String host,
    required String share,
    String? domain,
    String? username,
    String? password,
  }) async {
    try {
      await disconnect();

      _connection = await SmbConnect.connectAuth(
        host: host,
        domain: domain ?? "",
        username: username ?? 'guest',
        password: password ?? '',
      );

      _connectedHost = host;
      _connectedShare = share;
      _connectedDomain = domain;
      _connectedUsername = username;
      _connectedPassword = password;

      return true;
    } catch (e) {
      print("SMB Connect Error: $e");
      return false;
    }
  }

  // 获取文件列表 (适配 README 的 listFiles)
  Future<List<FileEntity>> listFiles(
    String path, {
    bool recursive = false,
    bool filterVideos = false,
  }) async {
    if (_connection == null) return [];
    try {
      // 构建完整路径
      final fullPath = _connectedShare != null 
          ? "$_connectedShare/$path" 
          : path;
      
      // 0.0.9 先通过路径获取 SmbFile 对象
      SmbFile folder = await _connection!.file(fullPath);
      List<SmbFile> files = await _connection!.listFiles(folder);

      final result = files.map((f) => FileEntity(
        name: f.name,
        path: path.isEmpty ? f.name : '$path/${f.name}',
        size: f.size, // 0.0.9 文档显示 SmbFile 有 size 属性
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
        size: file.size,
        isDirectory: file.isDirectory(),
      );
    } catch (e) {
      print("SMB Get File Info Error: $e");
      return null;
    }
  }

  // 为代理服务器提供随机访问流 (RandomAccessFile)
  // 这是支持视频进度拖动的关键
  Future<RandomAccessFile> openRandomAccessFile(String path) async {
    if (_connection == null) throw Exception("SMB Not Connected");
    final fullPath = _connectedShare != null 
        ? "$_connectedShare/$path" 
        : path;
    SmbFile file = await _connection!.file(fullPath);
    return await _connection!.open(file); // 对应 README 中的 Random access file
  }

  Future<void> disconnect() async {
    await _connection?.close();
    _connection = null;
    _connectedHost = null;
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
