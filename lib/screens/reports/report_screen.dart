import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../widgets/service_status_icon.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime selectedDay = DateTime.now();

  List<Map<String, dynamic>> completedOfDay = [];
  double dayTotal = 0;

  int monthCount = 0;
  double monthTotal = 0;

  int yearCount = 0;
  double yearTotal = 0;

  int waitingPartsCount = 0;

  int monthCanceledCount = 0;
  int yearCanceledCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDay,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() => selectedDay = picked);
      await _loadAll();
    }
  }

  Future<void> _loadAll() async {
    final db = DatabaseHelper.instance;

    final dayDb = db.toDbDate(selectedDay);

    // Günlük tamamlananlar
    final list = await db.getCompletedServicesByCompletedDate(dayDb);
    double total = 0;
    for (final s in list) {
      final v = s['price'];
      final price = v is num
          ? v.toDouble()
          : double.tryParse(v.toString()) ?? 0;
      total += price;
    }

    // Aylık / Yıllık özet
    final now = DateTime.now();

    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final yearStart = DateTime(now.year, 1, 1);
    final yearEnd = DateTime(now.year, 12, 31);

    final monthSum = await db.getSummaryByCompletedDateRange(
      db.toDbDate(monthStart),
      db.toDbDate(monthEnd),
    );

    final yearSum = await db.getSummaryByCompletedDateRange(
      db.toDbDate(yearStart),
      db.toDbDate(yearEnd),
    );

    final waitingCount = await db.getWaitingPartsCount();

    final monthCanceled = await db.getCanceledCountByPlannedDateRange(
      db.toDbDate(monthStart),
      db.toDbDate(monthEnd),
    );

    final yearCanceled = await db.getCanceledCountByPlannedDateRange(
      db.toDbDate(yearStart),
      db.toDbDate(yearEnd),
    );

    int asInt(dynamic v) => v is int ? v : int.tryParse(v.toString()) ?? 0;
    double asDouble(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0;

    if (!mounted) return;
    setState(() {
      completedOfDay = list;
      dayTotal = total;

      monthCount = asInt(monthSum['count']);
      monthTotal = asDouble(monthSum['total']);

      yearCount = asInt(yearSum['count']);
      yearTotal = asDouble(yearSum['total']);

      waitingPartsCount = waitingCount;
      monthCanceledCount = monthCanceled;
      yearCanceledCount = yearCanceled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseHelper.instance;
    final dayText = db.toUiDate(db.toDbDate(selectedDay));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporlama'),
        actions: [
          IconButton(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: ListTile(
                title: Text('Gün Seç: $dayText'),
                subtitle: const Text(
                  'O gün “Tamamlandı” olan servisler ve gelir',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDay,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _statCard(
                    title: 'Günlük Gelir',
                    value: '${dayTotal.toStringAsFixed(2)} ₺',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    title: 'Günlük Fiş',
                    value: '${completedOfDay.length}',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _statCard(title: 'Bu Ay Fiş', value: '$monthCount'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    title: 'Bu Ay Kazanç',
                    value: '${monthTotal.toStringAsFixed(2)} ₺',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _statCard(
                    title: 'Bu Ay İptal',
                    value: '$monthCanceledCount',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    title: 'Aktif Parça Bekleyen',
                    value: '$waitingPartsCount',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _statCard(title: 'Bu Yıl Fiş', value: '$yearCount'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    title: 'Bu Yıl Kazanç',
                    value: '${yearTotal.toStringAsFixed(2)} ₺',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _statCard(
                    title: 'Bu Yıl İptal',
                    value: '$yearCanceledCount',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    title: 'Aktif Parça Bekleyen',
                    value: '$waitingPartsCount',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Text(
              'Seçilen Günün Tamamlanan Servisleri',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (completedOfDay.isEmpty)
              const Center(child: Text('Bu gün tamamlanan servis yok'))
            else
              ...completedOfDay.map((s) {
                final priceRaw = s['price'];
                final price = priceRaw is num
                    ? priceRaw.toDouble()
                    : double.tryParse(priceRaw.toString()) ?? 0;

                final status = (s['service_status'] ?? '').toString();

                return Card(
                  child: ListTile(
                    title: Text((s['name'] ?? 'Müşteri').toString()),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ürün: ${(s['product'] ?? '').toString()}'),
                        Text(
                          'İşlem: ${(s['done_description'] ?? '').toString()}',
                        ),
                        Text('Ücret: ${price.toStringAsFixed(2)} ₺'),
                      ],
                    ),

                    // ✅ SAĞDA DURUM İKONU
                    trailing: ServiceStatusIcon(status: status),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _statCard({required String title, required String value}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
