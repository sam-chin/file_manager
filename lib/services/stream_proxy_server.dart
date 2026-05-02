import 'dart:async';
import 'dart:io';
import 'smb_service.dart';

class StreamProxyServer {
  static final StreamProxyServer _instance = StreamProxyServer._internal();
  factory StreamProxyServer() => _instance;
  StreamProxyServer._internal();

  HttpServer? _server;
  int _port = 8080;
  final Map<String, StreamSubscription<List<int>>> _activeSubscriptions = {};

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
        request.response
          ..statusCode = HttpStatus.notFound
          ..close();
      }
    } catch (e) {
      if (!request.response.done) {
        try {
          request.response
            ..statusCode = HttpStatus.internalServerError
            ..close();
        } catch (_) {}
      }
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
          ..close();
        return;
      }

      final fileInfo = await SmbService().getFileInfo(filePath);
      if (fileInfo == null) {
        response
          ..statusCode = HttpStatus.notFound
          ..close();
        return;
      }

      if (fileInfo.isDirectory) {
        response
          ..statusCode = HttpStatus.forbidden
          ..close();
        return;
      }

      final range = request.headers.value(HttpHeaders.rangeHeader);
      final fileSize = fileInfo.size;

      int start = 0;
      int end = fileSize - 1;
      bool isPartial = false;

      if (range != null && range.startsWith('bytes=')) {
        final rangePart = range.substring(6);
        final parts = rangePart.split('-');

        if (parts.length >= 1) {
          final startStr = parts[0];
          if (startStr.isNotEmpty) {
            start = int.tryParse(startStr) ?? 0;
          }
        }

        if (parts.length >= 2) {
          final endStr = parts[1];
          if (endStr.isNotEmpty) {
            end = int.tryParse(endStr) ?? (fileSize - 1);
          }
        }

        if (start < 0) start = 0;
        if (end >= fileSize) end = fileSize - 1;
        if (start > end) {
          response
            ..statusCode = HttpStatus.requestedRangeNotSatisfiable
            ..headers.set(HttpHeaders.contentRangeHeader, 'bytes */$fileSize')
            ..close();
          return;
        }

        isPartial = true;
      }

      final contentLength = end - start + 1;

      response
        ..statusCode = isPartial ? HttpStatus.partialContent : HttpStatus.ok
        ..headers.set(HttpHeaders.acceptRangesHeader, 'bytes')
        ..headers.set(HttpHeaders.contentTypeHeader, _getContentType(filePath))
        ..headers.set(HttpHeaders.contentLengthHeader, contentLength);

      if (isPartial) {
        response.headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes $start-$end/$fileSize',
        );
      }

      await _streamFileContent(request, response, filePath, start, end);
    } catch (e) {
      if (!response.done) {
        try {
          response
            ..statusCode = HttpStatus.internalServerError
            ..close();
        } catch (_) {}
      }
    }
  }

  Future<void> _streamFileContent(
    HttpRequest request,
    HttpResponse response,
    String filePath,
    int start,
    int end,
  ) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    StreamSubscription<List<int>>? subscription;
    int bytesToSkip = start;
    int bytesToSend = end - start + 1;
    int bytesSent = 0;

    try {
      final fileStream = SmbService().openFileStream(filePath);

      final completer = Completer<void>();

      subscription = fileStream.listen(
        (chunk) async {
          if (response.done || completer.isCompleted) {
            return;
          }

          subscription?.pause();

          try {
            if (bytesToSkip > 0) {
              if (chunk.length <= bytesToSkip) {
                bytesToSkip -= chunk.length;
                subscription?.resume();
                return;
              } else {
                final skippedChunk = chunk.sublist(bytesToSkip);
                bytesToSkip = 0;

                if (skippedChunk.isNotEmpty) {
                  final chunkToSend = skippedChunk.length <= bytesToSend
                      ? skippedChunk
                      : skippedChunk.sublist(0, bytesToSend);

                  await response.addStream(Stream.value(chunkToSend));
                  bytesSent += chunkToSend.length;
                  bytesToSend -= chunkToSend.length;
                }
              }
            } else {
              final chunkToSend = chunk.length <= bytesToSend
                  ? chunk
                  : chunk.sublist(0, bytesToSend);

              await response.addStream(Stream.value(chunkToSend));
              bytesSent += chunkToSend.length;
              bytesToSend -= chunkToSend.length;
            }

            if (bytesToSend <= 0) {
              completer.complete();
            } else {
              subscription?.resume();
            }
          } catch (e) {
            if (!completer.isCompleted) {
              completer.completeError(e);
            }
          }
        },
        onError: (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        cancelOnError: true,
      );

      _activeSubscriptions[requestId] = subscription;

      await completer.future.timeout(
        const Duration(minutes: 30),
        onTimeout: () {
          throw TimeoutException('Stream timeout');
        },
      );

      await response.flush();
      await response.close();
    } on TimeoutException {
    } catch (e) {
    } finally {
      _activeSubscriptions.remove(requestId);
      await subscription?.cancel();
    }
  }

  String _getContentType(String filePath) {
    final lowerPath = filePath.toLowerCase();

    if (lowerPath.endsWith('.mp4')) return 'video/mp4';
    if (lowerPath.endsWith('.mkv')) return 'video/x-matroska';
    if (lowerPath.endsWith('.avi')) return 'video/x-msvideo';
    if (lowerPath.endsWith('.mov')) return 'video/quicktime';
    if (lowerPath.endsWith('.webm')) return 'video/webm';
    if (lowerPath.endsWith('.flv')) return 'video/x-flv';
    if (lowerPath.endsWith('.wmv')) return 'video/x-ms-wmv';
    if (lowerPath.endsWith('.m4v')) return 'video/x-m4v';

    return 'application/octet-stream';
  }

  void _handleServerError(error) {}

  String getSmbProxyUrl(String smbPath) {
    final encodedPath = Uri.encodeComponent(smbPath);
    return '$baseUrl/smb/$encodedPath';
  }
}
