import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import 'today_service_detail_screen.dart';

class PartWaitingScreen extends StatefulWidget {
  const PartWaitingScreen({super.key});

  @override
  State<PartWaitingScreen> createState() => _PartWaitingScreenState();
}

class _PartWaitingScreenState extends State<PartWaitingScreen> {
  List<Map<String, dynamic>> services = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DatabaseHelper.instance
        .getWaitingPartsServicesWithCustomer();
    if (!mounted) return;
    setState(() => services = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parça Bekleyenler'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: services.isEmpty
          ? const Center(child: Text('Parça bekleyen servis yok'))
          : ListView.builder(
              itemCount: services.length,
              itemBuilder: (context, i) {
                final s = services[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text((s['name'] ?? 'Müşteri').toString()),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Ürün: ${(s['product'] ?? '').toString()}"),
                        Text("Arıza: ${(s['problem'] ?? '').toString()}"),
                        Text(
                          "Servis Tarihi: ${DatabaseHelper.instance.toUiDate(s['planned_date']?.toString())}",
                        ),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TodayServiceDetailScreen(service: s),
                        ),
                      );
                      await _load(); // durum Tamamlandı/İptal olursa buradan düşer
                    },
                  ),
                );
              },
            ),
    );
  }
}
