import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:pro_video_editor/pro_video_editor.dart';
import 'package:pro_video_editor_example/features/export/video_export_page.dart';

import 'features/thumbnail/thumbnail_example_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  runApp(const MyApp());
}

/// The root widget of the application.
///
/// This widget sets up the app's state and initial configuration.
/// It is typically used to initialize themes, routes, and global settings.
class MyApp extends StatelessWidget {
  /// Creates the root [MyApp] widget.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade800,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
    );
  }
}

/// The main landing page of the application.
///
/// This widget serves as the entry point after launching the app,
/// typically containing the primary UI or navigation structure.
class HomePage extends StatefulWidget {
  /// Creates the [HomePage] widget.
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await VideoUtilsService.instance.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pro Video Editor')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.image_outlined),
                  title: const Text('Thumbnail generation'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ThumbnailExamplePage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.import_export_rounded),
                  title: const Text('Video Export'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const VideoExportPage()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
          Center(child: Text('Running on: $_platformVersion\n')),
        ],
      ),
    );
  }
}
