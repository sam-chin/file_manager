import 'package:flutter/material.dart';
import '../services/app_service.dart';
import '../models/file_item.dart';

class FileBrowserPage extends StatefulWidget {
  final String path;
  const FileBrowserPage({super.key, this.path = "/"});

  @override
  State<FileBrowserPage> createState() => _FileBrowserPageState();
}

class _FileBrowserPageState extends State<FileBrowserPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.path == "/" ? "文件管理" : widget.path.split('/').last)),
      body: FutureBuilder<List<FileItem>>(
        future: AppService().browse(widget.path),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("加载失败: ${snapshot.error}"));
          }
          final files = snapshot.data ?? [];
          if (files.isEmpty) {
            return const Center(child: Text("文件夹是空的，或未连接服务器"));
          }

          return ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final item = files[index];
              return ListTile(
                leading: Icon(item.isDirectory ? Icons.folder : Icons.insert_drive_file),
                title: Text(item.name),
                subtitle: item.isDirectory ? null : Text("${(item.size / 1024 / 1024).toStringAsFixed(2)} MB"),
                onTap: () {
                  if (item.isDirectory) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => FileBrowserPage(path: item.path),
                    ));
                  } else {
                    AppService().playMedia(context, item);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
