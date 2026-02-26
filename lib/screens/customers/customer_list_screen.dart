import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import 'customer_detail_screen.dart';
import '../services/today_services_screen.dart';
import 'add_customer_screen.dart';
import 'edit_customer_screen.dart';
import '../settings/backup_screen.dart';
import '../services/part_waiting_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> customers = [];

  @override
  void initState() {
    super.initState();
    _checkReminders();
  }

  Future<void> _checkReminders() async {
    await DatabaseHelper.instance.processTodayReminders();
  }

  Future<void> _searchCustomer() async {
    final text = _searchController.text.trim();

    if (text.isEmpty) {
      setState(() {
        customers = [];
      });
      return;
    }

    final results = await DatabaseHelper.instance.searchCustomerByPhone(text);

    if (!mounted) return;
    setState(() {
      customers = results;
    });
  }

  Future<void> _showCustomerOptions(Map<String, dynamic> customer) async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Müşteriyi Düzenle'),
                onTap: () async {
                  Navigator.pop(context);

                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditCustomerScreen(
                        id: customer['id'] as int,
                        name: (customer['name'] ?? '').toString(),
                        phone: (customer['phone'] ?? '').toString(),
                        address: (customer['address'] ?? '').toString(),
                      ),
                    ),
                  );

                  if (updated == true) {
                    await _searchCustomer();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Müşteriyi Sil',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Müşteriyi Sil'),
                      content: const Text(
                        'Bu müşteri ve tüm servis kayıtları silinsin mi?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('İptal'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Sil'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await DatabaseHelper.instance.deleteCustomer(
                      customer['id'] as int,
                    );

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Müşteri silindi')),
                    );

                    await _searchCustomer();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openAddCustomer() async {
    final added = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
    );

    if (added == true) {
      await _searchCustomer();
    }
  }

  Future<void> _openTodayServices() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TodayServicesScreen()),
    );

    await _checkReminders();
    await _searchCustomer();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Servis Otomasyonu"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BackupScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openAddCustomer,
                child: const Text("Yeni Müşteri Kayıt"),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _searchController,
              keyboardType: TextInputType.phone,
              onSubmitted: (_) => _searchCustomer(),
              decoration: InputDecoration(
                labelText: "Telefon ile Ara",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchCustomer,
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openTodayServices,
                child: const Text("Günün Servisleri"),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PartWaitingScreen(),
                    ),
                  );
                  await _checkReminders();
                  await _searchCustomer();
                },
                child: const Text("Parça Bekleyenler"),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: customers.isEmpty
                  ? const SizedBox()
                  : ListView.builder(
                      itemCount: customers.length,
                      itemBuilder: (context, index) {
                        final customer = customers[index];

                        return Card(
                          child: ListTile(
                            title: Text((customer['name'] ?? '').toString()),
                            subtitle: Text(
                              (customer['phone'] ?? '').toString(),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CustomerDetailScreen(
                                    customerId: customer['id'] as int,
                                    customerName: (customer['name'] ?? '')
                                        .toString(),
                                  ),
                                ),
                              );

                              await _searchCustomer();
                            },
                            onLongPress: () => _showCustomerOptions(customer),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
