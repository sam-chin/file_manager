import 'package:flutter/material.dart';
import '../services/app_service.dart';
import '../models/file_item.dart';
import 'server_list_page.dart';
import 'file_browser_page.dart';
import 'settings_page.dart';
import 'media_category_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appService = AppService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMB 多媒体播放器'),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade50,
        ),
        child: GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(20),
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          children: [
            _buildModule(context, '音乐', Icons.music_note, FileItemType.audio, Colors.purple),
            _buildModule(context, '视频', Icons.movie, FileItemType.video, Colors.blue),
            _buildModule(context, '图片', Icons.image, FileItemType.image, Colors.orange),
            _buildModule(context, '设备', Icons.storage, null, Colors.green),
            _buildModule(context, '设置', Icons.settings, null, Colors.grey, isSettings: true),
            _buildModule(context, '文件管理', Icons.folder_open, null, Colors.teal, isFileBrowser: true),
          ],
        ),
      ),
    );
  }

  Widget _buildModule(
    BuildContext context,
    String title,
    IconData icon,
    FileItemType? type,
    Color color, {
    bool isSettings = false,
    bool isFileBrowser = false,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _handleNavigation(context, type, isSettings, isFileBrowser),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: color,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(
    BuildContext context,
    FileItemType? type,
    bool isSettings,
    bool isFileBrowser,
  ) async {
    if (isSettings) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsPage()),
      );
    } else if (isFileBrowser) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FileBrowserPage()),
      );
    } else if (type != null) {
      if (AppService().currentServerName == '未连接') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ServerListPage()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MediaCategoryPage(type: type)),
        );
      }
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ServerListPage()),
      );
    }
  }
}
