import 'dart:async';
import 'package:smb_connect/smb_connect.dart';

class SmbService {
  static final SmbService _instance = SmbService._internal();
  factory SmbService() => _instance;
  SmbService._internal();

  SmbContext? _context;
  static const List<String> videoExtensions = [
    '.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.iso'
  ];

  Future<bool> connect({
    required String host,
    required String share,
    String? domain,
    String? username,
    String? password,
  }) async {
    try {
      _context = SmbContext(
        host: host,
        share: share,
        domain: domain ?? 'WORKGROUP',
        username: username ?? 'guest',
        password: password ?? '',
      );
      await _context!.connect();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> disconnect() async {
    if (_context != null) {
      await _context!.disconnect();
      _context = null;
    }
  }

  Future<List<SmbFileInfo>> listFiles(String path, {bool recursive = false}) async {
    if (_context == null) throw Exception('Not connected');
    final List<SmbFileInfo> files = [];
    try {
      final items = await _context!.listDirectory(path);
      for (final item in items) {
        if (item.isDirectory) {
          if (recursive) {
            final subFiles = await listFiles('$path/${item.name}', recursive: true);
            files.addAll(subFiles);
          }
        } else {
          if (_isVideoFile(item.name)) {
            files.add(item);
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

  Future<SmbFileInfo?> getFileInfo(String path) async {
    if (_context == null) throw Exception('Not connected');
    return _context!.getFileInfo(path);
  }

  Future<Stream<List<int>>> openFile(String path) async {
    if (_context == null) throw Exception('Not connected');
    return _context!.openFile(path);
  }

  bool get isConnected => _context != null;
}

class SmbFileInfo {
  final String name;
  final int size;
  final bool isDirectory;
  final DateTime? modifiedTime;

  SmbFileInfo({
    required this.name,
    required this.size,
    required this.isDirectory,
    this.modifiedTime,
  });
}
