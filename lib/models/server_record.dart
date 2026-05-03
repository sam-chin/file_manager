class ServerRecord {
  final int? id;
  final String name;
  final String ip;
  final String username;
  final String password;
  final String shareName;
  final String type; // SMB 或其他

  ServerRecord({
    this.id,
    required this.name,
    required this.ip,
    required this.username,
    required this.password,
    required this.shareName,
    this.type = 'SMB',
  });

  // 转换为数据库格式
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'ip': ip,
      'username': username,
      'password': password,
      'shareName': shareName,
      'type': type,
    };
  }

  // 从数据库格式转换回模型
  factory ServerRecord.fromMap(Map<String, dynamic> map) {
    return ServerRecord(
      id: map['id'],
      name: map['name'],
      ip: map['ip'],
      username: map['username'],
      password: map['password'],
      shareName: map['shareName'],
      type: map['type'],
    );
  }
}