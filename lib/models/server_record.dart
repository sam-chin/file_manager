// lib/models/server_record.dart
// 去掉所有 isar 注解，改为纯 Dart 类 + sqflite Map 序列化

enum ServerType { smb, ftp }

class ServerRecord {
  int? id;
  ServerType type;
  String name;
  String host;
  int port;
  String? share;
  String? domain;
  String? username;
  String? encryptedPassword;
  DateTime createdAt;
  DateTime? lastConnected;

  ServerRecord({
    this.id,
    required this.type,
    required this.name,
    required this.host,
    this.port = 0,
    this.share,
    this.domain,
    this.username,
    this.encryptedPassword,
    DateTime? createdAt,
    this.lastConnected,
  }) : createdAt = createdAt ?? DateTime.now();

  // sqflite 序列化
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'type': type.index,
        'name': name,
        'host': host,
        'port': port,
        'share': share,
        'domain': domain,
        'username': username,
        'encrypted_password': encryptedPassword,
        'created_at': createdAt.millisecondsSinceEpoch,
        'last_connected': lastConnected?.millisecondsSinceEpoch,
      };

  factory ServerRecord.fromMap(Map<String, dynamic> map) => ServerRecord(
        id: map['id'] as int?,
        type: ServerType.values[map['type'] as int],
        name: map['name'] as String,
        host: map['host'] as String,
        port: (map['port'] as int?) ?? 0,
        share: map['share'] as String?,
        domain: map['domain'] as String?,
        username: map['username'] as String?,
        encryptedPassword: map['encrypted_password'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            map['created_at'] as int),
        lastConnected: map['last_connected'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                map['last_connected'] as int)
            : null,
      );
}
