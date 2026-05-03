import '../models/server_record.dart';
import '../models/file_item.dart';
import 'smb_service.dart';
import 'dlna_service.dart';
import 'stream_proxy_server.dart';

class AppService {
  // 单例模式
  static final AppService _instance = AppService._internal();
  factory AppService() => _instance;
  AppService._internal();

  // 内部服务，不暴露给 UI
  final SmbService _smbService = SmbService();
  final DlnaService _dlnaService = DlnaService();
  final StreamProxyServer _proxyServer = StreamProxyServer();

  // 当前服务器状态
  ServerRecord? _activeServer;

  // 1. 设置当前服务器
  void setCurrentServer(ServerRecord server) {
    _activeServer = server;
  }

  // 2. 统一浏览接口
  Future<List<FileItem>> browse(String path) async {
    if (_activeServer == null) throw "未选中服务器";

    if (_activeServer!.type == ServerType.smb) {
      return await _smbService.listFiles(_activeServer!, path);
    }
    
    return [];
  }

  // 3. 准备播放 URL
  Future<String> preparePlayback(FileItem item) async {
    if (item.isDirectory) throw "无法播放文件夹";

    if (_activeServer?.type == ServerType.smb) {
      return await _proxyServer.startProxy(item, _activeServer!);
    }
    
    return item.path;
  }

  // 4. DLNA 投屏中控 - 使用 dynamic，不暴露 DLNADevice
  Future<void> castToDevice(FileItem item, dynamic device) async {
    final playUrl = await preparePlayback(item);
    await _dlnaService.cast(device, playUrl, item.name);
  }

  // 获取当前服务器信息
  ServerRecord? get currentServer => _activeServer;
  
  // 获取当前服务器名称
  String get currentServerName => _activeServer?.name ?? "未连接";
  
  // 获取连接状态
  bool get hasActiveServer => _activeServer != null;
}
