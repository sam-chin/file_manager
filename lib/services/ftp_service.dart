import 'dart:async';
import 'package:ftpconnect/ftpconnect.dart';

class FtpService {
  static final FtpService _instance = FtpService._internal();
  factory FtpService() => _instance;
  FtpService._internal();

  FTPConnect? _client;
  static const List<String> videoExtensions = [
    '.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.iso'
  ];

  Future<bool> connect({
    required String host,
    required int port,
    required String username,
    required String password,
    bool passiveMode = true,
  }) async {
    try {
      _client = FTPConnect(
        host,
        port: port,
        user: username,
        pass: password,
        passiveMode: passiveMode,
      );
      await _client!.connect();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> disconnect() async {
    if (_client != null) {
      await _client!.disconnect();
      _client = null;
    }
  }

  Future<List<FtpFileInfo>> listFiles(String path, {bool recursive = false}) async {
    if (_client == null) throw Exception('Not connected');
    final List<FtpFileInfo> files = [];
    try {
      final items = await _client!.listDirectoryContent(path);
      for (final item in items) {
        if (item.type == FTPEntryType.DIR) {
          if (recursive) {
            final subFiles = await listFiles('$path/${item.name}', recursive: true);
            files.addAll(subFiles);
          }
        } else {
          if (_isVideoFile(item.name)) {
            files.add(FtpFileInfo(
              name: item.name,
              size: item.size ?? 0,
              isDirectory: false,
              modifiedTime: item.modifyDate,
            ));
          }
        }
      }
    } catch (e) {
      rethrow;
    }
    return files;
  }

  bool _isVideoFile(String filename) {
    final lowerName = filename.toLowerCase();
    return videoExtensions.any((ext) => lowerName.endsWith(ext));
  }

  Future<Stream<List<int>>?> downloadFileStream(String path, {int offset = 0}) async {
    if (_client == null) throw Exception('Not connected');
    final completer = StreamController<List<int>>();
    try {
      final tempFile = await _client!.downloadFileWithRetry(path);
      if (tempFile != null) {
        final stream = tempFile.openRead(offset);
        await for (final chunk in stream) {
          completer.add(chunk);
        }
        await completer.close();
      }
    } catch (e) {
      completer.addError(e);
      await completer.close();
    }
    return completer.stream;
  }

  bool get isConnected => _client != null;
}

class FtpFileInfo {
  final String name;
  final int size;
  final bool isDirectory;
  final DateTime? modifiedTime;

  FtpFileInfo({
    required this.name,
    required this.size,
    required this.isDirectory,
    this.modifiedTime,
  });
}
