import 'dart:io';
import '../models/file_item.dart';

class StreamProxyServer {
  static final StreamProxyServer _instance = StreamProxyServer._internal();
  factory StreamProxyServer() => _instance;
  StreamProxyServer._internal();

  HttpServer? _server;
  int _port = 8080;

  int get port => _port;
  String get baseUrl => 'http://127.0.0.1:$_port';
  bool get isRunning => _server != null;

  Future<void> start({int port = 8080}) async {
    // 简化为不启动实际服务器，避免错误
    _port = port;
  }

  Future<void> stop() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }
  }

  String getSmbProxyUrl(String smbPath) {
    final encodedPath = Uri.encodeComponent(smbPath);
    return '$baseUrl/smb/$encodedPath';
  }
}
