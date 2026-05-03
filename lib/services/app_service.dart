import '../models/server_record.dart';
import '../models/file_item.dart';
import 'smb_service.dart';
import 'dlna_service.dart';
import 'stream_proxy_server.dart';

class AppService {
  // 单例模式保持不变
  static final AppService _instance = AppService._internal();
  factory AppService() => _instance;
  AppService._internal();

  final SmbService _smbService = SmbService();
  final DlnaService _dlnaService = DlnaService();
  final StreamProxyServer _proxyServer = StreamProxyServer();

  // 关键：保存当前连接的服务器信息
  ServerRecord? _activeServer;

  // 1. 设置当前服务器 (从 ServerListPage 跳转时调用)
  void setCurrentServer(ServerRecord server) {
    _activeServer = server;
  }

  // 2. 统一浏览接口
  Future<List<FileItem>> browse(String path) async {
    if (_activeServer == null) throw "未选中服务器";

    if (_activeServer!.type == ServerType.smb) {
      // 这里的 path 建议以 / 开头，例如 "/Movies"
      return await _smbService.listFiles(_activeServer!, path);
    }
    
    // 如果以后有本地文件浏览，可以在这里扩展
    return [];
  }

  // 3. 准备播放 URL (针对 media_kit)
  Future<String> preparePlayback(FileItem item) async {
    if (item.isDirectory) throw "无法播放文件夹";

    // 如果是远程 SMB 文件，启动代理转发
    if (_activeServer?.type == ServerType.smb) {
      // 启动本地 HTTP 代理，将 SMB 流转为 HTTP 流
      return await _proxyServer.startProxy(item, _activeServer!);
    }
    
    return item.path; // 本地文件直接返回路径
  }

  // 4. DLNA 投屏中控
  Future<void> castToDevice(FileItem item, dynamic device) async {
    final playUrl = await preparePlayback(item);
    await _dlnaService.cast(device, playUrl, item.name);
  }

  // 获取当前服务器信息
  ServerRecord? get currentServer => _activeServer;
  
  // 获取当前服务器名称（供 UI 显示）
  String get currentServerName => _activeServer?.name ?? "未连接";
  
  // 获取连接状态
  bool get hasActiveServer => _activeServer != null;
}
