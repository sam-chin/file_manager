import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../models/server_record.dart';
import '../services/app_service.dart';
import 'server_list_page.dart';
import 'file_browser_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AppService _appService = AppService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            _buildSearchBar(),
            const SizedBox(height: 20),
            _buildStorageOverview(),
            const SizedBox(height: 24),
            _buildCategoryGrid(),
            const SizedBox(height: 24),
            _buildLanShareCard(),
            const SizedBox(height: 24),
            _buildRecentAndFavorites(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: '搜索文件名...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onSubmitted: (value) async {
          if (value.isNotEmpty && _appService.hasActiveServer) {
            final results = await _appService.browse('');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('找到 ${results.length} 个文件')),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildStorageOverview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _appService.hasActiveServer 
                    ? _appService.currentServerName
                    : "未连接服务器",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_appService.hasActiveServer)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "已连接",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                    ),
                  ),
                ),
            ],
          ),
          if (_appService.currentServer != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _appService.currentServer!.host,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      _CategoryItem(
        icon: Icons.video_library,
        color: Colors.red,
        label: "视频",
        count: null,
        onTap: () async {
          if (!_appService.hasActiveServer) {
            _showNoServerMessage();
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FileBrowserPage(
                title: "视频",
                filterType: FileType.video,
              ),
            ),
          );
        },
      ),
      _CategoryItem(
        icon: Icons.music_note,
        color: Colors.green,
        label: "音乐",
        count: null,
        onTap: () async {
          if (!_appService.hasActiveServer) {
            _showNoServerMessage();
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FileBrowserPage(
                title: "音乐",
                filterType: FileType.audio,
              ),
            ),
          );
        },
      ),
      _CategoryItem(
        icon: Icons.image,
        color: Colors.orange,
        label: "图片",
        count: null,
        onTap: () async {
          if (!_appService.hasActiveServer) {
            _showNoServerMessage();
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FileBrowserPage(
                title: "图片",
                filterType: FileType.image,
              ),
            ),
          );
        },
      ),
      _CategoryItem(
        icon: Icons.folder,
        color: Colors.blue,
        label: "文件浏览",
        count: null,
        onTap: () async {
          if (!_appService.hasActiveServer) {
            _showNoServerMessage();
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FileBrowserPage(
                title: "文件浏览",
              ),
            ),
          );
        },
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: categories.map((cat) => _buildCategoryItem(cat)).toList(),
    );
  }

  void _showNoServerMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("请先在局域网共享中添加并选择服务器")),
    );
  }

  Widget _buildCategoryItem(_CategoryItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    item.icon,
                    color: item.color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.count != null)
                  Text(
                    "${item.count} 个文件",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanShareCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ServerListPage(),
              ),
            );
            if (mounted && result is ServerRecord) {
              setState(() {
                _isLoading = true;
              });
              try {
                await _appService.setCurrentServer(result);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("已连接: ${result.name}")),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("连接失败: $e")),
                  );
                }
              }
              setState(() {
                _isLoading = false;
              });
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.lan,
                        color: Colors.purple,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "局域网共享",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _appService.hasActiveServer 
                                ? "当前服务器: ${_appService.currentServerName}"
                                : "点击添加服务器",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
                if (_isLoading)
                  const Positioned(
                    right: 40,
                    top: 24,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentAndFavorites() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "收藏与最近",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            icon: Icons.star,
            color: Colors.amber,
            title: "收藏",
            subtitle: "快速访问常用文件夹",
            onTap: () {},
          ),
          const Divider(height: 32),
          _buildSection(
            icon: Icons.history,
            color: Colors.grey,
            title: "最近文件",
            subtitle: "查看最近打开的资源",
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryItem {
  final IconData icon;
  final Color color;
  final String label;
  final int? count;
  final VoidCallback onTap;

  _CategoryItem({
    required this.icon,
    required this.color,
    required this.label,
    this.count,
    required this.onTap,
  });
}
