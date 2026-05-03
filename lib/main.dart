// lib/main.dart
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart'; // 必须导入
import 'services/database_service.dart';
import 'ui/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // media_kit 必须在 runApp 之前初始化，否则播放时崩溃
  MediaKit.ensureInitialized();

  // 初始化 sqflite 数据库
  await DatabaseService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '媒体管理器',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
