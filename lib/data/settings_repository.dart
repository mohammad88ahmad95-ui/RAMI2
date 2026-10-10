import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../core/errors.dart';
import 'database.dart';

class SettingKeys {
  static const businessName = 'business_name';
  static const userName = 'user_name';
  static const defaultCurrency = 'default_currency';
  static const themeMode = 'theme_mode'; // system | light | dark
  static const language = 'language';
  static const lockEnabled = 'lock_enabled';
  static const biometricEnabled = 'biometric_enabled';
  static const pinHash = 'pin_hash';
  static const pinSalt = 'pin_salt';
  static const lastBackupAt = 'last_backup_at';

  /// المفاتيح التي تُحفظ داخل النسخة الاحتياطية (بدون إعدادات الحماية).
  static const backedUp = [businessName, userName, defaultCurrency, themeMode, language];
}

/// الإعدادات لا تُحدث إشعار تغيّر البيانات (حتى لا تُعاد تحميل كل الشاشات).
class SettingsRepository {
  SettingsRepository._();
  static final SettingsRepository instance = SettingsRepository._();
  final _db = AppDatabase.instance;

  Future<Map<String, String>> all() async {
    try {
      final db = await _db.database;
      final rows = await db.query('settings');
      return {for (final r in rows) r['key'] as String: r['value'] as String};
    } catch (e) {
      debugPrint('settings read error: $e');
      throw const AppException(kLoadError);
    }
  }

  Future<void> set(String key, String value) async {
    try {
      final db = await _db.database;
      await db.insert('settings', {'key': key, 'value': value},
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('settings write error: $e');
      throw const AppException(kSaveError);
    }
  }

  Future<void> remove(String key) async {
    try {
      final db = await _db.database;
      await db.delete('settings', where: 'key = ?', whereArgs: [key]);
    } catch (e) {
      debugPrint('settings delete error: $e');
      throw const AppException(kSaveError);
    }
  }
}
