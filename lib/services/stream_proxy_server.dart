import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'smb_service.dart';

class StreamProxyServer {
  static final StreamProxyServer _instance = StreamProxyServer._internal();
  factory StreamProxyServer() => _instance;
  StreamProxyServer._internal();

  HttpServer? _server;
  int _port = 8080;
  final Map<String, StreamSubscription<Uint8List>> _activeSubscriptions = {};

  int get port => _port;
  String get baseUrl => 'http://127.0.0.1:$_port';
  bool get isRunning => _server != null;

  Future<void> start({int port = 8080}) async {
    if (_server != null) return;

    _port = port;
    try {
      _server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        _port,
        shared: true,
      );
      _server!.listen(_handleRequest, onError: _handleServerError);
    } catch (e) {
      _server = null;
      rethrow;
    }
  }

  Future<void> stop() async {
    if (_server == null) return;

    try {
      for (final sub in _activeSubscriptions.values) {
        await sub.cancel();
      }
      _activeSubscriptions.clear();
      await _server!.close(force: true);
    } finally {
      _server = null;
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      final path = request.uri.path;

      if (path.startsWith('/smb/')) {
        await _handleSmbRequest(request);
      } else {
        try {
          request.response
            ..statusCode = HttpStatus.notFound
            ..close();
        } catch (_) {}
      }
    } catch (e) {
      try {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..close();
      } catch (_) {}
    }
  }

  Future<void> _handleSmbRequest(HttpRequest request) async {
    final response = request.response;
    final encodedPath = request.uri.path.substring('/smb/'.length);
    final filePath = Uri.decodeComponent(encodedPath);
    bool responseSent = false;

    try {
      if (!SmbService().isConnected) {
        try {
          response
            ..statusCode = HttpStatus.serviceUnavailable
            ..close();
        } catch (_) {}
        return;
      }

      final fileInfo = await SmbService().getFileInfo(filePath);
      if (fileInfo == null) {
        try {
          response
            ..statusCode = HttpStatus.notFound
            ..close();
        } catch (_) {}
        return;
      }

      if (fileInfo.isDirectory) {
        try {
          response
            ..statusCode = HttpStatus.forbidden
            ..close();
        } catch (_) {}
        return;
      }

      // 对于新 API，我们只发送完整文件流，暂不处理 Range
      response.statusCode = HttpStatus.ok;
      response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
      response.headers.set(HttpHeaders.contentTypeHeader, _getContentType(filePath));

      // 使用新的 openRead 方法
      final stream = await SmbService().openRead(filePath);
      await stream.pipe(response);
      responseSent = true;

    } catch (e) {
      if (!responseSent) {
        try {
          response
            ..statusCode = HttpStatus.internalServerError
            ..close();
        } catch (_) {}
      }
    }
  }

  String _getContentType(String filePath) {
    final lower = filePath.toLowerCase();

    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mkv')) return 'video/x-matroska';
    if (lower.endsWith('.avi')) return 'video/x-msvideo';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.webm')) return 'video/webm';
    if (lower.endsWith('.flv')) return 'video/x-flv';
    if (lower.endsWith('.wmv')) return 'video/x-ms-wmv';
    if (lower.endsWith('.m4v')) return 'video/x-m4v';

    return 'application/octet-stream';
  }

  void _handleServerError(error) {}

  String getSmbProxyUrl(String smbPath) {
    final encodedPath = Uri.encodeComponent(smbPath);
    return '$baseUrl/smb/$encodedPath';
  }
}
