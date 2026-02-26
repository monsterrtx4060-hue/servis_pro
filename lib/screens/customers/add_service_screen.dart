import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';

class AddServiceScreen extends StatefulWidget {
  final int customerId;

  const AddServiceScreen({super.key, required this.customerId});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _productController = TextEditingController();
  final _problemController = TextEditingController();
  final _priceController = TextEditingController();

  DateTime selectedDate = DateTime.now();

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _saveService() async {
    final product = _productController.text.trim();
    final problem = _problemController.text.trim();
    final priceText = _priceController.text.trim();

    if (product.isEmpty || problem.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen ürün ve arıza bilgisi girin')),
      );
      return;
    }

    await DatabaseHelper.instance.insertService({
      'customerId': widget.customerId,
      'product': product,
      'problem': problem,
      'price': double.tryParse(priceText) ?? 0,
      'done_description': '',
      'planned_date': DatabaseHelper.instance.toDbDate(selectedDate),
      'date': DatabaseHelper.instance.todayDbDate(),
      'service_status': 'Açık',
    });

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _productController.dispose();
    _problemController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uiDate = DatabaseHelper.instance.toUiDate(
      DatabaseHelper.instance.toDbDate(selectedDate),
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Arıza Kayıt")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _productController,
              decoration: const InputDecoration(
                labelText: "Ürün",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _problemController,
              decoration: const InputDecoration(
                labelText: "Arıza",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: "Ücret (opsiyonel)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: Text("Servis Tarihi: $uiDate"),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveService,
                child: const Text("Kaydet"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
