enum FileItemType { folder, video, audio, image, other }

class FileItem {
  final String name;
  final String path;
  final int size;
  final bool isDirectory;
  final FileItemType type;

  FileItem({
    required this.name,
    required this.path,
    required this.size,
    required this.isDirectory,
    required this.type,
  });
}