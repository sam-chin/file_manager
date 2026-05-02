import 'package:flutter/material.dart';
import '../models/server_record.dart';
import '../models/file_item.dart';
import '../services/app_service.dart';

class FileBrowserPage extends StatefulWidget {
  final String title;
  final ServerRecord? server;
  final FileType? filterType;

  const FileBrowserPage({
    super.key,
    required this.title,
    this.server,
    this.filterType,
  });

  @override
  State<FileBrowserPage> createState() => _FileBrowserPageState();
}

class _FileBrowserPageState extends State<FileBrowserPage> {
  final AppService _appService = AppService();
  
  List<FileItem> _files = [];
  bool _isLoading = false;
  bool _isConnected = false;
  String _currentPath = "";

  bool get _isRemoteMode => widget.server != null;

  @override
  void initState() {
    super.initState();
    if (_isRemoteMode) {
      _connectAndLoad();
    }
  }

  Future<void> _connectAndLoad() async {
    setState(() {
      _isLoading = true;
    });

    if (widget.server != null) {
      await _appService.setCurrentServer(widget.server);
      final connected = await _appService.connect();

      if (connected) {
        setState(() {
          _isConnected = true;
        });
        await _loadFiles(_currentPath);
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadFiles(String path) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final entities = await _appService.browse(path);
      
      final List<FileItem> allFiles = [];
      
      if (path.isNotEmpty) {
        allFiles.add(FileItem(
          name: '..',
          path: _getParentPath(path),
          size: 0,
          modifiedTime: DateTime.now(),
          isDirectory: true,
          type: FileType.folder,
        ));
      }
      
      // 过滤文件（如果需要的话）
      for (final entity in entities) {
        if (widget.filterType == null || 
            entity.type == widget.filterType || 
            entity.type == FileType.folder) {
          allFiles.add(entity);
        }
      }
      
      setState(() {
        _files = allFiles;
        _currentPath = path;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    // AppService 是全局单例，不需要在这里断开
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isRemoteMode && !_isConnected
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('连接失败'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _connectAndLoad,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _files.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.filterType == FileType.video 
                                ? Icons.videocam_off 
                                : Icons.folder_open,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _getEmptyText(),
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _files.length,
                      itemBuilder: (context, index) {
                        final file = _files[index];
                        return ListTile(
                          leading: Icon(
                            _getFileIcon(file),
                            color: _getFileIconColor(file),
                          ),
                          title: Text(file.name),
                          subtitle: Text(
                            file.type == FileType.folder ? '' : file.displaySize,
                          ),
                          onTap: () => _onFileTap(file),
                        );
                      },
                    ),
    );
  }

  IconData _getFileIcon(FileItem file) {
    if (file.name == '..') return Icons.arrow_back;
    if (file.type == FileType.folder) return Icons.folder;
    if (file.type == FileType.video) return Icons.video_library;
    if (file.type == FileType.audio) return Icons.music_note;
    if (file.type == FileType.image) return Icons.image;
    if (file.type == FileType.document) return Icons.description;
    return Icons.insert_drive_file;
  }

  Color _getFileIconColor(FileItem file) {
    if (file.name == '..') return Colors.grey;
    if (file.type == FileType.folder) return Colors.orange;
    if (file.type == FileType.video) return Colors.red;
    if (file.type == FileType.audio) return Colors.green;
    if (file.type == FileType.image) return Colors.orange;
    return Colors.blue;
  }

  void _onFileTap(FileItem file) async {
    if (file.name == '..') {
      final parentPath = _getParentPath(_currentPath);
      _loadFiles(parentPath);
    } else if (file.type == FileType.folder) {
      final newPath = _currentPath.isEmpty ? file.name : '$_currentPath/${file.name}';
      _loadFiles(newPath);
    } else if (file.type == FileType.video) {
      // 统一调用中控台进行播放
      try {
        final proxyUrl = await _appService.preparePlayback(file);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('准备播放: ${file.name}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('准备播放失败: $e')),
          );
        }
      }
    }
  }

  String _getEmptyText() {
    if (widget.filterType == FileType.video) return '没有找到视频文件';
    if (widget.filterType == FileType.audio) return '没有找到音频文件';
    if (widget.filterType == FileType.image) return '没有找到图片文件';
    return '文件夹为空';
  }

  String _getParentPath(String path) {
    if (!path.contains('/')) return '';
    return path.substring(0, path.lastIndexOf('/'));
  }
}
