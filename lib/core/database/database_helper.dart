import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // =========================
  // DB INIT / CLOSE
  // =========================

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('servis.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT,
        reminder_date TEXT,
        reminder_note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE services(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER,
        product TEXT,
        problem TEXT,
        price REAL DEFAULT 0,
        done_description TEXT DEFAULT '',
        planned_date TEXT,
        date TEXT,
        service_status TEXT DEFAULT 'Parça Bekliyor',
        completed_date TEXT
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE services ADD COLUMN done_description TEXT DEFAULT ''",
      );
    }

    if (oldVersion < 3) {
      await db.execute("ALTER TABLE services ADD COLUMN planned_date TEXT");
    }

    if (oldVersion < 4) {
      await db.execute("ALTER TABLE customers ADD COLUMN reminder_date TEXT");
      await db.execute("ALTER TABLE customers ADD COLUMN reminder_note TEXT");
    }

    if (oldVersion < 5) {
      // Eski sürümden gelen status kolonu (eski default 'Açık' olabilir)
      await db.execute(
        "ALTER TABLE services ADD COLUMN service_status TEXT DEFAULT 'Açık'",
      );
    }

    // v7: completed_date + status normalize
    if (oldVersion < 7) {
      // completed_date kolonu yoksa ekle
      try {
        await db.execute("ALTER TABLE services ADD COLUMN completed_date TEXT");
      } catch (_) {
        // zaten varsa geç
      }

      // Status'leri sadece 3 tipe indir
      await db.execute("""
        UPDATE services
        SET service_status = 'Parça Bekliyor'
        WHERE service_status IS NULL
           OR TRIM(service_status) = ''
           OR TRIM(service_status) NOT IN ('Parça Bekliyor','Tamamlandı','İptal')
      """);

      // Tamamlandı olup completed_date boş olanlara planned_date yaz (tahmini)
      await db.execute("""
        UPDATE services
        SET completed_date = planned_date
        WHERE TRIM(service_status) = 'Tamamlandı'
          AND (completed_date IS NULL OR TRIM(completed_date) = '')
      """);
    }
  }

  // =========================
  // BACKUP / RESTORE
  // =========================

  Future<String?> exportDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final originalPath = join(dbPath, 'servis.db');
      final originalFile = File(originalPath);

      if (!await originalFile.exists()) return null;

      final dir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();

      // Saniye + milisaniye ekli -> üstüne yazma olmaz
      final backupName =
          'servis_backup_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}_'
          '${now.millisecond.toString().padLeft(3, '0')}.db';

      final backupPath = join(dir.path, backupName);
      await originalFile.copy(backupPath);

      return backupPath;
    } catch (_) {
      return null;
    }
  }

  Future<bool> importDatabase() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Geri yüklenecek yedeği seç',
        type: FileType.any,
        allowMultiple: false,
        withData: false,
      );

      if (result == null || result.files.single.path == null) return false;

      final pickedPath = result.files.single.path!;
      if (!pickedPath.toLowerCase().endsWith('.db')) return false;

      final backupFile = File(pickedPath);
      if (!await backupFile.exists()) return false;

      await closeDatabase();

      final dbPath = await getDatabasesPath();
      final originalPath = join(dbPath, 'servis.db');
      final originalFile = File(originalPath);

      if (await originalFile.exists()) {
        // güvenlik yedeği
        await originalFile.copy('$originalPath.before_restore');
        await originalFile.delete();
      }

      await backupFile.copy(originalPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  // =========================
  // TARİH YARDIMCILARI
  // =========================

  /// DB formatı: yyyy-MM-dd
  String todayDbDate() {
    final now = DateTime.now();
    return _toDbDate(now);
  }

  String toDbDate(DateTime dt) => _toDbDate(dt);

  String _toDbDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// UI formatı: dd.MM.yyyy
  String toUiDate(String? dbDate) {
    if (dbDate == null || dbDate.trim().isEmpty) return '-';

    try {
      final dt = DateTime.parse(dbDate);
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year.toString();
      return '$d.$m.$y';
    } catch (_) {
      return dbDate;
    }
  }

  // =========================
  // CUSTOMER
  // =========================

  Future<int> insertCustomer(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('customers', row);
  }

  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    final db = await database;
    return await db.query('customers', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> searchCustomerByPhone(String phone) async {
    final db = await database;
    return await db.query(
      'customers',
      where: 'phone LIKE ?',
      whereArgs: ['%$phone%'],
      orderBy: 'id DESC',
    );
  }

  Future<Map<String, dynamic>?> getCustomerById(int customerId) async {
    final db = await database;
    final result = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [customerId],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  Future<int> updateCustomer(
    int id,
    String name,
    String phone,
    String address,
  ) async {
    final db = await database;
    return await db.update(
      'customers',
      {'name': name, 'phone': phone, 'address': address},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateCustomerReminder(
    int customerId, {
    String? reminderDate,
    String? reminderNote,
  }) async {
    final db = await database;
    return await db.update(
      'customers',
      {'reminder_date': reminderDate, 'reminder_note': reminderNote},
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    await db.delete('services', where: 'customerId = ?', whereArgs: [id]);
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // =========================
  // SERVICES
  // =========================

  Future<int> insertService(Map<String, dynamic> row) async {
    final db = await database;
    final data = Map<String, dynamic>.from(row);

    data['done_description'] = (data['done_description'] ?? '').toString();
    data['service_status'] = (data['service_status'] ?? 'Parça Bekliyor')
        .toString();

    if (data['planned_date'] == null ||
        data['planned_date'].toString().isEmpty) {
      data['planned_date'] = todayDbDate();
    }
    if (data['date'] == null || data['date'].toString().isEmpty) {
      data['date'] = todayDbDate();
    }

    return await db.insert('services', data);
  }

  Future<List<Map<String, dynamic>>> getServicesByCustomer(
    int customerId,
  ) async {
    final db = await database;
    return await db.query(
      'services',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getTodayServices(String dbDate) async {
    final db = await database;
    return await db.query(
      'services',
      where: 'planned_date = ?',
      whereArgs: [dbDate],
      orderBy: 'id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getTodayServicesWithCustomer({
    String? dbDate,
  }) async {
    final db = await database;
    final targetDate = dbDate ?? todayDbDate();

    final result = await db.rawQuery(
      '''
      SELECT
        s.id,
        s.customerId,
        s.product,
        s.problem,
        s.price,
        s.done_description,
        s.planned_date,
        s.date,
        s.service_status,
        s.completed_date,
        c.name,
        c.phone,
        c.address,
        c.reminder_note
      FROM services s
      LEFT JOIN customers c ON s.customerId = c.id
      WHERE s.planned_date = ?
      ORDER BY s.id DESC
      ''',
      [targetDate],
    );

    return result;
  }

  Future<int> deleteService(int id) async {
    final db = await database;
    return await db.delete('services', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateServiceDoneDescription(
    int serviceId,
    String description,
  ) async {
    final db = await database;
    return await db.update(
      'services',
      {'done_description': description},
      where: 'id = ?',
      whereArgs: [serviceId],
    );
  }

  /// Detay ekranındaki "Kaydı Güncelle" butonu bunu çağırıyor (durum + ücret + yapılan işlem)
  Future<int> updateServiceComplete(
    int serviceId,
    String doneDescription,
    double price, {
    String? serviceStatus,
  }) async {
    final db = await database;

    final values = <String, dynamic>{
      'done_description': doneDescription,
      'price': price,
    };

    if (serviceStatus != null) {
      values['service_status'] = serviceStatus;

      if (serviceStatus == 'Tamamlandı') {
        values['completed_date'] = todayDbDate();
      } else {
        values['completed_date'] = null;
      }
    }

    return await db.update(
      'services',
      values,
      where: 'id = ?',
      whereArgs: [serviceId],
    );
  }

  Future<int> updateServiceStatus(int serviceId, String status) async {
    final db = await database;

    final values = <String, dynamic>{
      'service_status': status,
      'completed_date': status == 'Tamamlandı' ? todayDbDate() : null,
    };

    return await db.update(
      'services',
      values,
      where: 'id = ?',
      whereArgs: [serviceId],
    );
  }

  // =========================
  // PARÇA BEKLEYENLER
  // =========================

  Future<List<Map<String, dynamic>>>
  getWaitingPartsServicesWithCustomer() async {
    final db = await database;

    return await db.rawQuery('''
      SELECT
        s.id,
        s.customerId,
        s.product,
        s.problem,
        s.price,
        s.done_description,
        s.planned_date,
        s.date,
        s.service_status,
        s.completed_date,
        c.name,
        c.phone,
        c.address,
        c.reminder_note
      FROM services s
      LEFT JOIN customers c ON s.customerId = c.id
      WHERE TRIM(COALESCE(s.service_status,'')) = 'Parça Bekliyor'
        AND (s.completed_date IS NULL OR TRIM(s.completed_date) = '')
      ORDER BY s.planned_date DESC, s.id DESC
      ''');
  }

  // =========================
  // RAPORLAMA
  // =========================

  Future<List<Map<String, dynamic>>> getCompletedServicesByCompletedDate(
    String dbDate,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT
        s.id,
        s.customerId,
        s.product,
        s.problem,
        s.price,
        s.done_description,
        s.planned_date,
        s.date,
        s.service_status,
        s.completed_date,
        c.name,
        c.phone,
        c.address
      FROM services s
      LEFT JOIN customers c ON s.customerId = c.id
      WHERE TRIM(COALESCE(s.service_status,'')) = 'Tamamlandı'
        AND TRIM(COALESCE(s.completed_date,'')) = ?
      ORDER BY s.id DESC
      ''',
      [dbDate],
    );
  }

  Future<Map<String, dynamic>> getSummaryByCompletedDateRange(
    String startDb,
    String endDb,
  ) async {
    final db = await database;
    final res = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS count,
        COALESCE(SUM(price), 0) AS total
      FROM services
      WHERE TRIM(COALESCE(service_status,'')) = 'Tamamlandı'
        AND TRIM(COALESCE(completed_date,'')) >= ?
        AND TRIM(COALESCE(completed_date,'')) <= ?
      ''',
      [startDb, endDb],
    );
    return res.first;
  }

  // İstersen raporda direkt kullanırsın (opsiyonel)
  Future<double> getRevenueByCompletedDate(String dbDate) async {
    final db = await database;
    final res = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(price), 0) AS total
      FROM services
      WHERE TRIM(COALESCE(service_status,'')) = 'Tamamlandı'
        AND TRIM(COALESCE(completed_date,'')) = ?
      ''',
      [dbDate],
    );

    final total = res.first['total'];
    return (total is num)
        ? total.toDouble()
        : double.tryParse(total.toString()) ?? 0.0;
  }

  Future<int> getWaitingPartsCount() async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT COUNT(*) AS count
      FROM services
      WHERE TRIM(COALESCE(service_status,'')) = 'Parça Bekliyor'
        AND (completed_date IS NULL OR TRIM(completed_date) = '')
      ''');
    final v = res.first['count'];
    return v is int ? v : int.tryParse(v.toString()) ?? 0;
  }

  Future<int> getCanceledCountByPlannedDateRange(
    String startDb,
    String endDb,
  ) async {
    final db = await database;
    final res = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM services
      WHERE TRIM(COALESCE(service_status,'')) = 'İptal'
        AND TRIM(COALESCE(planned_date,'')) >= ?
        AND TRIM(COALESCE(planned_date,'')) <= ?
      ''',
      [startDb, endDb],
    );
    final v = res.first['count'];
    return v is int ? v : int.tryParse(v.toString()) ?? 0;
  }

  // =========================
  // FIX (İSTEĞE BAĞLI)
  // =========================

  Future<void> fixCompletedDateForCompletedServices() async {
    final db = await database;
    await db.execute("""
      UPDATE services
      SET completed_date = COALESCE(completed_date, planned_date)
      WHERE TRIM(COALESCE(service_status,'')) = 'Tamamlandı'
        AND (completed_date IS NULL OR TRIM(completed_date) = '')
    """);
  }

  // =========================
  // HATIRLATICI -> OTOMATİK SERVİS
  // =========================

  Future<void> processTodayReminders() async {
    final db = await database;
    final today = todayDbDate();

    final customersWithReminder = await db.query(
      'customers',
      where: 'reminder_date IS NOT NULL AND reminder_date != ?',
      whereArgs: [''],
    );

    for (final customer in customersWithReminder) {
      final reminderDate = (customer['reminder_date'] ?? '').toString().trim();
      if (reminderDate != today) continue;

      final existing = await db.query(
        'services',
        where: 'customerId = ? AND planned_date = ? AND product = ?',
        whereArgs: [customer['id'], today, 'Periyodik Bakım'],
        limit: 1,
      );

      if (existing.isEmpty) {
        await db.insert('services', {
          'customerId': customer['id'],
          'product': 'Periyodik Bakım',
          'problem': (customer['reminder_note'] ?? 'Bakım zamanı geldi')
              .toString(),
          'price': 0,
          'done_description': '',
          'planned_date': today,
          'date': today,
          'service_status': 'Parça Bekliyor',
          'completed_date': null,
        });
      }

      await db.update(
        'customers',
        {'reminder_date': null, 'reminder_note': null},
        where: 'id = ?',
        whereArgs: [customer['id']],
      );
    }
  }
}
