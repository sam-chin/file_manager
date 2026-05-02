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
      _server!.listen(_handleRequest, onError: (error) {
        print("StreamProxyServer Error: $error");
      });
      print("StreamProxyServer started on port $_port");
    } catch (e) {
      print("StreamProxyServer Start Error: $e");
      _server = null;
      rethrow;
    }
  }

  Future<void> stop() async {
    if (_server == null) return;

    try {
      await _server!.close(force: true);
      print("StreamProxyServer stopped");
    } catch (e) {
      print("StreamProxyServer Stop Error: $e");
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
        request.response
          ..statusCode = HttpStatus.notFound
          ..close();
      }
    } catch (e) {
      print("StreamProxyServer Request Error: $e");
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

    try {
      if (!SmbService().isConnected) {
        response
          ..statusCode = HttpStatus.serviceUnavailable
          ..write("Not connected to SMB server")
          ..close();
        return;
      }

      final fileInfo = await SmbService().getFileInfo(filePath);
      if (fileInfo == null) {
        response
          ..statusCode = HttpStatus.notFound
          ..write("File not found")
          ..close();
        return;
      }

      if (fileInfo.isDirectory) {
        response
          ..statusCode = HttpStatus.forbidden
          ..write("Cannot serve directories")
          ..close();
        return;
      }

      final fileSize = fileInfo.size;
      int start = 0;
      int end = fileSize - 1;
      bool isPartial = false;

      final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
      if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
        isPartial = true;
        final range = _parseRange(rangeHeader, fileSize);
        start = range.$1;
        end = range.$2;
      }

      final contentLength = end - start + 1;

      response.statusCode = isPartial ? HttpStatus.partialContent : HttpStatus.ok;
      response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
      response.headers.set(HttpHeaders.contentTypeHeader, _getContentType(filePath));
      response.headers.set(HttpHeaders.contentLengthHeader, contentLength);

      if (isPartial) {
        response.headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes $start-$end/$fileSize',
        );
      }

      if (start > 0) {
        response.write("Range requests not fully supported in this version");
      }

      await response.close();
    } on RangeNotSatisfiableException {
        response
          ..statusCode = HttpStatus.requestedRangeNotSatisfiable
          ..headers.set(HttpHeaders.contentRangeHeader, 'bytes */${fileInfo.size}')
          ..close();
    } catch (e) {
      try {
        response
        ..statusCode = HttpStatus.internalServerError
        ..close();
      } catch (_) {}
    }
  }

  (int, int) _parseRange(String rangeHeader, int fileSize) {
    final rangeStr = rangeHeader.substring(6);
    final parts = rangeStr.split('-');

    int start = 0;
    int end = fileSize - 1;

    if (parts[0].isNotEmpty) {
      start = int.tryParse(parts[0]) ?? 0;
    }

    if (parts.length > 1 && parts[1].isNotEmpty) {
      end = int.tryParse(parts[1]) ?? fileSize - 1;
    }

    if (start < 0) start = 0;
    if (end >= fileSize) end = fileSize - 1;
    if (start > end) {
      throw RangeNotSatisfiableException();
    }

    return (start, end);
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

  String getSmbProxyUrl(String smbPath) {
    final encodedPath = Uri.encodeComponent(smbPath);
    return '$baseUrl/smb/$encodedPath';
  }
}

class RangeNotSatisfiableException implements Exception {
  RangeNotSatisfiableException();
}
