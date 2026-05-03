class ServerRecord {
  int? id;
  String name;
  String ip;
  String username;
  String password;
  String? shareName;
  final String type;

  ServerRecord({
    this.id,
    required this.name,
    required this.ip,
    required this.username,
    required this.password,
    this.shareName,
    this.type = 'SMB',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'ip': ip,
      'username': username,
      'password': password,
      'shareName': shareName ?? "",
      'type': type,
    };
  }

  factory ServerRecord.fromMap(Map<String, dynamic> map) {
    return ServerRecord(
      id: map['id'],
      name: map['name'],
      ip: map['ip'],
      username: map['username'],
      password: map['password'],
      shareName: map['shareName'],
      type: map['type'] ?? 'SMB',
    );
  }
}
