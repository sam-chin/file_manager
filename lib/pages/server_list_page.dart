import 'package:flutter/material.dart';
import '../services/app_service.dart';
import '../models/server_record.dart';

class ServerListPage extends StatefulWidget {
  const ServerListPage({super.key});

  @override
  State<ServerListPage> createState() => _ServerListPageState();
}

class _ServerListPageState extends State<ServerListPage> {
  void _showAddServerDialog() {
    final nameController = TextEditingController();
    final ipController = TextEditingController();
    final userController = TextEditingController();
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("添加 SMB 设备"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "设备名称")),
            TextField(controller: ipController, decoration: const InputDecoration(labelText: "IP 地址 (如 192.168.1.5)")),
            TextField(controller: userController, decoration: const InputDecoration(labelText: "账号")),
            TextField(controller: passController, decoration: const InputDecoration(labelText: "密码"), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
          ElevatedButton(
            onPressed: () async {
              final newServer = ServerRecord(
                name: nameController.text,
                ip: ipController.text,
                username: userController.text,
                password: passController.text,
              );
              await AppService().db.insertServer(newServer);
              await AppService().init();
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text("保存"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final servers = AppService().savedServers;

    return Scaffold(
      appBar: AppBar(title: const Text("我的设备")),
      body: servers.isEmpty
        ? const Center(child: Text("暂无设备，请点击右下角添加"))
        : ListView.builder(
            itemCount: servers.length,
            itemBuilder: (context, index) => ListTile(
              leading: const Icon(Icons.storage, color: Colors.blue),
              title: Text(servers[index].name),
              subtitle: Text(servers[index].ip),
              onTap: () async {
                try {
                  await AppService().connect(servers[index]);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("连接成功！")));
                  }
                  Navigator.pop(context);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("连接失败: $e")));
                  }
                }
              },
            ),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddServerDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
