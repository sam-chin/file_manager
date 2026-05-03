import 'package:flutter/material.dart';
import '../models/server_record.dart';
import '../services/database_service.dart';
import '../services/app_service.dart';
import 'file_browser_page.dart';
import 'add_server_page.dart';

class ServerListPage extends StatefulWidget {
  const ServerListPage({super.key});

  @override
  State<ServerListPage> createState() => _ServerListPageState();
}

class _ServerListPageState extends State<ServerListPage> {
  final AppService _appService = AppService();
  List<ServerRecord> _servers = [];
  bool _isLoading = false;
  String? _connectingServerId;

  @override
  void initState() {
    super.initState();
    _loadServers();
  }

  Future<void> _loadServers() async {
    final servers = await DatabaseService.getAllServers();
    setState(() {
      _servers = servers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("局域网服务器"),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddServerPage()),
          ).then((_) {
            _loadServers();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_servers.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storage,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "还没有添加服务器",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "点击右下角的 + 按钮添加",
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _servers.length,
      itemBuilder: (context, index) {
        final server = _servers[index];
        final isSelected = _appService.currentServer?.id == server.id;
        final isConnecting = _connectingServerId == server.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isSelected ? Colors.blue[50] : null,
          child: ListTile(
            leading: Icon(
              server.type == ServerType.smb ? Icons.folder_shared : Icons.cloud,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Row(
              children: [
                Text(server.name),
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "当前",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                if (isConnecting)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
            subtitle: Text("${server.host}${server.port > 0 ? ':${server.port}' : ''}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("确认删除"),
                        content: Text("确定要删除服务器 \"${server.name}\" 吗？"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("取消"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("删除"),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await DatabaseService.deleteServer(server.id);
                      _loadServers();
                    }
                  },
                ),
              ],
            ),
            onTap: isConnecting ? null : () async {
              setState(() {
                _connectingServerId = server.id;
              });

              try {
                await _appService.setCurrentServer(server);
                if (mounted) {
                  // 连接成功后，返回服务器对象给上一页
                  Navigator.pop(context, server);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("连接失败: $e")),
                  );
                }
              }

              setState(() {
                _connectingServerId = null;
              });
            },
          ),
        );
      },
    );
  }
}
