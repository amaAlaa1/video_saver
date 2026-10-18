import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:video_player/video_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('videos_box');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VideoCypher',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const SavedVideosScreen(),
    );
  }
}

class SavedVideosScreen extends StatefulWidget {
  const SavedVideosScreen({super.key});

  @override
  State<SavedVideosScreen> createState() => _SavedVideosScreenState();
}

class _SavedVideosScreenState extends State<SavedVideosScreen> {
  final _videosBox = Hive.box('videos_box');

  @override
  void initState() {
    super.initState();

    // استقبال الميديا المشاركة (فيديوهات أو روابط)
    ReceiveSharingIntent.instance.getMediaStream().listen((value) async {
      if (value.isNotEmpty) {
        await _saveVideoData(value.first.path);
      }
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((value) async {
      if (value.isNotEmpty) {
        await _saveVideoData(value.first.path);
      }
    });
  }

  Future<void> _saveVideoData(String pathOrUrl) async {
    String title = "فيديو بدون عنوان";
    String image = "";

    // إذا كان الرابط رابط ويب نحاول جلب معلوماته المصغرة
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      var data = await MetadataFetch.extract(pathOrUrl);
      title = data?.title ?? "فيديو من الويب";
      image = data?.image ?? "";
    } else {
      // إذا كان ملفاً محلياً
      title = pathOrUrl.split('/').last;
    }

    Map<String, String> videoInfo = {
      "title": title,
      "image": image,
      "url": pathOrUrl,
    };

    await _videosBox.add(videoInfo);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مكتبة الفيديوهات المحفوظة'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder(
        valueListenable: _videosBox.listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return const Center(
              
