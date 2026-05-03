import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/file_item.dart';
import '../services/media_service.dart';

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

  FileItem _entityToFileItem(FileSystemEntity entity) {
    final name = entity.path.split('/').last;
    final isDir = entity is Directory;
    int size = 0;
    if (!isDir && entity is File) {
      size = entity.lengthSync();
    }
    return FileItem(
      name: name,
      path: entity.path,
      size: size,
      isDirectory: isDir,
      type: isDir ? FileItemType.folder : FileItemType.video,
    );
  }

  IconData _getIcon(FileSystemEntity entity) {
    if (entity is Directory) return Icons.folder;
    final name = entity.path.toLowerCase();
    if (name.endsWith('.mp4') || name.endsWith('.mkv') || name.endsWith('.mov')) {
      return Icons.video_file;
    }
    if (name.endsWith('.mp3') || name.endsWith('.flac') || name.endsWith('.wav')) {
      return Icons.audio_file;
    }
    if (name.endsWith('.jpg') || name.endsWith('.png') || name.endsWith('.gif')) {
      return Icons.image;
    }
    return Icons.insert_drive_file;
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
                return GestureDetector(
                  onDoubleTap: isDir ? null : () {
                    MediaService().openFile(_entityToFileItem(entity));
                  },
                  child: ListTile(
                    leading: Icon(
                      _getIcon(entity),
                      color: isDir ? Colors.amber : Colors.grey,
                    ),
                    title: Text(name),
                    onTap: () {
                      if (isDir) {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => FileBrowserPage(path: entity.path),
                        ));
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
