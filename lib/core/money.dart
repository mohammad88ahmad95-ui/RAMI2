import 'constants.dart';
import 'text_utils.dart';

/// جميع المبالغ تُخزَّن كأعداد صحيحة بأصغر وحدة (×100) لتجنب أخطاء الفاصلة العشرية.
class Money {
  Money._();

  static const String _lrm = '\u200E';

  /// يحوّل نصاً مثل "1,500.50" إلى 150050. يُرجع null إذا كان غير صالح.
  static int? parse(String? input) {
    if (input == null) return null;
    var t = digitsToAscii(input).trim();
    t = t.replaceAll(RegExp(r'[,\u066C\s]'), '').replaceAll('\u066B', '.');
    if (t.isEmpty) return null;
    if (!RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(t)) return null;
    final parts = t.split('.');
    if (parts[0].length > 12) return null;
    final whole = int.parse(parts[0]);
    var frac = parts.length > 1 ? parts[1] : '';
    frac = frac.padRight(2, '0');
    return whole * 100 + int.parse(frac.isEmpty ? '0' : frac);
  }

  static String _group(String digits) => digits.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (m) => ',',
      );

  /// تنسيق بدون عملة: 2,500,000 أو 1,250.50
  static String format(int minor) {
    final neg = minor < 0;
    final abs = minor.abs();
    final whole = abs ~/ 100;
    final frac = abs % 100;
    var s = _group(whole.toString());
    if (frac != 0) s = '$s.${frac.toString().padLeft(2, '0')}';
    return neg ? '$_lrm-$s' : s;
  }

  /// 2,500,000 ل.س
  static String withCurrency(int minor, String currencyCode) =>
      '${format(minor)} ${currencySymbol(currencyCode)}';

  /// +2,500,000 أو -1,000,000 (للعرض في الواجهة فقط).
  static String signed(int minor, {required bool plus}) =>
      '$_lrm${plus ? '+' : '-'}${format(minor.abs())}';

  /// نص قابل للتعديل داخل الحقل (بدون فواصل).
  static String toInput(int minor) {
    final whole = minor ~/ 100;
    final frac = minor % 100;
    return frac == 0 ? whole.toString() : '$whole.${frac.toString().padLeft(2, '0')}';
  }
}
