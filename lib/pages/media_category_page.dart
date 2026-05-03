class MediaCategoryPage extends StatefulWidget {
  final String category;
  const MediaCategoryPage({super.key, required this.category});

  @override
  State<MediaCategoryPage> createState() => _MediaCategoryPageState();
}

class _MediaCategoryPageState extends State<MediaCategoryPage> {
  // 逻辑：调用 AppService 获取全局文件索引，并根据扩展名过滤
  // 也可以通过递归 SMB 目录来查找
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category)),
      body: Center(child: Text("${widget.category} 列表开发中...")), // 这里复用 FileBrowser 的 ListView 逻辑
    );
  }
}