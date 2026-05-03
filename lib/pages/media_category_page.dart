import 'package:flutter/material.dart';
import '../services/app_service.dart';
import '../models/file_item.dart';
import 'file_browser_page.dart';

class MediaCategoryPage extends StatefulWidget {
  final FileItemType type;

  const MediaCategoryPage({super.key, required this.type});

  @override
  State<MediaCategoryPage> createState() => _MediaCategoryPageState();
}

class _MediaCategoryPageState extends State<MediaCategoryPage> {
  List<FileItem> folders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() => isLoading = true);
    try {
      final result = await AppService().listFoldersByMedia(widget.type);
      setState(() {
        folders = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = _getTitle();
    IconData icon = _getIcon();
    Color color = _getColor();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFolders,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : folders.isEmpty
              ? const Center(child: Text('未找到相关文件夹'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: folders.length,
                  itemBuilder: (context, index) => _buildFolderCard(folders[index], icon, color),
                ),
    );
  }

  Widget _buildFolderCard(FileItem folder, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: Icon(Icons.folder, color: color, size: 36),
        title: Text(
          folder.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        subtitle: const Text('点击进入查看文件'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FileBrowserPage(path: folder.path),
            ),
          );
        },
      ),
    );
  }

  String _getTitle() {
    switch (widget.type) {
      case FileItemType.audio:
        return '音乐文件夹';
      case FileItemType.video:
        return '视频文件夹';
      case FileItemType.image:
        return '图片文件夹';
      default:
        return '文件夹';
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case FileItemType.audio:
        return Icons.music_note;
      case FileItemType.video:
        return Icons.movie;
      case FileItemType.image:
        return Icons.image;
      default:
        return Icons.folder;
    }
  }

  Color _getColor() {
    switch (widget.type) {
      case FileItemType.audio:
        return Colors.purple;
      case FileItemType.video:
        return Colors.blue;
      case FileItemType.image:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
