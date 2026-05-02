import 'dart:async';
import 'dart:io';
import 'smb_service.dart';

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

    RandomAccessFile? raf;
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

      // 获取随机访问文件
      raf = await SmbService().openRandomAccessFile(filePath);
      final fileSize = await raf.length();

      // 设置基本响应头
      response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
      response.headers.set(HttpHeaders.contentTypeHeader, _getContentType(filePath));

      // 处理 Range 请求 (HTTP 206)
      final rangeHeader = request.headers.value('range');
      if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
        try {
          final range = rangeHeader.substring(6);
          final parts = range.split('-');
          
          int start = 0;
          if (parts[0].isNotEmpty) {
            start = int.tryParse(parts[0]) ?? 0;
          }
          
          int end = fileSize - 1;
          if (parts.length > 1 && parts[1].isNotEmpty) {
            end = int.tryParse(parts[1]) ?? fileSize - 1;
          }

          // 边界检查
          if (start < 0) start = 0;
          if (end >= fileSize) end = fileSize - 1;
          if (start > end) {
            response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
            response.headers.set(HttpHeaders.contentRangeHeader, 'bytes */$fileSize');
            try {
              await response.close();
            } catch (_) {}
            return;
          }

          // 跳转位置
          await raf.setPosition(start);
          
          // 设置 206 响应
          response.statusCode = HttpStatus.partialContent;
          final contentLength = end - start + 1;
          response.headers.set(HttpHeaders.contentLengthHeader, contentLength);
          response.headers.set(HttpHeaders.contentRangeHeader, 'bytes $start-$end/$fileSize');
          
          // 发送数据
          await _pipeRange(raf, response, start, end);
          responseSent = true;

        } catch (e) {
          print('Range Error: $e');
          // 回退到完整文件传输
          await _pipeFull(raf, response, fileSize);
          responseSent = true;
        }
      } else {
        // 无 Range 请求，发送完整文件
        response.statusCode = HttpStatus.ok;
        response.headers.set(HttpHeaders.contentLengthHeader, fileSize);
        await _pipeFull(raf, response, fileSize);
        responseSent = true;
      }

    } catch (e) {
      print('Proxy Error: $e');
      if (!responseSent) {
        try {
          response
            ..statusCode = HttpStatus.internalServerError
            ..close();
        } catch (_) {}
      }
    } finally {
      try {
        await raf?.close();
      } catch (_) {}
    }
  }

  Future<void> _pipeFull(RandomAccessFile raf, HttpResponse response, int fileSize) async {
    await raf.setPosition(0);
    await _pipeRange(raf, response, 0, fileSize - 1);
  }

  Future<void> _pipeRange(RandomAccessFile raf, HttpResponse response, int start, int end) async {
    const bufferSize = 8192;
    int bytesRemaining = end - start + 1;
    
    while (bytesRemaining > 0) {
      final buffer = List<int>.filled(
        bytesRemaining < bufferSize ? bytesRemaining : bufferSize,
        0,
      );
      final bytesRead = await raf.readInto(buffer);
      
      if (bytesRead <= 0) break;
      
      final data = bytesRead < buffer.length ? buffer.sublist(0, bytesRead) : buffer;
      response.add(data);
      bytesRemaining -= bytesRead;
      
      if (bytesRead < bufferSize) break;
    }
    
    await response.flush();
    await response.close();
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
