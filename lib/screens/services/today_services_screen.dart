import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import 'today_service_detail_screen.dart';
import '../../widgets/service_status_icon.dart';

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

  bool _isOverdue(String? plannedDate) {
    if (plannedDate == null) return false;

    final date = DateTime.tryParse(plannedDate);
    if (date == null) return false;

    final today = DateTime.now();
    final onlyToday = DateTime(today.year, today.month, today.day);

    return date.isBefore(onlyToday);
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
          IconButton(onPressed: _loadServices, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: services.isEmpty
          ? const Center(child: Text("Bugün servis yok"))
          : ListView.builder(
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];

                final status = (service['service_status'] ?? 'Parça Bekliyor')
                    .toString()
                    .trim();

                final isCompleted = status == 'Tamamlandı';
                final overdue = _isOverdue(service['planned_date']?.toString());

                return Card(
                  color: isCompleted
                      ? Colors.grey.shade200
                      : overdue
                      ? Colors.red.shade50
                      : null,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            (service['name'] ?? 'Müşteri').toString(),
                          ),
                        ),
                        if (overdue && !isCompleted)
                          const Icon(
                            Icons.warning,
                            color: Colors.red,
                            size: 20,
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Ürün: ${(service['product'] ?? '').toString()}"),
                        Text("Arıza: ${(service['problem'] ?? '').toString()}"),
                        Text("Durum: $status"),

                        if (overdue && !isCompleted)
                          const Text(
                            "⚠ Gecikmiş servis",
                            style: TextStyle(color: Colors.red),
                          ),
                      ],
                    ),
                    trailing: ServiceStatusIcon(
                      status: service['service_status']?.toString(),
                    ),
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
