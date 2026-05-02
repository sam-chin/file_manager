enum FileType { folder, video, audio, image, document, unknown }

class FileItem {
  final String name;
  final String path;
  final int size;
  final DateTime modifiedTime;
  final FileType type;
  final bool isDirectory;

  FileItem({
    required this.name,
    required this.path,
    required this.size,
    required this.modifiedTime,
    required this.type,
    required this.isDirectory,
  });

  String get displaySize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
