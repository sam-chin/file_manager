// lib/services/app_service.dart
import '../models/server_record.dart';
import '../models/file_item.dart';
import 'smb_service.dart';
import 'ftp_service.dart';
import 'dlna_service.dart';
import 'stream_proxy_server.dart';

class AppService {
  static final AppService _instance = AppService._internal();
  factory AppService() => _instance;
  AppService._internal();

  final SmbService _smbService = SmbService();
  final FtpService _ftpService = FtpService();
  final DlnaService _dlnaService = DlnaService();
  final StreamProxyServer _proxyServer = StreamProxyServer();

  ServerRecord? _activeServer;

  // ── 服务器管理 ────────────────────────────────────────────

  void setCurrentServer(ServerRecord server) {
    _activeServer = server;
  }

  ServerRecord? get currentServer => _activeServer;
  String get currentServerName => _activeServer?.name ?? '未连接';
  bool get hasActiveServer => _activeServer != null;

  // ── 文件浏览 ──────────────────────────────────────────────

  Future<List<FileItem>> browse(String path) async {
    if (_activeServer == null) throw Exception('未选中服务器');

    switch (_activeServer!.type) {
      case ServerType.smb:
        return await _smbService.listFiles(_activeServer!, path);
      case ServerType.ftp:
        return await _ftpService.listFiles(_activeServer!, path);
    }
  }

  // ── 播放准备 ──────────────────────────────────────────────

  Future<String> preparePlayback(FileItem item) async {
    if (item.isDirectory) throw Exception('无法播放文件夹');

    if (_activeServer?.type == ServerType.smb) {
      return await _proxyServer.startProxy(item, _activeServer!);
    }
    return item.path;
  }

  // ── DLNA 投屏 ─────────────────────────────────────────────

  Future<void> startDlnaSearch({
    void Function(List<dynamic> devices)? onDevicesChanged,
  }) async {
    await _dlnaService.startSearch(onDevicesChanged: onDevicesChanged);
  }

  Future<void> stopDlnaSearch() async {
    await _dlnaService.stopSearch();
  }

  List<dynamic> get dlnaDevices => _dlnaService.devices;

  Future<void> castToDevice(FileItem item, dynamic device) async {
    final playUrl = await preparePlayback(item);
    await _dlnaService.cast(device, playUrl, item.name);
  }

  Future<void> pauseDlna(dynamic device) => _dlnaService.pause(device);
  Future<void> stopDlna(dynamic device) => _dlnaService.stop(device);
}
