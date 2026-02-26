import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import 'today_service_detail_screen.dart';

class TodayServicesScreen extends StatefulWidget {
  const TodayServicesScreen({super.key});

  @override
  State<TodayServicesScreen> createState() => _TodayServicesScreenState();
}

class _TodayServicesScreenState extends State<TodayServicesScreen> {
  List<Map<String, dynamic>> services = [];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    await DatabaseHelper.instance.processTodayReminders();

    final data = await DatabaseHelper.instance.getTodayServicesWithCustomer();

    if (!mounted) return;
    setState(() {
      services = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    final todayText = DatabaseHelper.instance.toUiDate(
      DatabaseHelper.instance.todayDbDate(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("Günün Servisleri • $todayText"),
        actions: [
          IconButton(
            onPressed: _loadServices,
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: services.isEmpty
          ? const Center(child: Text("Bugün servis yok"))
          : ListView.builder(
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];

                final doneText = (service['done_description'] ?? '')
                    .toString()
                    .trim();
                final priceRaw = service['price'];
                final double price = priceRaw is num
                    ? priceRaw.toDouble()
                    : double.tryParse(priceRaw.toString()) ?? 0;

                final isCompleted = doneText.isNotEmpty && price > 0;

                return Card(
                  color: isCompleted ? Colors.grey.shade200 : null,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text((service['name'] ?? 'Müşteri').toString()),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Ürün: ${(service['product'] ?? '').toString()}"),
                        Text("Arıza: ${(service['problem'] ?? '').toString()}"),
                        Text(
                          "Durum: ${(service['service_status'] ?? 'Açık').toString()}",
                        ),
                      ],
                    ),
                    trailing: isCompleted
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TodayServiceDetailScreen(service: service),
                        ),
                      );
                      await _loadServices();
                    },
                  ),
                );
              },
            ),
    );
  }
}
