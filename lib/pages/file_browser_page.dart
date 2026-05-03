import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class FileBrowserPage extends StatefulWidget {
  final String? path;
  const FileBrowserPage({super.key, this.path});

  @override
  State<FileBrowserPage> createState() => _FileBrowserPageState();
}

class _FileBrowserPageState extends State<FileBrowserPage> {
  late String currentPath;
  List<FileSystemEntity> files = [];

  @override
  void initState() {
    super.initState();
    _initPath();
  }

  Future<void> _initPath() async {
    final statusStorage = await Permission.storage.request();
    final statusManage = await Permission.manageExternalStorage.request();
    
    if (statusStorage.isGranted || statusManage.isGranted) {
      if (widget.path == null) {
        currentPath = "/storage/emulated/0";
      } else {
        currentPath = widget.path!;
      }
      _fetchFiles();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("需要存储权限")));
      }
    }
  }

  void _fetchFiles() {
    try {
      final dir = Directory(currentPath);
      setState(() {
        files = dir.listSync();
        files.sort((a, b) {
          final aIsDir = a is Directory;
          final bIsDir = b is Directory;
          if (aIsDir && !bIsDir) return -1;
          if (!aIsDir && bIsDir) return 1;
          return a.path.toLowerCase().compareTo(b.path.toLowerCase());
        });
      });
    } catch (e) {
      debugPrint("读取失败: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(currentPath.split('/').last)),
      body: files.isEmpty
          ? const Center(child: Text("文件夹为空或无权限"))
          : ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final entity = files[index];
                final isDir = entity is Directory;
                final name = entity.path.split('/').last;
                return ListTile(
                  leading: Icon(isDir ? Icons.folder : Icons.insert_drive_file, color: isDir ? Colors.amber : Colors.grey),
                  title: Text(name),
                  onTap: () {
                    if (isDir) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => FileBrowserPage(path: entity.path),
                      ));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("文件播放功能待实现")));
                    }
                  },
                );
              },
            ),
    );
  }
}
