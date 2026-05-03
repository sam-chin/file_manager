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

  Future<String> start(SmbConnect connection) async {
    _currentConnection = connection;
    if (_server != null) return "http://localhost:${_server!.port}";

    final router = Router();

    router.get('/stream', (Request request) async {
      final path = request.url.queryParameters['path'];
      if (path == null || _currentConnection == null) {
        return Response.notFound('Missing path or connection');
      }

      try {
        final smbFile = await _currentConnection!.file(path);
        final stream = await _currentConnection!.openRead(smbFile);
        
        return Response.ok(
          stream,
          headers: {
            'Content-Type': 'video/mp4',
            'Content-Length': smbFile.size.toString(),
            'Accept-Ranges': 'none',
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
