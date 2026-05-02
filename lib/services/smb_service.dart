import 'dart:async';
import 'dart:io';
import 'package:smb_connect/smb_connect.dart';
import '../entities/base_file_entity.dart';

class SmbService {
  static final SmbService _instance = SmbService._internal();
  factory SmbService() => _instance;
  SmbService._internal();

  SmbClient? _client;
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

      _client = SmbClient(
        host: host,
        share: share,
        domain: domain ?? 'WORKGROUP',
        username: username ?? 'guest',
        password: password ?? '',
      );

      await _client!.connect().timeout(timeout);

      _isConnected = true;
      _connectedHost = host;
      _connectedShare = share;

      return true;
    } on TimeoutException {
      _isConnected = false;
      _client = null;
      return false;
    } on SocketException {
      _isConnected = false;
      _client = null;
      return false;
    } catch (e) {
      _isConnected = false;
      _client = null;
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      _isConnected = false;
      _connectedHost = null;
      _connectedShare = null;

      if (_client != null) {
        await _client!.disconnect();
        _client = null;
      }
    } catch (e) {
      _client = null;
    }
  }

  Future<List<BaseFileEntity>> listFiles(
    String path, {
    bool recursive = false,
    bool filterVideos = false,
  }) async {
    if (!_isConnected || _client == null) {
      throw StateError('Not connected to SMB server');
    }

    final List<BaseFileEntity> result = [];

    try {
      final items = await _client!.listDirectory(path).timeout(
        const Duration(seconds: 30),
      );

      for (final item in items) {
        final fileType = item.isDirectory ? FileType.directory : FileType.file;
        final filePath = path.isEmpty ? item.name : '$path/${item.name}';

        final entity = BaseFileEntity(
          name: item.name,
          path: filePath,
          type: fileType,
          size: item.isDirectory ? 0 : item.fileSize,
          modifiedTime: item.lastWriteTime,
        );

        if (!filterVideos || entity.isVideo || entity.isDirectory) {
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

  Future<BaseFileEntity?> getFileInfo(String path) async {
    if (!_isConnected || _client == null) {
      throw StateError('Not connected to SMB server');
    }

    try {
      final parentPath = _getParentPath(path);
      final fileName = _getFileName(path);

      final items = await _client!.listDirectory(parentPath).timeout(
        const Duration(seconds: 30),
      );

      final targetItem = items.where((item) => item.name == fileName).firstOrNull;
      if (targetItem == null) return null;

      return BaseFileEntity(
        name: targetItem.name,
        path: path,
        type: targetItem.isDirectory ? FileType.directory : FileType.file,
        size: targetItem.isDirectory ? 0 : targetItem.fileSize,
        modifiedTime: targetItem.lastWriteTime,
      );
    } catch (e) {
      return null;
    }
  }

  Stream<List<int>> openFileStream(String path) {
    if (!_isConnected || _client == null) {
      throw StateError('Not connected to SMB server');
    }

    final controller = StreamController<List<int>>();

    () async {
      try {
        final fileStream = _client!.openFileRead(path);

        await for (final chunk in fileStream) {
          if (controller.isClosed) break;
          controller.add(chunk);
        }

        if (!controller.isClosed) {
          await controller.close();
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
          await controller.close();
        }
      }
    }();

    return controller.stream;
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
