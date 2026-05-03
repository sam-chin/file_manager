import 'package:flutter/material.dart';
import '../services/app_service.dart';
import '../models/server_record.dart';

class ServerListPage extends StatefulWidget {
  const ServerListPage({super.key});

  @override
  State<ServerListPage> createState() => _ServerListPageState();
}

class _ServerListPageState extends State<ServerListPage> {
  void _showServerDialog({ServerRecord? existingServer}) {
    final nameController = TextEditingController(text: existingServer?.name);
    final ipController = TextEditingController(text: existingServer?.ip);
    final portController = TextEditingController(text: existingServer?.port.toString() ?? "445");
    final userController = TextEditingController(text: existingServer?.username);
    final passController = TextEditingController(text: existingServer?.password);
    final shareController = TextEditingController(text: existingServer?.shareName ?? "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingServer == null ? "添加设备" : "修改记录"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "设备名称")),
              TextField(controller: ipController, decoration: const InputDecoration(labelText: "IP 地址")),
              TextField(controller: portController, decoration: const InputDecoration(labelText: "端口"), keyboardType: TextInputType.number),
              TextField(controller: shareController, decoration: const InputDecoration(labelText: "共享文件夹 (留空则扫描根目录)")),
              TextField(controller: userController, decoration: const InputDecoration(labelText: "用户名")),
              TextField(controller: passController, decoration: const InputDecoration(labelText: "密码"), obscureText: true),
            ],
          ),
        ),
        actions: [
          if (existingServer != null)
            TextButton(
              onPressed: () async {
                await AppService().db.deleteServer(existingServer.id!);
                await AppService().init();
                if (mounted) setState(() {});
                if (mounted) Navigator.pop(context);
              },
              child: const Text("删除", style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          ElevatedButton(
            onPressed: () async {
              final server = ServerRecord(
                id: existingServer?.id,
                name: nameController.text,
                ip: ipController.text,
                port: int.tryParse(portController.text) ?? 445,
                username: userController.text,
                password: passController.text,
                shareName: shareController.text.isEmpty ? null : shareController.text,
              );
              
              if (existingServer == null) {
                await AppService().db.insertServer(server);
              } else {
                await AppService().db.updateServer(server);
              }
              await AppService().init();
              if (mounted) setState(() {});
              if (mounted) Navigator.pop(context);
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
              subtitle: Text(servers[index].shareName == null || servers[index].shareName!.isEmpty
                  ? "${servers[index].ip}:${servers[index].port}"
                  : "${servers[index].ip}:${servers[index].port} / ${servers[index].shareName}"),
              onTap: () async {
                try {
                  await AppService().connect(servers[index]);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("连接成功！")));
                  }
                  Navigator.pop(context);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
                  }
                }
              },
              onLongPress: () => _showServerDialog(existingServer: servers[index]),
            ),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServerDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
