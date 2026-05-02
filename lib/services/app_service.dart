import '../models/file_item.dart';
import '../models/server_record.dart';
import '../repositories/storage_repository.dart';
import '../repositories/smb_storage_repository.dart';
import 'smb_service.dart';
import 'dlna_service.dart';
import 'stream_proxy_server.dart';

class AppService {
  static final AppService _instance = AppService._internal();
  factory AppService() => _instance;
  AppService._internal();

  final SmbService smbService = SmbService();
  final DlnaService dlnaService = DlnaService();
  final StreamProxyServer proxyServer = StreamProxyServer();

  StorageRepository? _currentRepository;
  ServerRecord? _currentServer;

  ServerRecord? get currentServer => _currentServer;
  bool get isConnected => _currentRepository?.isConnected ?? false;

  // 设置当前服务器
  Future<void> setCurrentServer(ServerRecord? server) async {
    if (_currentRepository != null) {
      await _currentRepository!.disconnect();
    }

    _currentServer = server;

    if (server != null) {
      if (server.type == ServerType.smb) {
        _currentRepository = SmbStorageRepository(
          smbService: smbService,
          server: server,
        );
      }
    } else {
      _currentRepository = null;
    }
  }

  // 统一入口：浏览文件
  Future<List<FileItem>> browse(String path) async {
    if (_currentRepository == null) {
      throw Exception("No server selected");
    }
    return await _currentRepository!.getFiles(path);
  }

  // 统一搜索
  Future<List<FileItem>> search(String query, String path) async {
    if (_currentRepository == null) {
      return [];
    }
    return await _currentRepository!.search(query, path);
  }

  // 搜索所有视频
  Future<List<FileItem>> searchAllVideos() async {
    if (_currentRepository == null) {
      return [];
    }

    final allFiles = await _currentRepository!.getFiles("");
    return _filterByType(allFiles, FileType.video);
  }

  // 搜索所有音乐
  Future<List<FileItem>> searchAllAudio() async {
    if (_currentRepository == null) {
      return [];
    }

    final allFiles = await _currentRepository!.getFiles("");
    return _filterByType(allFiles, FileType.audio);
  }

  // 搜索所有图片
  Future<List<FileItem>> searchAllImages() async {
    if (_currentRepository == null) {
      return [];
    }

    final allFiles = await _currentRepository!.getFiles("");
    return _filterByType(allFiles, FileType.image);
  }

  List<FileItem> _filterByType(List<FileItem> files, FileType type) {
    return files.where((file) => file.type == type).toList();
  }

  // 统一投屏入口
  Future<void> castToDevice(FileItem file, dynamic device, String url) async {
    try {
      String playUrl = url;
      
      // 如果是 SMB 文件，使用代理
      if (_currentRepository is SmbStorageRepository) {
        playUrl = proxyServer.getSmbProxyUrl(file.path);
      }

      // 调用 DLNA 投屏
      await dlnaService.castVideo(device, playUrl, file.name);
    } catch (e) {
      print("Cast Error: $e");
      rethrow;
    }
  }

  // 统一播放准备
  Future<String> preparePlayback(FileItem file) async {
    try {
      // 启动代理服务器（如果还没启动）
      if (!proxyServer.isRunning) {
        await proxyServer.start();
      }

      // 返回代理 URL
      if (_currentRepository is SmbStorageRepository) {
        return proxyServer.getSmbProxyUrl(file.path);
      }

      return file.path;
    } catch (e) {
      print("Playback Prepare Error: $e");
      rethrow;
    }
  }

  // 连接到当前服务器
  Future<bool> connect() async {
    if (_currentRepository == null) return false;
    return await _currentRepository!.connect();
  }

  // 断开连接
  Future<void> disconnect() async {
    if (_currentRepository != null) {
      await _currentRepository!.disconnect();
    }
  }
}
