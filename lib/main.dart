import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:metadata_fetch/metadata_fetch.dart';

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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SavedVideosScreen(),
    );
  }
}

class SavedVideosScreen extends StatefulWidget {
  const SavedVideosScreen({super.key});

  @override
  State<SavedVideosScreen> createState() => _SavedVideosScreenState();
}

class _SavedVideosScreenState extends State<SavedVideosScreen> {
  late final Box _videosBox;

  @override
  void initState() {
    super.initState();
    _videosBox = Hive.box('videos_box');

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

  Future<void> _saveVideoData(String url) async {
    var data = await MetadataFetch.extract(url);

    Map<String, String> videoInfo = {
      "title": data?.title ?? "فيديو بدون عنوان",
      "image": data?.image ?? "",
      "url": url,
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
      ),
      body: ValueListenableBuilder(
        valueListenable: _videosBox.listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'لا توجد فيديوهات محفوظة بعد. جربي المشاركة من أي تطبيق!',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              var video = box.getAt(index);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  leading: video['image'] != ""
                      ? Image.network(video['image'], width: 60, fit: BoxFit.cover, errorBuilder: (__, _, ___) => const Icon(Icons.video_library, size: 40))
                      : const Icon(Icons.video_library, size: 40),
                  title: Text(video['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(video['url'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      box.deleteAt(index);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
