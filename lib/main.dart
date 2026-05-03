import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'services/app_service.dart';
import 'pages/home_page.dart';
import 'widgets/global_media_viewer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await AppService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '极简媒体管家',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            const Positioned.fill(
              child: GlobalMediaViewer(),
            ),
          ],
        );
      },
      home: const HomePage(),
    );
  }
}
