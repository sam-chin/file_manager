import 'dart:async';
import 'dart:io';
import 'package:ftpconnect/ftpconnect.dart';
import '../entities/base_file_entity.dart';

class FtpService {
  static final FtpService _instance = FtpService._internal();
  factory FtpService() => _instance;
  FtpService._internal();

  FTPConnect? _client;
  bool _isConnected = false;
  String? _connectedHost;
  int? _connectedPort;

  bool get isConnected => _isConnected;
  String? get connectedHost => _connectedHost;
  int? get connectedPort => _connectedPort;

  Future<bool> connect({
    required String host,
    int port = 21,
    required String username,
    required String password,
    bool passiveMode = true,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      await disconnect();

      _client = FTPConnect(
        host,
        port: port,
        user: username,
        pass: password,
        passiveMode: passiveMode,
        showLog: false,
      );

      await _client!.connect().timeout(timeout);

      _isConnected = true;
      _connectedHost = host;
      _connectedPort = port;

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
      _connectedPort = null;

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
      throw StateError('Not connected to FTP server');
    }

    final List<BaseFileEntity> result = [];

    try {
      final items = await _client!.listDirectoryContent(path).timeout(
        const Duration(seconds: 30),
      );

      for (final item in items) {
        if (item.name == '.' || item.name == '..') continue;

        final fileType = item.type == FTPEntryType.DIR
            ? FileType.directory
            : FileType.file;
        final filePath = path.isEmpty ? item.name : '$path/${item.name}';

        final entity = BaseFileEntity(
          name: item.name,
          path: filePath,
          type: fileType,
          size: item.size ?? 0,
          modifiedTime: item.modifyDate,
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
      throw StateError('Not connected to FTP server');
    }

    try {
      final parentPath = _getParentPath(path);
      final fileName = _getFileName(path);

      final items = await _client!.listDirectoryContent(parentPath).timeout(
        const Duration(seconds: 30),
      );

      final targetItem = items.where((item) => item.name == fileName).firstOrNull;
      if (targetItem == null) return null;

      return BaseFileEntity(
        name: targetItem.name,
        path: path,
        type: targetItem.type == FTPEntryType.DIR
            ? FileType.directory
            : FileType.file,
        size: targetItem.size ?? 0,
        modifiedTime: targetItem.modifyDate,
      );
    } catch (e) {
      return null;
    }
  }

  Stream<List<int>>? openFileStream(String path, {int offset = 0}) {
    if (!_isConnected || _client == null) {
      throw StateError('Not connected to FTP server');
    }

    final controller = StreamController<List<int>>();

    () async {
      try {
        final tempFile = await _client!.downloadFileWithRetry(path);

        if (tempFile == null) {
          controller.addError(Exception('File not found'));
          await controller.close();
          return;
        }

        final fileStream = tempFile.openRead(offset);

        await for (final chunk in fileStream) {
          if (controller.isClosed) break;
          controller.add(chunk);
        }

        if (!controller.isClosed) {
          await controller.close();
        }

        await tempFile.delete();
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
