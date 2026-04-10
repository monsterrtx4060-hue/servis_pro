import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../utils/service_receipt_pdf.dart';
import 'package:url_launcher/url_launcher.dart';

class TodayServiceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const TodayServiceDetailScreen({super.key, required this.service});

  @override
  State<TodayServiceDetailScreen> createState() =>
      _TodayServiceDetailScreenState();
}

class _TodayServiceDetailScreenState extends State<TodayServiceDetailScreen> {
  late TextEditingController _doneController;
  late TextEditingController _priceController;

  final List<String> _statuses = const [
    'Parça Bekliyor',
    'Tamamlandı',
    'İptal',
  ];

  late String _selectedStatus;

  @override
  void initState() {
    super.initState();

    _doneController = TextEditingController(
      text: (widget.service['done_description'] ?? '').toString(),
    );

    _priceController = TextEditingController(
      text: (widget.service['price'] ?? '').toString(),
    );

    final current = (widget.service['service_status'] ?? 'Parça Bekliyor')
        .toString();

    _selectedStatus = _statuses.contains(current) ? current : 'Parça Bekliyor';
  }

  String _uiDate(String? dbDate) => DatabaseHelper.instance.toUiDate(dbDate);

  // 📞 ARAMA
  Future<void> callCustomer(String phone) async {
    if (phone.isEmpty) return;

    final Uri url = Uri.parse("tel:$phone");

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // 💬 WHATSAPP (SADECE WHATSAPP MESSENGER AÇAR)
  Future<void> sendWhatsApp() async {
    try {
      String phone = (widget.service['phone'] ?? '').toString();

      if (phone.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Telefon numarası yok")));
        return;
      }

      String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');

      if (cleaned.startsWith('0')) {
        cleaned = '9$cleaned';
      }

      final message = Uri.encodeComponent("""
Merhaba ${widget.service['name']},

Servis bilgilendirme:

📅 Tarih: ${_uiDate(widget.service['planned_date']?.toString())}
🔧 Ürün: ${widget.service['product']}
⚠️ Arıza: ${widget.service['problem']}

Bilginize.
""");

      // 👇 SADECE WHATSAPP MESSENGER
      final Uri whatsappUri = Uri.parse(
        "whatsapp://send?phone=$cleaned&text=$message",
      );

      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("WhatsApp açılamadı")));
    }
  }

  Future<void> _save() async {
    final doneText = _doneController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    final serviceId = widget.service['id'] as int;

    await DatabaseHelper.instance.updateServiceComplete(
      serviceId,
      doneText,
      price,
      serviceStatus: _selectedStatus,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Servis kaydı güncellendi")));
  }

  Map<String, dynamic> _currentServiceMap() {
    return {
      ...widget.service,
      'done_description': _doneController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0,
      'service_status': _selectedStatus,
      'planned_date_ui': _uiDate(widget.service['planned_date']?.toString()),
      'created_date_ui': _uiDate(widget.service['date']?.toString()),
    };
  }

  Future<void> _printReceipt() async {
    await ServiceReceiptPdf.printServiceReceipt(_currentServiceMap());
  }

  Future<void> _shareReceipt() async {
    await ServiceReceiptPdf.shareServiceReceipt(_currentServiceMap());

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("PDF paylaşım ekranı açıldı")));
  }

  @override
  void dispose() {
    _doneController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plannedDate = _uiDate(widget.service['planned_date']?.toString());
    final createdDate = _uiDate(widget.service['date']?.toString());

    return Scaffold(
      appBar: AppBar(title: const Text("Servis Detayı")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              "Müşteri Bilgileri",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Text("Ad Soyad: ${widget.service['name'] ?? ''}"),

            // 📞 + 💬 BUTONLAR
            Row(
              children: [
                Expanded(
                  child: Text("Telefon: ${widget.service['phone'] ?? ''}"),
                ),

                // 📞 ARAMA
                IconButton(
                  icon: const Icon(Icons.phone, color: Colors.green),
                  onPressed: () => callCustomer(widget.service['phone'] ?? ''),
                ),

                // 💬 WHATSAPP (LOGO)
                IconButton(
                  icon: Image.asset(
                    'assets/icons/whatsapp.png',
                    width: 26,
                    height: 26,
                  ),
                  onPressed: sendWhatsApp,
                ),
              ],
            ),

            Text("Adres: ${widget.service['address'] ?? ''}"),

            const Divider(height: 30),

            const Text(
              "Arıza Kaydı",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Text("Ürün: ${widget.service['product'] ?? ''}"),
            Text("Arıza: ${widget.service['problem'] ?? ''}"),
            Text("Planlanan Servis Tarihi: $plannedDate"),
            Text("Kayıt Tarihi: $createdDate"),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                labelText: "Servis Durumu",
                border: OutlineInputBorder(),
              ),
              items: _statuses
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),

            const SizedBox(height: 15),

            TextField(
              controller: _doneController,
              decoration: const InputDecoration(
                labelText: "Yapılan İşlem",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 15),

            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: "Ücret (₺)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _save,
              child: const Text("Kaydı Güncelle"),
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: _printReceipt,
              icon: const Icon(Icons.print),
              label: const Text("PDF Önizle / Yazdır"),
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: _shareReceipt,
              icon: const Icon(Icons.share),
              label: const Text("PDF Kaydet / Paylaş"),
            ),
          ],
        ),
      ),
    );
  }
}
