import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'server_list_page.dart';
import 'add_server_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('媒体管理器'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const ServerListPage(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddServerPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
