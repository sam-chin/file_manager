import 'package:flutter/material.dart';
import '../models/server_record.dart';
import '../services/database_service.dart';

class AddServerPage extends StatefulWidget {
  const AddServerPage({super.key});

  @override
  State<AddServerPage> createState() => _AddServerPageState();
}

class _AddServerPageState extends State<AddServerPage> {
  final _formKey = GlobalKey<FormState>();
  ServerType _type = ServerType.smb;
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _shareController = TextEditingController();
  final _domainController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _shareController.dispose();
    _domainController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveServer() async {
    if (_formKey.currentState!.validate()) {
      final server = ServerRecord()
        ..type = _type
        ..name = _nameController.text
        ..host = _hostController.text
        ..port = int.tryParse(_portController.text) ?? (_type == ServerType.smb ? 445 : 21)
        ..share = _shareController.text.isEmpty ? null : _shareController.text
        ..domain = _domainController.text.isEmpty ? null : _domainController.text
        ..username = _usernameController.text.isEmpty ? null : _usernameController.text
        ..encryptedPassword = _passwordController.text.isEmpty ? null : _passwordController.text
        ..createdAt = DateTime.now();

      await DatabaseService.saveServer(server);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加服务器'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<ServerType>(
                segments: const [
                  ButtonSegment(
                    value: ServerType.smb,
                    icon: Icon(Icons.folder_shared),
                    label: Text('SMB'),
                  ),
                  ButtonSegment(
                    value: ServerType.ftp,
                    icon: Icon(Icons.cloud),
                    label: Text('FTP'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (selection) {
                  setState(() {
                    _type = selection.first;
                  });
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '服务器名称',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入服务器名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hostController,
                decoration: const InputDecoration(
                  labelText: '主机地址',
                  hintText: '192.168.1.100',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入主机地址';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _portController,
                decoration: InputDecoration(
                  labelText: '端口',
                  hintText: _type == ServerType.smb ? '445' : '21',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              if (_type == ServerType.smb) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _shareController,
                  decoration: const InputDecoration(
                    labelText: '共享文件夹',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _domainController,
                  decoration: const InputDecoration(
                    labelText: '域 (可选)',
                    hintText: 'WORKGROUP',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '用户名 (可选)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: '密码 (可选)',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveServer,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
