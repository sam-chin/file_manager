import 'dart:async';
import 'dart:io';
import 'package:smb_connect/smb_connect.dart';
import '../entities/base_file_entity.dart';

class SmbService {
  static final SmbService _instance = SmbService._internal();
  factory SmbService() => _instance;
  SmbService._internal();

  SmbContext? _context;
  bool _isConnected = false;
  String? _connectedHost;
  String? _connectedShare;
  String? _connectedDomain;
  String? _connectedUsername;
  String? _connectedPassword;

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

      final authenticator = NtlmPasswordAuthenticator(
        domain: domain ?? 'WORKGROUP',
        username: username ?? 'guest',
        password: password ?? '',
      );

      _context = SmbContext(
        host: host,
        share: share,
        authenticator: authenticator,
      );

      await _context!.connect().timeout(timeout);

      _isConnected = true;
      _connectedHost = host;
      _connectedShare = share;
      _connectedDomain = domain;
      _connectedUsername = username;
      _connectedPassword = password;

      return true;
    } on TimeoutException {
      _isConnected = false;
      _context = null;
      return false;
    } on SocketException {
      _isConnected = false;
      _context = null;
      return false;
    } catch (e) {
      _isConnected = false;
      _context = null;
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      _isConnected = false;
      _connectedHost = null;
      _connectedShare = null;
      _connectedDomain = null;
      _connectedUsername = null;
      _connectedPassword = null;

      if (_context != null) {
        await _context!.disconnect();
        _context = null;
      }
    } catch (e) {
      _context = null;
    }
  }

  Future<List<BaseFileEntity>> listFiles(
    String path, {
    bool recursive = false,
    bool filterVideos = false,
  }) async {
    if (!_isConnected || _context == null) {
      throw StateError('Not connected to SMB server');
    }

    final List<BaseFileEntity> result = [];

    try {
      final items = await _context!.listDirectory(path).timeout(
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
    if (!_isConnected || _context == null) {
      throw StateError('Not connected to SMB server');
    }

    try {
      final parentPath = _getParentPath(path);
      final fileName = _getFileName(path);

      final items = await _context!.listDirectory(parentPath).timeout(
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
    if (!_isConnected || _context == null) {
      throw StateError('Not connected to SMB server');
    }

    final controller = StreamController<List<int>>();

    () async {
      try {
        final fileStream = _context!.openFileRead(path);

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

  Future<SmbFileInfo?> openFileInfo(String path) async {
    if (!_isConnected || _context == null) {
      throw StateError('Not connected to SMB server');
    }
    return _context!.getFileInfo(path);
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
