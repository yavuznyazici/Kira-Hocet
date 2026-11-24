import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'kira_hocet.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE apartments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          tenant TEXT NOT NULL,
          rent INTEGER NOT NULL,
          payment_day INTEGER NOT NULL,
          increase_rent INTEGER,
          increase_month INTEGER,
          increase_year INTEGER
        )
      ''');
      await db.execute('''
        CREATE TABLE payments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          apartment_id INTEGER NOT NULL,
          year INTEGER NOT NULL,
          month INTEGER NOT NULL,
          amount INTEGER NOT NULL,
          paid INTEGER NOT NULL DEFAULT 0,
          paid_at TEXT,
          UNIQUE(apartment_id, year, month),
          FOREIGN KEY(apartment_id) REFERENCES apartments(id) ON DELETE CASCADE
        )
      ''');
    });
    await _db!.execute('PRAGMA foreign_keys = ON');
    return _db!;
  }

  Future<List<Map<String, Object?>>> getApartments() async =>
      (await database).query('apartments', orderBy: 'name COLLATE NOCASE');

  Future<int> saveApartment(Map<String, Object?> values) async {
    final db = await database;
    if (values['id'] == null) return db.insert('apartments', values);
    return db.update('apartments', values, where: 'id = ?', whereArgs: [values['id']]);
  }

  Future<void> deleteApartment(int id) async {
    final db = await database;
    await db.delete('payments', where: 'apartment_id = ?', whereArgs: [id]);
    await db.delete('apartments', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, Object?>?> getPayment(int apartmentId, DateTime month) async {
    final rows = await (await database).query('payments',
        where: 'apartment_id = ? AND year = ? AND month = ?',
        whereArgs: [apartmentId, month.year, month.month], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> setPayment(int apartmentId, DateTime month, int amount, bool paid) async {
    final db = await database;
    await db.insert(
      'payments',
      {
        'apartment_id': apartmentId,
        'year': month.year,
        'month': month.month,
        'amount': amount,
        'paid': paid ? 1 : 0,
        'paid_at': paid ? DateTime.now().toIso8601String() : null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> paymentsForMonth(DateTime month) async =>
      (await database).query('payments', where: 'year = ? AND month = ?', whereArgs: [month.year, month.month]);
}
