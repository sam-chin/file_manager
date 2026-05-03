import 'package:flutter/material.dart';
import '../services/app_service.dart';
import '../models/server_record.dart';

class ServerListPage extends StatefulWidget {
  const ServerListPage({super.key});
  @override
  State<ServerListPage> createState() => _ServerListPageState();
}

class _ServerListPageState extends State<ServerListPage> {
  void _addServer() {
    // 简化逻辑：此处应弹出 Dialog 让用户输入 IP/账号/密码
    // 然后调用 AppService().db.insertServer(...)
  }

  @override
  Widget build(BuildContext context) {
    final servers = AppService().savedServers;
    return Scaffold(
      appBar: AppBar(title: const Text("局域网共享")),
      body: ListView.builder(
        itemCount: servers.length,
        itemBuilder: (context, i) => ListTile(
          leading: const Icon(Icons.dns),
          title: Text(servers[i].name),
          subtitle: Text(servers[i].ip),
          onTap: () async {
            await AppService().connect(servers[i]);
            if (mounted) Navigator.pop(context);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _addServer, child: const Icon(Icons.add)),
    );
  }
}