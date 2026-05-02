import '../models/file_item.dart';

abstract class StorageRepository {
  // 统一的列出文件接口
  Future<List<FileItem>> getFiles(String path);
  
  // 统一的搜索接口
  Future<List<FileItem>> search(String query, String path);
  
  // 统一的文件详情接口
  Future<FileItem> getDetails(String path);
  
  // 是否已连接
  bool get isConnected;
  
  // 连接
  Future<bool> connect();
  
  // 断开连接
  Future<void> disconnect();
}
