class ServerRecord {
  int? id;
  String name;
  String ip;
  String username;
  String password;
  String? shareName;
  final String type;
  final int port;

  ServerRecord({
    this.id,
    required this.name,
    required this.ip,
    required this.username,
    required this.password,
    this.shareName,
    this.type = 'SMB',
    this.port = 445,
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
      'port': port,
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
      port: map['port'] != null ? int.tryParse(map['port'].toString()) ?? 445 : 445,
    );
  }
}
