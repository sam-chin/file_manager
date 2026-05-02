import 'package:flutter/material.dart';
import '../models/server_record.dart';
import '../models/file_item.dart';
import '../services/smb_service.dart';
import 'video_player_page.dart';

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
  List<FileItem> _files = [];
  bool _isLoading = false;
  bool _isConnected = false;
  String _currentPath = '';

  bool get _isRemoteMode => widget.server != null;

  @override
  void initState() {
    super.initState();
    if (_isRemoteMode) {
      _connectAndLoad();
    } else {
      _loadLocalFiles();
    }
  }

  Future<void> _connectAndLoad() async {
    setState(() {
      _isLoading = true;
    });

    if (widget.server!.type == ServerType.smb) {
      final connected = await SmbService().connect(
        host: widget.server!.host,
        share: widget.server!.share ?? '',
        domain: widget.server!.domain,
        username: widget.server!.username,
        password: widget.server!.encryptedPassword,
      );

      if (connected) {
        setState(() {
          _isConnected = true;
        });
        await _loadRemoteFiles('');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadRemoteFiles(String path) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final entities = await SmbService().listFiles(path, filterVideos: widget.filterType == FileType.video);
      
      final List<FileItem> allFiles = [];
      
      if (path.isNotEmpty) {
        allFiles.add(FileItem(
          name: '..',
          path: path,
          isRemote: true,
          type: FileType.folder,
        ));
      }
      
      allFiles.addAll(entities.map((e) => FileItem(
        name: e.name,
        path: e.path,
        isRemote: true,
        type: e.isDirectory ? FileType.folder : e.type,
        size: e.size,
        modifiedTime: e.modifiedTime,
      )));
      
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

  Future<void> _loadLocalFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      setState(() {
        _files = [];
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
    SmbService().disconnect();
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
                            widget.filterType == FileType.video ? Icons.videocam_off : Icons.folder_open,
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

  void _onFileTap(FileItem file) {
    if (file.name == '..') {
      final parentPath = _getParentPath(_currentPath);
      _loadRemoteFiles(parentPath);
    } else if (file.type == FileType.folder) {
      final newPath = _currentPath.isEmpty ? file.name : '$_currentPath/${file.name}';
      _loadRemoteFiles(newPath);
    } else if (file.type == FileType.video) {
      final filePath = _currentPath.isEmpty ? file.name : '$_currentPath/${file.name}';
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerPage(
            server: widget.server,
            filePath: filePath,
            fileName: file.name,
          ),
        ),
      );
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
