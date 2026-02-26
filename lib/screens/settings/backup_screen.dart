import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import 'package:share_plus/share_plus.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  Future<void> _export() async {
    final path = await DatabaseHelper.instance.exportDatabase();

    if (!mounted) return;

    if (path == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Yedek oluşturulamadı")));
      return;
    }

    await Share.shareXFiles([XFile(path)]);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Yedek oluşturuldu")));
  }

  Future<void> _import() async {
    final ok = await DatabaseHelper.instance.importDatabase();

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Geri yükleme başarısız")));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Geri yüklendi. Uygulamayı kapatıp tekrar açın."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yedekleme")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.upload),
                label: const Text("Veriyi Yedekle"),
                onPressed: _export,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text("Yedekten Geri Yükle"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _import,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
