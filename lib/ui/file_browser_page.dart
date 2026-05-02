import 'package:flutter/material.dart';
import '../models/server_record.dart';
import '../services/smb_service.dart';
import 'video_player_page.dart';

class FileBrowserPage extends StatefulWidget {
  final ServerRecord server;

  const FileBrowserPage({super.key, required this.server});

  @override
  State<FileBrowserPage> createState() => _FileBrowserPageState();
}

class _FileBrowserPageState extends State<FileBrowserPage> {
  List<SmbFileInfo> _files = [];
  bool _isLoading = false;
  bool _isConnected = false;
  String _currentPath = '';

  @override
  void initState() {
    super.initState();
    _connectAndLoad();
  }

  Future<void> _connectAndLoad() async {
    setState(() {
      _isLoading = true;
    });

    if (widget.server.type == ServerType.smb) {
      final connected = await SmbService().connect(
        host: widget.server.host,
        share: widget.server.share ?? '',
        domain: widget.server.domain,
        username: widget.server.username,
        password: widget.server.encryptedPassword,
      );

      if (connected) {
        setState(() {
          _isConnected = true;
        });
        await _loadFiles('');
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
      final files = await SmbService().listFiles(path);
      setState(() {
        _files = files;
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
    SmbService().disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.server.name),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isConnected
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
                            Icons.videocam_off,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '没有找到视频文件',
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
                            Icons.video_library,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(file.name),
                          subtitle: Text(_formatSize(file.size)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoPlayerPage(
                                  server: widget.server,
                                  filePath: '$_currentPath/${file.name}',
                                  fileName: file.name,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
