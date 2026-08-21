import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:metadata_fetch/metadata_fetch.dart';

void main() async {
  // تهيئة قاعدة البيانات المحلية قبل تشغيل التطبيق
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('videos_box'); // فتح الصندوق لتخزين البيانات

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
  _SavedVideosScreenState createState() => _SavedVideosScreenState();
}

class _SavedVideosScreenState extends State<SavedVideosScreen> {
  final _videosBox = Hive.box('videos_box');

  @override
  void initState() {
    super.initState();
    
    // استقبال الروابط وحفظها فوراً في قاعدة البيانات
    ReceiveSharingIntent.instance.getMediaStream().listen((value) async {
      if (value.isNotEmpty) {
        await _saveVideoData(value.first.path);
      }
    });
  }

  // دالة لجلب البيانات وحفظها في Hive
  Future<void> _saveVideoData(String url) async {
    var data = await MetadataFetch.extract(url);
    
    Map<String, String> videoInfo = {
      "title": data?.title ?? "فيديو بدون عنوان",
      "image": data?.image ?? "",
      "url": url,
    };

    // حفظ البيانات في الصندوق مع مفتاح فريد
    await _videosBox.add(videoInfo);
    setState(() {}); // تحديث الشاشة لتظهر الفيديو الجديد فوراً
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مكتبة الفيديوهات الدائمة'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ValueListenableBuilder(
        valueListenable: _videosBox.listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Text('لا توجد فيديوهات محفوظة بعد. جربي المشاركة من أي تطبيق!'),
            );
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              var video = box.getAt(index);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  leading: video['image'] != '' 
                      ? Image.network(video['image'], width: 60, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.video_library))
                      : const Icon(Icons.video_library, size: 40),
                  title: Text(video['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(video['url'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // حذف الفيديو من القاعدة نهائياً
                      box.deleteAt(index);
                    },
                  ),
                  onTap: () {
                    // الانتقال لشاشة المشاهدة عند الضغط على الفيديو
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoPlayerScreen(url: video['url']),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// شاشة عرض أو تشغيل الفيديو
class VideoPlayerScreen extends StatelessWidget {
  final String url;
  const VideoPlayerScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("مشاهدة الفيديو")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("رابط الفيديو:\n$url", textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        ),
      ), 
    );
  }
}
