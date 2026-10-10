import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../core/constants.dart';
import '../core/errors.dart';

/// فتح قاعدة البيانات المحلية (SQLite) وإدارة إشعارات التغيير.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  /// يزداد عند كل كتابة ناجحة؛ الشاشات تستمع إليه لتحديث نفسها تلقائياً.
  final ValueNotifier<int> changes = ValueNotifier<int>(0);

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, kDbName);
    return openDatabase(
      path,
      version: kDbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE suppliers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT NOT NULL DEFAULT '',
  company TEXT NOT NULL DEFAULT '',
  address TEXT NOT NULL DEFAULT '',
  notes TEXT NOT NULL DEFAULT '',
  currency TEXT NOT NULL DEFAULT 'SYP',
  archived INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)''');
        await db.execute('''
CREATE TABLE purchase_invoices (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  supplier_id INTEGER NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
  invoice_number TEXT NOT NULL DEFAULT '',
  date TEXT NOT NULL,
  amount INTEGER NOT NULL CHECK (amount > 0),
  notes TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)''');
        await db.execute('''
CREATE TABLE payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  supplier_id INTEGER NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
  date TEXT NOT NULL,
  amount INTEGER NOT NULL CHECK (amount > 0),
  method TEXT NOT NULL DEFAULT 'cash',
  notes TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)''');
        await db.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
        await db.execute('CREATE INDEX idx_inv_supplier ON purchase_invoices(supplier_id, date)');
        await db.execute('CREATE INDEX idx_pay_supplier ON payments(supplier_id, date)');
        await db.execute('CREATE INDEX idx_inv_date ON purchase_invoices(date)');
        await db.execute('CREATE INDEX idx_pay_date ON payments(date)');
        await db.execute('CREATE INDEX idx_sup_archived ON suppliers(archived)');
      },
    );
  }

  void markChanged() => changes.value++;

  /// قراءة مع تحويل أي خطأ تقني إلى رسالة عربية بسيطة.
  Future<T> read<T>(Future<T> Function(Database db) action) async {
    try {
      final db = await database;
      return await action(db);
    } on AppException {
      rethrow;
    } catch (e, st) {
      debugPrint('DB read error: $e\n$st');
      throw const AppException(kLoadError);
    }
  }

  /// كتابة ثم إشعار الشاشات بالتغيير.
  Future<T> write<T>(Future<T> Function(Database db) action) async {
    try {
      final db = await database;
      final r = await action(db);
      markChanged();
      return r;
    } on AppException {
      rethrow;
    } catch (e, st) {
      debugPrint('DB write error: $e\n$st');
      throw const AppException(kSaveError);
    }
  }
}

String nowIso() => DateTime.now().toIso8601String();
