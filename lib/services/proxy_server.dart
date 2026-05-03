import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:smb_connect/smb_connect.dart';

class ProxyServer {
  static final ProxyServer _instance = ProxyServer._internal();
  factory ProxyServer() => _instance;
  ProxyServer._internal();

  HttpServer? _server;
  SmbConnect? _currentConnection;

  // 启动代理
  Future<String> start(SmbConnect connection) async {
    _currentConnection = connection;
    if (_server != null) return "http://localhost:${_server!.port}";

    final router = Router();

    // 路由处理：http://localhost:port/stream?path=/home/movie.mp4
    router.get('/stream', (Request request) async {
      final path = request.url.queryParameters['path'];
      if (path == null || _currentConnection == null) {
        return Response.notFound('Missing path or connection');
      }

      try {
        final smbFile = await _currentConnection!.file(path);
        final stream = await _currentConnection!.openRead(smbFile);
        
        // 将 SMB 流包装成 HTTP 响应
        return Response.ok(
          stream,
          headers: {
            'Content-Type': 'video/mp4', // 简单处理，实际可根据后缀判断
            'Content-Length': smbFile.fileSize.toString(),
            'Accept-Ranges': 'none', // 0.0.9 暂不支持 Seek，建议设为 none
          },
        );
      } catch (e) {
        return Response.internalServerError(body: e.toString());
      }
    });

    _server = await io.serve(router, InternetAddress.loopbackIPv4, 0);
    print('代理服务器已启动: http://${_server!.address.host}:${_server!.port}');
    return "http://localhost:${_server!.port}";
  }

  void stop() {
    _server?.close();
    _server = null;
  }
}