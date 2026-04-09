import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';
import '../../core/database/database_helper.dart';
import '../customers/customer_detail_screen.dart';
import '../customers/add_customer_screen.dart';

class RecentCallsScreen extends StatefulWidget {
  const RecentCallsScreen({super.key});

  @override
  State<RecentCallsScreen> createState() => _RecentCallsScreenState();
}

class _RecentCallsScreenState extends State<RecentCallsScreen> {
  List<CallLogEntry> calls = [];

  Map<String, String> nameCache = {}; // numara -> isim cache

  @override
  void initState() {
    super.initState();
    loadCalls();
  }

  Future<void> loadCalls() async {
    Iterable<CallLogEntry> entries = await CallLog.get();

    final limited = entries.take(20).toList(); // 👈 sadece son 20

    // isimleri önceden çek
    for (final c in limited) {
      final phone = c.number ?? '';
      if (phone.isEmpty) continue;

      final result = await DatabaseHelper.instance.searchCustomerByPhone(phone);

      if (result.isNotEmpty) {
        nameCache[phone] = result.first['name'] ?? phone;
      } else {
        nameCache[phone] = phone;
      }
    }

    if (!mounted) return;

    setState(() {
      calls = limited;
    });
  }

  Future<void> onCallTap(String phone) async {
    final results = await DatabaseHelper.instance.searchCustomerByPhone(phone);

    if (!mounted) return;

    if (results.isNotEmpty) {
      final customer = results.first;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerDetailScreen(
            customerId: customer['id'],
            customerName: customer['name'],
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddCustomerScreen(phone: phone)),
      );
    }
  }

  String formatDate(int? timestamp) {
    if (timestamp == null) return "-";
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${dt.day}.${dt.month} ${dt.hour}:${dt.minute}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Son Aramalar")),
      body: calls.isEmpty
          ? const Center(child: Text("Kayıt bulunamadı"))
          : ListView.builder(
              itemCount: calls.length,
              itemBuilder: (context, index) {
                final c = calls[index];
                final phone = c.number ?? "-";

                final displayName = nameCache[phone] ?? phone;

                return ListTile(
                  leading: const Icon(Icons.phone),
                  title: Text(displayName),
                  subtitle: Text(phone),
                  onTap: () => onCallTap(phone),
                );
              },
            ),
    );
  }
}
