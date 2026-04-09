import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../services/today_service_detail_screen.dart';
import 'add_service_screen.dart';
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

  Future<void> callCustomer(String phone) async {
    final Uri url = Uri.parse("tel:$phone");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Arama başlatılamadı");
    }
  }

  Future<void> _loadCustomer() async {
    final data = await DatabaseHelper.instance.getCustomerById(
      widget.customerId,
    );
    if (data == null) return;

    final reminderRaw = (data['reminder_date'] ?? '').toString().trim();
    reminderDate = reminderRaw.isEmpty ? null : DateTime.tryParse(reminderRaw);

    _reminderNoteController.text = (data['reminder_note'] ?? '').toString();

    if (!mounted) return;

    setState(() {
      customer = data;
    });
  }

  Future<void> _loadServices() async {
    final data = await DatabaseHelper.instance.getServicesByCustomer(
      widget.customerId,
    );

    if (!mounted) return;

    setState(() {
      services = data;
    });
  }

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

  Future<void> _deleteService(int id) async {
    await DatabaseHelper.instance.deleteService(id);
    await _loadServices();
  }

  Future<void> _updateDoneDescription(int serviceId) async {
    final service = services.firstWhere((s) => s['id'] == serviceId);

    final controller = TextEditingController(
      text: (service['done_description'] ?? '').toString(),
    );

    final updated = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Yapılan İşlem Güncelle"),
        content: TextField(controller: controller, maxLines: 3),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );

    if (updated != null) {
      await DatabaseHelper.instance.updateServiceDoneDescription(
        serviceId,
        updated,
      );
      await _loadServices();
    }
  }

  void _showServiceOptions(int serviceId) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("İşlem Seçin"),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _updateDoneDescription(serviceId);
            },
            child: const Text("Yapılan İşlemi Düzenle"),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _deleteService(serviceId);
            },
            child: const Text(
              "Servisi Sil",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
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
          // ================= CUSTOMER INFO =================
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: c == null
                  ? const SizedBox()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Müşteri Bilgileri",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text("Ad Soyad: ${c['name'] ?? ''}"),

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
                              onPressed: () {
                                final phone = (c['phone'] ?? '').toString();
                                if (phone.isNotEmpty) {
                                  callCustomer(phone);
                                }
                              },
                            ),
                          ],
                        ),

                        Text("Adres: ${c['address'] ?? ''}"),
                      ],
                    ),
            ),
          ),

          // ================= REMINDER =================
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Bakım Hatırlatıcı",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),

                  const SizedBox(height: 8),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      reminderDate == null
                          ? "Tarih Seçilmedi"
                          : DatabaseHelper.instance.toUiDate(
                              DatabaseHelper.instance.toDbDate(reminderDate!),
                            ),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _selectReminderDate,
                  ),

                  TextField(
                    controller: _reminderNoteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Hatırlatma Notu",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveReminder,
                      child: const Text("Kaydet"),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ================= NEW SERVICE =================
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final added = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AddServiceScreen(customerId: widget.customerId),
                    ),
                  );

                  if (added == true) {
                    await _loadServices();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text("Yeni Arıza Kayıt"),
              ),
            ),
          ),

          const Divider(height: 1),

          // ================= SERVICES =================
          Expanded(
            child: services.isEmpty
                ? const Center(child: Text("Henüz servis kaydı yok"))
                : ListView.builder(
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final service = services[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          title: Text(service['product'] ?? ''),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Arıza: ${service['problem'] ?? ''}"),
                              Text(
                                "Servis Tarihi: ${DatabaseHelper.instance.toUiDate(service['planned_date']?.toString())}",
                              ),
                              Text("Durum: ${service['service_status'] ?? ''}"),
                              Text(
                                "İşlem: ${(service['done_description'] ?? '').toString().isEmpty ? 'Yok' : service['done_description']}",
                              ),
                              Text("Ücret: ${service['price'] ?? 0} ₺"),
                            ],
                          ),
                          trailing: ServiceStatusIcon(
                            status: service['service_status'],
                          ),
                          onLongPress: () => _showServiceOptions(service['id']),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TodayServiceDetailScreen(
                                  service: {
                                    ...service,
                                    'name': c?['name'],
                                    'phone': c?['phone'],
                                    'address': c?['address'],
                                  },
                                ),
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
