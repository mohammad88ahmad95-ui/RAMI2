import 'constants.dart';
import 'money.dart';
import 'text_utils.dart';

class Validators {
  Validators._();

  static String? supplierName(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'يرجى إدخال اسم المورد';
    if (t.length > 100) return 'اسم المورد طويل جداً';
    return null;
  }

  static String? phone(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    final digits = onlyDigits(t);
    if (digits.length < 5 || digits.length > 20 || !RegExp(r'^[0-9+\-\s()٠-٩]+$').hasMatch(t)) {
      return 'رقم الهاتف غير صحيح';
    }
    return null;
  }

  static String? invoiceNumber(String? v) {
    if ((v ?? '').trim().length > 50) return 'رقم الفاتورة طويل جداً';
    return null;
  }

  static String? notes(String? v) {
    if ((v ?? '').length > 1000) return 'الملاحظات طويلة جداً';
    return null;
  }

  static String? amount(String? v, {required String what}) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'يرجى إدخال $what';
    final minor = Money.parse(t);
    if (minor == null) return '$what غير صحيح';
    if (minor <= 0) return '$what يجب أن يكون أكبر من صفر';
    if (minor > kMaxAmountMinor) return '$what كبير جداً';
    return null;
  }

  static String? date(DateTime? d) {
    if (d == null) return 'يرجى اختيار التاريخ';
    if (d.year < 2000 || d.year > 2100) return 'التاريخ غير صحيح';
    return null;
  }
}
