import 'package:flutter/material.dart';
import 'smb_service.dart';
import 'db_helper.dart';
import 'proxy_server.dart';
import '../models/file_item.dart';
import '../models/server_record.dart';
import '../pages/player_page.dart';

class AppService {
  static final AppService _instance = AppService._internal();
  factory AppService() => _instance;
  AppService._internal();

  final SmbService smb = SmbService();
  final DBHelper db = DBHelper();
  List<ServerRecord> savedServers = [];

  Future<void> init() async {
    savedServers = await db.getServers();
  }

  // 全局播放方法：任何页面调用此方法即可
  Future<void> playMedia(BuildContext context, FileItem item) async {
    if (smb.connection == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("请先连接服务器")));
      return;
    }
    
    // 启动代理并获取流地址
    final baseUrl = await ProxyServer().start(smb.connection!);
    final streamUrl = "$baseUrl/stream?path=${Uri.encodeComponent(item.path)}";

    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => PlayerPage(url: streamUrl, title: item.name),
      ));
    }
  }

  // 辅助：连接并更新状态
  Future<void> connect(ServerRecord server) async {
    await smb.connect(server.ip, server.username, server.password);
  }
}