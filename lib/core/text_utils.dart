const _arabicIndic = '٠١٢٣٤٥٦٧٨٩';
const _persian = '۰۱۲۳۴۵۶۷۸۹';

/// يحوّل الأرقام العربية/الفارسية إلى أرقام إنجليزية.
String digitsToAscii(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    final i = _arabicIndic.indexOf(ch);
    final j = _persian.indexOf(ch);
    if (i >= 0) {
      b.write(i);
    } else if (j >= 0) {
      b.write(j);
    } else {
      b.write(ch);
    }
  }
  return b.toString();
}

/// تطبيع النص العربي للبحث (إزالة التشكيل وتوحيد الحروف المتشابهة).
String normalizeForSearch(String input) {
  var s = digitsToAscii(input).toLowerCase().trim();
  s = s.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '');
  s = s
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ٱ', 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي');
  return s.replaceAll(RegExp(r'\s+'), ' ');
}

String onlyDigits(String s) => digitsToAscii(s).replaceAll(RegExp(r'[^0-9]'), '');

/// الحرف الأول لعرضه داخل الدائرة (Avatar).
String initialOf(String name) {
  final t = name.trim();
  if (t.isEmpty) return '؟';
  return String.fromCharCode(t.runes.first);
}

String safeFileName(String s) {
  final t = s.trim().replaceAll(RegExp(r'[\\/:*?"<>|\n\r\t]'), '_').replaceAll(RegExp(r'\s+'), '_');
  return t.isEmpty ? 'file' : t;
}
