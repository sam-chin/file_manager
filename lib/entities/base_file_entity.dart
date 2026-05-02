enum FileType { file, directory }

class BaseFileEntity {
  final String name;
  final String path;
  final FileType type;
  final int size;
  final DateTime? modifiedTime;

  const BaseFileEntity({
    required this.name,
    required this.path,
    required this.type,
    this.size = 0,
    this.modifiedTime,
  });

  bool get isDirectory => type == FileType.directory;
  bool get isFile => type == FileType.file;

  String? get extension {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) return null;
    return name.substring(dotIndex + 1).toLowerCase();
  }

  bool get isVideo {
    if (!isFile) return false;
    const videoExtensions = ['mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm', 'iso'];
    return videoExtensions.contains(extension);
  }

  BaseFileEntity copyWith({
    String? name,
    String? path,
    FileType? type,
    int? size,
    DateTime? modifiedTime,
  }) {
    return BaseFileEntity(
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
      size: size ?? this.size,
      modifiedTime: modifiedTime ?? this.modifiedTime,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaseFileEntity &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          path == other.path &&
          type == other.type &&
          size == other.size;

  @override
  int get hashCode => Object.hash(name, path, type, size);

  @override
  String toString() {
    return 'BaseFileEntity(name: $name, path: $path, type: $type, size: $size)';
  }
}
