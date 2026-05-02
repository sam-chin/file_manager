import 'package:isar/isar.dart';

part 'server_record.g.dart';

enum ServerType { smb, ftp }

@collection
class ServerRecord {
  Id id = Isar.autoIncrement;
  
  @enumerated
  late ServerType type;
  
  late String name;
  late String host;
  int port = 0;
  String? share;
  String? domain;
  String? username;
  String? encryptedPassword;
  DateTime createdAt = DateTime.now();
  DateTime? lastConnected;
}
