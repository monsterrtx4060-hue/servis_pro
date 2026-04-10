import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../services/today_service_detail_screen.dart';
import '../../widgets/service_status_icon.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;
  final String customerName;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  List<Map<String, dynamic>> services = [];
  Map<String, dynamic>? customer;

  DateTime? reminderDate;
  final TextEditingController _reminderNoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await _loadCustomer();
    await _loadServices();
  }

  // 📞 ARAMA
  Future<void> callCustomer(String phone) async {
    if (phone.isEmpty) return;

    final Uri url = Uri.parse("tel:$phone");

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // 💬 WHATSAPP
  Future<void> openWhatsApp(String phone) async {
    if (phone.isEmpty) return;

    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.startsWith('0')) {
      cleaned = '9$cleaned';
    }

    final Uri url = Uri.parse("whatsapp://send?phone=$cleaned");

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _loadCustomer() async {
    final data = await DatabaseHelper.instance.getCustomerById(
      widget.customerId,
    );

    if (!mounted) return;

    setState(() {
      customer = data;
    });
  }

  Future<void> _loadServices() async {
    final data = await DatabaseHelper.instance.getServicesByCustomer(
      widget.customerId,
    );

    for (var s in data) {
      s['name'] = customer?['name'];
      s['phone'] = customer?['phone'];
      s['address'] = customer?['address'];
    }

    if (!mounted) return;

    setState(() {
      services = data;
    });
  }

  // 📅 REMINDER DATE
  Future<void> _selectReminderDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: reminderDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        reminderDate = picked;
      });
    }
  }

  // 💾 REMINDER SAVE
  Future<void> _saveReminder() async {
    await DatabaseHelper.instance.updateCustomerReminder(
      widget.customerId,
      reminderDate: reminderDate == null
          ? null
          : DatabaseHelper.instance.toDbDate(reminderDate!),
      reminderNote: _reminderNoteController.text.trim(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Hatırlatıcı kaydedildi")));

    await _loadCustomer();
  }

  @override
  void dispose() {
    _reminderNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = customer;

    return Scaffold(
      appBar: AppBar(title: Text(widget.customerName)),
      body: Column(
        children: [
          // 📌 CUSTOMER
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: c == null
                  ? const SizedBox()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Ad: ${c['name'] ?? ''}"),

                        Row(
                          children: [
                            Expanded(
                              child: Text("Telefon: ${c['phone'] ?? ''}"),
                            ),

                            IconButton(
                              icon: const Icon(
                                Icons.phone,
                                color: Colors.green,
                              ),
                              onPressed: () => callCustomer(c['phone'] ?? ''),
                            ),

                            IconButton(
                              icon: Image.asset(
                                'assets/icons/whatsapp.png',
                                width: 26,
                              ),
                              onPressed: () => openWhatsApp(c['phone'] ?? ''),
                            ),
                          ],
                        ),

                        Text("Adres: ${c['address'] ?? ''}"),
                      ],
                    ),
            ),
          ),

          // 📌 REMINDER UI
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      reminderDate == null
                          ? "Tarih seçilmedi"
                          : reminderDate.toString(),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _selectReminderDate,
                  ),

                  TextField(
                    controller: _reminderNoteController,
                    decoration: const InputDecoration(
                      labelText: "Not",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: _saveReminder,
                    child: const Text("Kaydet"),
                  ),
                ],
              ),
            ),
          ),

          // 📌 SERVICES
          Expanded(
            child: ListView.builder(
              itemCount: services.length,
              itemBuilder: (context, index) {
                final s = services[index];

                return Card(
                  child: ListTile(
                    title: Text(s['product'] ?? ''),
                    subtitle: Text(s['problem'] ?? ''),
                    trailing: ServiceStatusIcon(status: s['service_status']),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TodayServiceDetailScreen(service: s),
                        ),
                      );

                      await _loadAll();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
