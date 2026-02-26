import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../services/today_service_detail_screen.dart';
import 'add_service_screen.dart';

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
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Yapılan işlemi girin"),
          maxLines: 3,
        ),
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
          // Müşteri bilgileri
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: c == null
                  ? const SizedBox.shrink()
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
                        Text("Ad Soyad: ${(c['name'] ?? '').toString()}"),
                        Text("Telefon: ${(c['phone'] ?? '').toString()}"),
                        Text("Adres: ${(c['address'] ?? '').toString()}"),
                      ],
                    ),
            ),
          ),

          // Hatırlatıcı
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
                          : "Tarih: ${DatabaseHelper.instance.toUiDate(DatabaseHelper.instance.toDbDate(reminderDate!))}",
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _selectReminderDate,
                  ),
                  TextField(
                    controller: _reminderNoteController,
                    decoration: const InputDecoration(
                      labelText: "Hatırlatma Notu",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveReminder,
                      child: const Text("Hatırlatıcıyı Kaydet"),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Yeni arıza kayıt butonu
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final added = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
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

          // Eski servis kayıtları
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
                          title: Text((service['product'] ?? '').toString()),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Arıza: ${(service['problem'] ?? '').toString()}",
                              ),
                              Text(
                                "Servis Tarihi: ${DatabaseHelper.instance.toUiDate(service['planned_date']?.toString())}",
                              ),
                              Text(
                                "Durum: ${(service['service_status'] ?? 'Açık').toString()}",
                              ),
                              Text(
                                "Yapılan İşlem: ${((service['done_description'] ?? '').toString().trim().isEmpty) ? 'Henüz yapılmadı' : service['done_description']}",
                              ),
                              Text(
                                "Ücret: ${(service['price'] ?? 0).toString()} ₺",
                              ),
                            ],
                          ),
                          onTap: () async {
                            final detailMap = {
                              'id': service['id'],
                              'customerId': service['customerId'],
                              'product': service['product'],
                              'problem': service['problem'],
                              'price': service['price'],
                              'done_description': service['done_description'],
                              'planned_date': service['planned_date'],
                              'date': service['date'],
                              'service_status': service['service_status'],
                              'name': (customer?['name'] ?? ''),
                              'phone': (customer?['phone'] ?? ''),
                              'address': (customer?['address'] ?? ''),
                              'reminder_note':
                                  (customer?['reminder_note'] ?? ''),
                            };

                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TodayServiceDetailScreen(
                                  service: detailMap,
                                ),
                              ),
                            );

                            await _loadAll();
                          },
                          onLongPress: () =>
                              _showServiceOptions(service['id'] as int),
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
