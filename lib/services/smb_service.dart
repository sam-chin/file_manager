import 'package:smb_connect/smb_connect.dart';
import '../models/file_item.dart';

class SmbService {
  SmbConnect? connection;

  Future<void> connect(String host, String user, String pass) async {
    connection = await SmbConnect.connectAuth(
      host: host,
      domain: "",
      username: user,
      password: pass
    );
  }

  Future<List<FileItem>> list(String path) async {
    if (connection == null) return [];
    var folder = await connection!.file(path);
    var files = await connection!.listFiles(folder);
    
    return files.map((f) => FileItem(
      name: f.path.split('/').last.isEmpty ? f.path : f.path.split('/').last,
      path: f.path,
      size: f.size,
      isDirectory: f.isDirectory(),
      type: f.isDirectory() ? FileItemType.folder : FileItemType.video
    )).toList();
  }

  Future<void> delete(String path) async {
    if (connection == null) return;
    var f = await connection!.file(path);
    await connection!.delete(f);
  }
}
