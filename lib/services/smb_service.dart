import 'dart:io';
import 'dart:typed_data';
import 'package:smb_connect/smb_connect.dart';
import '../models/file_item.dart';

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
    Duration timeout = const Duration(seconds: 30),
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
    } on TimeoutException {
      print("SMB Connect Timeout: Connecting took too long");
      return false;
    } catch (e) {
      print("SMB Connect Error: $e");
      return false;
    }
  }

  // 获取文件列表 (适配 README 的 listFiles)
  Future<List<FileItem>> listFiles(
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

      final result = files.map((f) => FileItem(
        name: f.name,
        path: path.isEmpty ? f.name : '$path/${f.name}',
        isRemote: true,
        type: f.isDirectory() ? FileType.folder : _getFileTypeFromName(f.name),
        size: f.size,
        modifiedTime: DateTime.now(), // SmbFile 0.0.9 没有提供时间戳，使用当前时间
      )).toList();

      final filteredResult = <FileItem>[];
      for (final entity in result) {
        if (!filterVideos || entity.isDirectory || entity.type == FileType.video) {
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

  Future<FileItem?> getFileInfo(String path) async {
    if (_connection == null) return null;
    try {
      final fullPath = _connectedShare != null 
          ? "$_connectedShare/$path" 
          : path;
      
      SmbFile file = await _connection!.file(fullPath);

      final fileName = _getFileName(path);
      final parentPath = _getParentPath(path);
      final entityPath = parentPath.isEmpty ? fileName : '$parentPath/$fileName';

      return FileItem(
        name: fileName,
        path: entityPath,
        isRemote: true,
        type: file.isDirectory() ? FileType.folder : _getFileTypeFromName(fileName),
        size: file.size,
        modifiedTime: DateTime.now(),
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

  Future<Stream<Uint8List>> openRead(String path) async {
    if (_connection == null) throw Exception("SMB Not Connected");
    final fullPath = _connectedShare != null 
        ? "$_connectedShare/$path" 
        : path;
    SmbFile file = await _connection!.file(fullPath);
    return await _connection!.openRead(file);
  }

  Future<void> disconnect() async {
    try {
      await _connection?.close();
    } catch (e) {
      print("SMB Disconnect Error: $e");
    }
    _connection = null;
    _connectedHost = null;
    _connectedShare = null;
    _connectedDomain = null;
    _connectedUsername = null;
    _connectedPassword = null;
  }

  FileType _getFileTypeFromName(String fileName) {
    final lower = fileName.toLowerCase();
    const videoExtensions = ['mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm', 'iso', 'm4v'];
    const audioExtensions = ['mp3', 'flac', 'wav', 'm4a', 'aac'];
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'];
    const documentExtensions = ['pdf', 'doc', 'docx', 'txt', 'epub'];

    for (final ext in videoExtensions) {
      if (lower.endsWith('.$ext')) return FileType.video;
    }
    for (final ext in audioExtensions) {
      if (lower.endsWith('.$ext')) return FileType.audio;
    }
    for (final ext in imageExtensions) {
      if (lower.endsWith('.$ext')) return FileType.image;
    }
    for (final ext in documentExtensions) {
      if (lower.endsWith('.$ext')) return FileType.document;
    }
    return FileType.other;
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
