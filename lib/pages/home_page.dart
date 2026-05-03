import 'package:flutter/material.dart';
import 'file_browser_page.dart';
import 'server_list_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("媒体中心"), centerTitle: true),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        children: [
          _menuItem(context, "文件管理", Icons.folder_copy, Colors.orange, () => 
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FileBrowserPage()))),
          _menuItem(context, "设备连接", Icons.lan, Colors.blue, () => 
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ServerListPage()))),
          _menuItem(context, "最近播放", Icons.history, Colors.red, () {}),
          _menuItem(context, "设置", Icons.settings, Colors.grey, () {}),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}