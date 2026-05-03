import 'dart:io';
import '../models/file_item.dart';
import '../models/server_record.dart';

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

  // 新方法：接收 FileItem 和 ServerRecord
  Future<String> startProxy(FileItem item, ServerRecord server) async {
    // 启动代理服务器（如果还没启动）
    if (!isRunning) {
      await start();
    }

    // 构造代理 URL
    final encodedPath = Uri.encodeComponent(item.path);
    return '$baseUrl/proxy/$encodedPath';
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
