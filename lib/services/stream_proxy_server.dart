import 'dart:async';
import 'dart:io';
import 'smb_service.dart';
import 'ftp_service.dart';

class StreamProxyServer {
  static final StreamProxyServer _instance = StreamProxyServer._internal();
  factory StreamProxyServer() => _instance;
  StreamProxyServer._internal();

  HttpServer? _server;
  int _port = 8080;
  final Map<String, StreamController<List<int>>> _activeStreams = {};

  int get port => _port;
  String get baseUrl => 'http://localhost:$_port';

  Future<void> start({int port = 8080}) async {
    _port = port;
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    _server!.listen(_handleRequest);
  }

  Future<void> stop() async {
    for (final controller in _activeStreams.values) {
      await controller.close();
    }
    _activeStreams.clear();
    await _server?.close();
    _server = null;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      final path = request.uri.path;
      if (path.startsWith('/smb/')) {
        await _handleSmbRequest(request);
      } else if (path.startsWith('/ftp/')) {
        await _handleFtpRequest(request);
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..close();
      }
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('Error: $e')
        ..close();
    }
  }

  Future<void> _handleSmbRequest(HttpRequest request) async {
    final smbPath = request.uri.path.substring('/smb/'.length);
    final range = request.headers.value('range');
    
    request.response.headers
      ..contentType = ContentType.parse('video/mp4')
      ..add('Accept-Ranges', 'bytes');

    final fileInfo = await SmbService().getFileInfo(smbPath);
    if (fileInfo == null) {
      request.response
        ..statusCode = HttpStatus.notFound
        ..close();
      return;
    }

    int start = 0;
    int end = fileInfo.size - 1;

    if (range != null && range.startsWith('bytes=')) {
      final parts = range.substring(6).split('-');
      start = int.tryParse(parts[0]) ?? 0;
      if (parts.length > 1 && parts[1].isNotEmpty) {
        end = int.tryParse(parts[1]) ?? end;
      }
    }

    final contentLength = end - start + 1;
    request.response
      ..statusCode = range != null ? HttpStatus.partialContent : HttpStatus.ok
      ..headers.add('Content-Range', 'bytes $start-$end/${fileInfo.size}')
      ..contentLength = contentLength;

    final stream = await SmbService().openFile(smbPath);
    await _streamResponse(request.response, stream, start, end);
  }

  Future<void> _handleFtpRequest(HttpRequest request) async {
    final ftpPath = request.uri.path.substring('/ftp/'.length);
    request.response.headers
      ..contentType = ContentType.parse('video/mp4')
      ..add('Accept-Ranges', 'bytes');

    request.response
      ..statusCode = HttpStatus.ok
      ..close();
  }

  Future<void> _streamResponse(
    HttpResponse response,
    Stream<List<int>> stream,
    int start,
    int end,
  ) async {
    int bytesSkipped = 0;
    int bytesSent = 0;
    final totalToSend = end - start + 1;

    await for (final chunk in stream) {
      if (bytesSkipped < start) {
        final remainingToSkip = start - bytesSkipped;
        if (chunk.length <= remainingToSkip) {
          bytesSkipped += chunk.length;
          continue;
        } else {
          final newChunk = chunk.sublist(remainingToSkip);
          bytesSkipped = start;
          bytesSent += newChunk.length;
          response.add(newChunk);
          if (bytesSent >= totalToSend) break;
        }
      } else {
        final spaceLeft = totalToSend - bytesSent;
        if (chunk.length <= spaceLeft) {
          bytesSent += chunk.length;
          response.add(chunk);
        } else {
          response.add(chunk.sublist(0, spaceLeft));
          bytesSent = totalToSend;
        }
        if (bytesSent >= totalToSend) break;
      }
    }
    await response.close();
  }

  String getSmbProxyUrl(String smbPath) {
    return '$baseUrl/smb/$smbPath';
  }

  String getFtpProxyUrl(String ftpPath) {
    return '$baseUrl/ftp/$ftpPath';
  }
}
