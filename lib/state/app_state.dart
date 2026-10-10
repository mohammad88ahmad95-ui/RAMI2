import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../data/settings_repository.dart';
import '../services/lock_service.dart';

/// حالة التطبيق العامة: الإعدادات، الوضع الداكن، قفل التطبيق، العملة النشطة.
class AppState extends ChangeNotifier {
  final SettingsRepository _repo = SettingsRepository.instance;
  Map<String, String> _s = {};

  bool loaded = false;
  bool locked = false;
  String activeCurrency = 'SYP';

  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  Future<void> load() async {
    _s = await _repo.all();
    activeCurrency = defaultCurrency;
    locked = lockEnabled;
    loaded = true;
    notifyListeners();
  }

  /// بعد استعادة نسخة احتياطية.
  Future<void> reloadSettings() async {
    _s = await _repo.all();
    if (!kCurrencies.any((c) => c.code == activeCurrency)) activeCurrency = defaultCurrency;
    notifyListeners();
  }

  // ---- القيم ----
  String get businessName => _s[SettingKeys.businessName] ?? '';
  String get userName => _s[SettingKeys.userName] ?? '';
  String get defaultCurrency {
    final c = _s[SettingKeys.defaultCurrency];
    return kCurrencies.any((x) => x.code == c) ? c! : 'SYP';
  }

  ThemeMode get themeMode {
    switch (_s[SettingKeys.themeMode]) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  bool get lockEnabled =>
      _s[SettingKeys.lockEnabled] == '1' && (_s[SettingKeys.pinHash] ?? '').isNotEmpty;
  bool get biometricEnabled => lockEnabled && _s[SettingKeys.biometricEnabled] == '1';
  DateTime? get lastBackupAt => DateTime.tryParse(_s[SettingKeys.lastBackupAt] ?? '');

  // ---- التعديل ----
  Future<void> _put(String key, String value) async {
    await _repo.set(key, value);
    _s[key] = value;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode m) =>
      _put(SettingKeys.themeMode, m == ThemeMode.dark ? 'dark' : m == ThemeMode.light ? 'light' : 'system');

  Future<void> setDefaultCurrency(String code) async {
    await _put(SettingKeys.defaultCurrency, code);
    activeCurrency = code;
    notifyListeners();
  }

  void setActiveCurrency(String code) {
    activeCurrency = code;
    notifyListeners();
  }

  Future<void> setBusinessName(String v) => _put(SettingKeys.businessName, v.trim());
  Future<void> setUserName(String v) => _put(SettingKeys.userName, v.trim());

  // ---- الحماية ----
  Future<void> enableLock(String pin) async {
    final salt = LockService.newSalt();
    await _repo.set(SettingKeys.pinSalt, salt);
    await _repo.set(SettingKeys.pinHash, LockService.hashPin(pin, salt));
    await _repo.set(SettingKeys.lockEnabled, '1');
    _s[SettingKeys.pinSalt] = salt;
    _s[SettingKeys.pinHash] = LockService.hashPin(pin, salt);
    _s[SettingKeys.lockEnabled] = '1';
    notifyListeners();
  }

  Future<void> disableLock() async {
    await _repo.set(SettingKeys.lockEnabled, '0');
    await _repo.set(SettingKeys.biometricEnabled, '0');
    await _repo.remove(SettingKeys.pinHash);
    await _repo.remove(SettingKeys.pinSalt);
    _s[SettingKeys.lockEnabled] = '0';
    _s[SettingKeys.biometricEnabled] = '0';
    _s.remove(SettingKeys.pinHash);
    _s.remove(SettingKeys.pinSalt);
    locked = false;
    notifyListeners();
  }

  Future<void> setBiometric(bool on) => _put(SettingKeys.biometricEnabled, on ? '1' : '0');

  bool checkPin(String pin) {
    final salt = _s[SettingKeys.pinSalt] ?? '';
    final hash = _s[SettingKeys.pinHash] ?? '';
    return hash.isNotEmpty && LockService.hashPin(pin, salt) == hash;
  }

  /// يُرجع true عند النجاح. بعد 5 محاولات خاطئة ينتظر المستخدم 30 ثانية.
  bool verifyPin(String pin) {
    if (lockoutRemaining > 0) return false;
    if (checkPin(pin)) {
      _failedAttempts = 0;
      return true;
    }
    _failedAttempts++;
    if (_failedAttempts >= 5) {
      _failedAttempts = 0;
      _lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
    }
    return false;
  }

  int get lockoutRemaining {
    final u = _lockoutUntil;
    if (u == null) return 0;
    final r = u.difference(DateTime.now()).inSeconds + 1;
    if (r <= 0) {
      _lockoutUntil = null;
      return 0;
    }
    return r;
  }

  void lock() {
    if (lockEnabled && !locked) {
      locked = true;
      notifyListeners();
    }
  }

  void unlock() {
    _failedAttempts = 0;
    if (locked) {
      locked = false;
      notifyListeners();
    }
  }
}
