import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import 'package:share_plus/share_plus.dart';

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yedekleme")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.upload),
              label: const Text("Veriyi Yedekle"),
              onPressed: () async {
                final path = await DatabaseHelper.instance.exportDatabase();

                if (path == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Yedek oluşturulamadı")),
                  );
                  return;
                }

                await Share.shareXFiles([XFile(path)]);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Yedek oluşturuldu")),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text("Yedekten Geri Yükle"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final ok = await DatabaseHelper.instance.importDatabase();

                if (!ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Geri yükleme başarısız")),
                  );
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Geri yüklendi. Uygulamayı kapatıp tekrar açın.",
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
