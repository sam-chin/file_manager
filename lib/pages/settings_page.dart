import 'package:flutter/material.dart';
import '../services/app_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSectionHeader('外观'),
          _buildListTile(
            Icons.wallpaper,
            '更改背景图片',
            () => _showInfo(context, '背景图片'),
          ),
          _buildListTile(
            Icons.palette,
            '主题颜色',
            () => _showInfo(context, '主题颜色'),
          ),
          const Divider(height: 1),
          _buildSectionHeader('内容管理'),
          _buildListTile(
            Icons.visibility_off,
            '隐藏文件夹管理',
            () => _navigateToHiddenFolders(context),
          ),
          _buildListTile(
            Icons.refresh,
            '清空缓存',
            () => _showConfirm(context, '清空缓存'),
          ),
          const Divider(height: 1),
          _buildSectionHeader('其他'),
          _buildListTile(
            Icons.info,
            '关于',
            () => _showAbout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _navigateToHiddenFolders(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('隐藏文件夹管理'),
        content: const Text('功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: const Text('功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showConfirm(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action),
        content: const Text('确定要执行此操作吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('操作成功')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'SMB 多媒体播放器',
      applicationVersion: 'v2.1.0',
      applicationLegalese: '© 2026',
      children: const [
        SizedBox(height: 16),
        Text('基于 Flutter + SMB2 协议的跨平台媒体播放应用'),
      ],
    );
  }
}
