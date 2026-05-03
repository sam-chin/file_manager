import 'package:flutter/material.dart';
import '../services/app_service.dart';
import '../models/file_item.dart';

class FileBrowserPage extends StatefulWidget {
  final String currentPath;
  const FileBrowserPage({super.key, this.currentPath = "/"});

  @override
  State<FileBrowserPage> createState() => _FileBrowserPageState();
}

class _FileBrowserPageState extends State<FileBrowserPage> {
  List<FileItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await AppService().browse(widget.currentPath);
      setState(() => _items = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("加载失败: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.currentPath)),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return ListTile(
                leading: Icon(item.isDirectory ? Icons.folder : Icons.video_file),
                title: Text(item.name),
                subtitle: item.isDirectory ? null : Text("${(item.size / 1024 / 1024).toStringAsFixed(2)} MB"),
                onTap: () {
                  if (item.isDirectory) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => FileBrowserPage(currentPath: item.path),
                    ));
                  } else {
                    _playVideo(item);
                  }
                },
                onLongPress: () => _showMenu(item),
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.create_new_folder),
        onPressed: () => _createNewFolder(),
      ),
    );
  }

  void _showMenu(FileItem item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("重命名"),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text("删除"),
            onTap: () async {
              Navigator.pop(context);
              await AppService().deleteItem(item);
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  void _playVideo(FileItem item) async {
    await AppService().playMedia(context, item);
  }

  void _createNewFolder() {
  }
}
