import '../models/file_item.dart';
import '../models/server_record.dart';
import '../services/smb_service.dart';
import 'storage_repository.dart';

class SmbStorageRepository implements StorageRepository {
  final SmbService _smbService;
  final ServerRecord _server;
  bool _isConnected = false;
  
  SmbStorageRepository({
    required SmbService smbService,
    required ServerRecord server,
  }) : _smbService = smbService,
       _server = server;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<bool> connect() async {
    // 简化连接逻辑，不实际建立长连接，只是标记
    _isConnected = true;
    return true;
  }

  @override
  Future<void> disconnect() async {
    _isConnected = false;
  }

  @override
  Future<List<FileItem>> getFiles(String path) async {
    // 每次调用时直接通过 server 和 path 来获取
    return await _smbService.listFiles(_server, path);
  }

  @override
  Future<List<FileItem>> search(String query, String path) async {
    final allFiles = await getFiles(path);
    
    return allFiles.where((file) {
      if (file.type == FileType.folder) return false;
      return file.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  @override
  Future<FileItem> getDetails(String path) async {
    // 对于 SMB，我们从列表中获取
    final parentPath = _getParentPath(path);
    final allFiles = await getFiles(parentPath);
    
    final fileName = _getFileName(path);
    return allFiles.firstWhere(
      (file) => file.name == fileName,
      orElse: () => throw Exception("File not found: $path"),
    );
  }

  String _getParentPath(String path) {
    if (!path.contains('/')) return '';
    return path.substring(0, path.lastIndexOf('/'));
  }

  String _getFileName(String path) {
    if (!path.contains('/')) return path;
    return path.substring(path.lastIndexOf('/') + 1);
  }
}
