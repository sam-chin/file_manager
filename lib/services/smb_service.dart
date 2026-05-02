import 'dart:async';
import 'dart:io';
import 'package:smb_connect/smb_connect.dart';

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
  static final SmbService _instance = SmbService._internal();
  factory SmbService() => _instance;
  SmbService._internal();

  dynamic _connection;
  bool _isConnected = false;
  String? _connectedHost;
  String? _connectedShare;

  bool get isConnected => _isConnected;
  String? get connectedHost => _connectedHost;
  String? get connectedShare => _connectedShare;

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

      final config = Configuration();
      final auth = NtlmPasswordAuthenticator(
        domain: domain ?? 'WORKGROUP',
        username: username ?? 'guest',
        password: password ?? '',
      );

      _connection = SmbClient(
        host: host,
        share: share,
        domain: domain ?? 'WORKGROUP',
        username: username ?? 'guest',
        password: password ?? '',
      );

      await (_connection as SmbClient).connect().timeout(timeout);

      _isConnected = true;
      _connectedHost = host;
      _connectedShare = share;

      return true;
    } on TimeoutException {
      _isConnected = false;
      _connection = null;
      return false;
    } on SocketException {
      _isConnected = false;
      _connection = null;
      return false;
    } catch (e) {
      _isConnected = false;
      _connection = null;
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      _isConnected = false;
      _connectedHost = null;
      _connectedShare = null;

      if (_connection != null) {
        await (_connection as SmbClient).disconnect();
        _connection = null;
      }
    } catch (e) {
      _connection = null;
    }
  }

  Future<List<FileEntity>> listFiles(
    String path, {
    bool recursive = false,
    bool filterVideos = false,
  }) async {
    if (!_isConnected || _connection == null) {
      throw StateError('Not connected to SMB server');
    }

    final List<FileEntity> result = [];

    try {
      final items = await (_connection as SmbClient).listDirectory(path).timeout(
        const Duration(seconds: 30),
      );

      for (final item in items) {
        final filePath = path.isEmpty ? item.name : '$path/${item.name}';

        final entity = FileEntity(
          name: item.name,
          path: filePath,
          size: item.isDirectory ? 0 : item.fileSize,
          isDirectory: item.isDirectory,
        );

        if (!filterVideos || _isVideoFile(entity.name) || entity.isDirectory) {
          result.add(entity);
        }

        if (recursive && entity.isDirectory) {
          try {
            final subItems = await listFiles(
              filePath,
              recursive: true,
              filterVideos: filterVideos,
            );
            result.addAll(subItems);
          } catch (e) {}
        }
      }

      result.sort((a, b) {
        if (a.isDirectory != b.isDirectory) {
          return a.isDirectory ? -1 : 1;
        }
        return a.name.compareTo(b.name);
      });

      return result;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<FileEntity?> getFileInfo(String path) async {
    if (!_isConnected || _connection == null) {
      throw StateError('Not connected to SMB server');
    }

    try {
      final parentPath = _getParentPath(path);
      final fileName = _getFileName(path);

      final items = await (_connection as SmbClient).listDirectory(parentPath).timeout(
        const Duration(seconds: 30),
      );

      final targetItem = items.where((item) => item.name == fileName).firstOrNull;
      if (targetItem == null) return null;

      return FileEntity(
        name: targetItem.name,
        path: path,
        size: targetItem.isDirectory ? 0 : targetItem.fileSize,
        isDirectory: targetItem.isDirectory,
      );
    } catch (e) {
      return null;
    }
  }

  Future<Stream<List<int>>> openInputStream(String path) async {
    if (!_isConnected || _connection == null) {
      throw StateError('Not connected to SMB server');
    }

    try {
      return (_connection as SmbClient).openFileRead(path);
    } catch (e) {
      rethrow;
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
