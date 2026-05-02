import 'dart:io';

enum FileType {
  video,
  audio,
  image,
  folder,
  document,
  other,
}

class FileItem {
  final String name;
  final String path;
  final bool isRemote;
  final FileType type;
  final int size;
  final DateTime? modifiedTime;
  final String? serverId;

  FileItem({
    required this.name,
    required this.path,
    this.isRemote = false,
    this.type = FileType.other,
    this.size = 0,
    this.modifiedTime,
    this.serverId,
  });

  factory FileItem.fromFile(File file) {
    final stat = file.statSync();
    return FileItem(
      name: file.path.split(Platform.pathSeparator).last,
      path: file.path,
      isRemote: false,
      type: _detectFileType(file.path),
      size: stat.size,
      modifiedTime: stat.modified,
    );
  }

  static FileType _detectFileType(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (['mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm', 'm4v', 'iso'].contains(ext)) {
      return FileType.video;
    }
    if (['mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a'].contains(ext)) {
      return FileType.audio;
    }
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic'].contains(ext)) {
      return FileType.image;
    }
    if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'rtf'].contains(ext)) {
      return FileType.document;
    }
    return FileType.other;
  }

  String get displaySize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  FileItem copyWith({
    String? name,
    String? path,
    bool? isRemote,
    FileType? type,
    int? size,
    DateTime? modifiedTime,
    String? serverId,
  }) {
    return FileItem(
      name: name ?? this.name,
      path: path ?? this.path,
      isRemote: isRemote ?? this.isRemote,
      type: type ?? this.type,
      size: size ?? this.size,
      modifiedTime: modifiedTime ?? this.modifiedTime,
      serverId: serverId ?? this.serverId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileItem &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          path == other.path &&
          isRemote == other.isRemote &&
          type == other.type;

  @override
  int get hashCode => name.hashCode ^ path.hashCode ^ isRemote.hashCode ^ type.hashCode;
}
