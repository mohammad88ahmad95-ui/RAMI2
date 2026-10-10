import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../core/constants.dart';
import '../core/dates.dart';
import '../core/errors.dart';
import '../data/database.dart';
import '../data/settings_repository.dart';
import 'file_service.dart';

class BackupInfo {
  final int suppliers;
  final int invoices;
  final int payments;
  final String createdAt;
  const BackupInfo(this.suppliers, this.invoices, this.payments, this.createdAt);
}

class _Parsed {
  final Map<String, String> settings;
  final List<Map<String, Object?>> suppliers;
  final List<Map<String, Object?>> invoices;
  final List<Map<String, Object?>> payments;
  final String createdAt;
  _Parsed(this.settings, this.suppliers, this.invoices, this.payments, this.createdAt);
}

/// نسخة احتياطية بصيغة JSON منظمة مع بصمة SHA-256 للتحقق من سلامة الملف.
class BackupService {
  BackupService._();

  static const String _invalid = 'ملف النسخة الاحتياطية غير صالح أو تالف.';

  static String _checksum(Object data) => sha256.convert(utf8.encode(jsonEncode(data))).toString();

  static Future<String> buildJson() async {
    try {
      final db = await AppDatabase.instance.database;
      final settings = await SettingsRepository.instance.all();
      final data = <String, Object?>{
        'settings': {
          for (final k in SettingKeys.backedUp)
            if (settings.containsKey(k)) k: settings[k],
        },
        'suppliers': await db.query('suppliers', orderBy: 'id'),
        'purchase_invoices': await db.query('purchase_invoices', orderBy: 'id'),
        'payments': await db.query('payments', orderBy: 'id'),
      };
      return jsonEncode({
        'app': 'rami',
        'version': kBackupVersion,
        'created_at': DateTime.now().toIso8601String(),
        'checksum': _checksum(data),
        'data': data,
      });
    } catch (_) {
      throw const AppException('تعذّر إنشاء النسخة الاحتياطية. حاول مرة أخرى.');
    }
  }

  /// يُنشئ ملف النسخة ويفتح قائمة المشاركة (واتساب، بريد، ملفات...).
  static Future<void> exportAndShare() async {
    final json = await buildJson();
    final now = DateTime.now();
    final stamp = '${isoDate(now)}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final file = await writeTempFile('rami_backup_$stamp.json', utf8.encode(json));
    await shareFile(file, mime: 'application/json', subject: 'نسخة احتياطية - رامي');
    await SettingsRepository.instance.set(SettingKeys.lastBackupAt, now.toIso8601String());
  }

  static _Parsed _parse(String text) {
    try {
      final root = jsonDecode(text);
      if (root is! Map<String, dynamic>) throw const AppException(_invalid);
      if (root['app'] != 'rami') throw const AppException('هذا الملف ليس نسخة احتياطية لتطبيق رامي.');
      final version = root['version'];
      if (version is! int || version > kBackupVersion) {
        throw const AppException('إصدار النسخة الاحتياطية غير مدعوم. حدّث التطبيق أولاً.');
      }
      final data = root['data'];
      if (data is! Map<String, dynamic>) throw const AppException(_invalid);
      if (root['checksum'] != _checksum(data)) throw const AppException(_invalid);

      List<Map<String, Object?>> list(String key) {
        final v = data[key];
        if (v is! List) throw const AppException(_invalid);
        return v.map((e) {
          if (e is! Map) throw const AppException(_invalid);
          return Map<String, Object?>.from(e);
        }).toList();
      }

      String str(Map<String, Object?> m, String k, {bool req = false}) {
        final v = m[k];
        if (v == null) {
          if (req) throw const AppException(_invalid);
          return '';
        }
        if (v is! String) throw const AppException(_invalid);
        if (req && v.trim().isEmpty) throw const AppException(_invalid);
        return v;
      }

      int integer(Map<String, Object?> m, String k) {
        final v = m[k];
        if (v is! int) throw const AppException(_invalid);
        return v;
      }

      final suppliers = <Map<String, Object?>>[];
      final ids = <int>{};
      for (final m in list('suppliers')) {
        final id = integer(m, 'id');
        if (!ids.add(id)) throw const AppException(_invalid);
        final currency = str(m, 'currency');
        suppliers.add({
          'id': id,
          'name': str(m, 'name', req: true),
          'phone': str(m, 'phone'),
          'company': str(m, 'company'),
          'address': str(m, 'address'),
          'notes': str(m, 'notes'),
          'currency': kCurrencies.any((c) => c.code == currency) ? currency : 'SYP',
          'archived': (m['archived'] == 1) ? 1 : 0,
          'created_at': str(m, 'created_at').isEmpty ? nowIso() : str(m, 'created_at'),
          'updated_at': str(m, 'updated_at').isEmpty ? nowIso() : str(m, 'updated_at'),
        });
      }

      void checkCommon(Map<String, Object?> m) {
        if (!ids.contains(integer(m, 'supplier_id'))) throw const AppException(_invalid);
        if (tryParseIso(str(m, 'date', req: true)) == null) throw const AppException(_invalid);
        final a = integer(m, 'amount');
        if (a <= 0 || a > kMaxAmountMinor) throw const AppException(_invalid);
      }

      final invoices = <Map<String, Object?>>[];
      for (final m in list('purchase_invoices')) {
        checkCommon(m);
        invoices.add({
          'id': integer(m, 'id'),
          'supplier_id': m['supplier_id'],
          'invoice_number': str(m, 'invoice_number'),
          'date': m['date'],
          'amount': m['amount'],
          'notes': str(m, 'notes'),
          'created_at': str(m, 'created_at').isEmpty ? nowIso() : str(m, 'created_at'),
          'updated_at': str(m, 'updated_at').isEmpty ? nowIso() : str(m, 'updated_at'),
        });
      }

      final payments = <Map<String, Object?>>[];
      for (final m in list('payments')) {
        checkCommon(m);
        payments.add({
          'id': integer(m, 'id'),
          'supplier_id': m['supplier_id'],
          'date': m['date'],
          'amount': m['amount'],
          'method': ['cash', 'transfer', 'remittance', 'other'].contains(m['method']) ? m['method'] : 'other',
          'notes': str(m, 'notes'),
          'created_at': str(m, 'created_at').isEmpty ? nowIso() : str(m, 'created_at'),
          'updated_at': str(m, 'updated_at').isEmpty ? nowIso() : str(m, 'updated_at'),
        });
      }

      final settings = <String, String>{};
      final rawSettings = data['settings'];
      if (rawSettings is Map) {
        for (final k in SettingKeys.backedUp) {
          final v = rawSettings[k];
          if (v is String) settings[k] = v;
        }
      }
      return _Parsed(settings, suppliers, invoices, payments, (root['created_at'] as String?) ?? '');
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(_invalid);
    }
  }

  /// قراءة الملف والتحقق منه دون تغيير أي بيانات.
  static BackupInfo inspect(String text) {
    final parsed = _parse(text);
    return BackupInfo(parsed.suppliers.length, parsed.invoices.length, parsed.payments.length, parsed.createdAt);
  }

  /// يستبدل جميع البيانات الحالية بمحتوى النسخة (بعد حفظ نسخة أمان تلقائية).
  static Future<void> restore(String text) async {
    final parsed = _parse(text);
    try {
      // نسخة أمان تلقائية قبل الاستبدال
      final json = await buildJson();
      final dir = await getApplicationDocumentsDirectory();
      await File(p.join(dir.path, 'rami_auto_backup_before_restore.json')).writeAsString(json, flush: true);
    } catch (_) {
      // فشل نسخة الأمان لا يمنع الاستعادة
    }
    await AppDatabase.instance.write((db) async {
      await db.transaction((txn) async {
        await txn.delete('payments');
        await txn.delete('purchase_invoices');
        await txn.delete('suppliers');
        final batch = txn.batch();
        for (final m in parsed.suppliers) {
          batch.insert('suppliers', m);
        }
        for (final m in parsed.invoices) {
          batch.insert('purchase_invoices', m);
        }
        for (final m in parsed.payments) {
          batch.insert('payments', m);
        }
        for (final e in parsed.settings.entries) {
          batch.insert('settings', {'key': e.key, 'value': e.value},
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      });
    });
  }

  /// حذف جميع البيانات (الموردون والفواتير والدفعات).
  static Future<void> wipeAll() async {
    await AppDatabase.instance.write((db) async {
      await db.transaction((txn) async {
        await txn.delete('payments');
        await txn.delete('purchase_invoices');
        await txn.delete('suppliers');
      });
    });
  }
}
