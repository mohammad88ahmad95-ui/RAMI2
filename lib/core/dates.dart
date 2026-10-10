const List<String> _months = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];

String _two(int n) => n.toString().padLeft(2, '0');

DateTime today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

/// yyyy-MM-dd
String isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

DateTime? tryParseIso(String? s) {
  if (s == null) return null;
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s);
  if (m == null) return null;
  final y = int.parse(m.group(1)!);
  final mo = int.parse(m.group(2)!);
  final d = int.parse(m.group(3)!);
  final dt = DateTime(y, mo, d);
  if (dt.year != y || dt.month != mo || dt.day != d) return null;
  return dt;
}

/// 08/10/2026
String fmtShortDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

String fmtShort(String iso) {
  final d = tryParseIso(iso);
  return d == null ? iso : fmtShortDate(d);
}

/// 08 أكتوبر 2026
String fmtLong(DateTime d) => '${_two(d.day)} ${_months[d.month - 1]} ${d.year}';

String fmtLongIso(String iso) {
  final d = tryParseIso(iso);
  return d == null ? iso : fmtLong(d);
}

String monthName(int month) => _months[month - 1];

/// 08/10/2026 14:30
String fmtDateTime(DateTime d) => '${fmtShortDate(d)} ${_two(d.hour)}:${_two(d.minute)}';

int daysBetween(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

/// اليوم / أمس / منذ يومين / منذ 5 أيام ...
String relativeDay(String iso) {
  final d = tryParseIso(iso);
  if (d == null) return iso;
  final diff = daysBetween(d, today());
  if (diff < 0) return fmtLong(d);
  if (diff == 0) return 'اليوم';
  if (diff == 1) return 'أمس';
  if (diff == 2) return 'منذ يومين';
  if (diff <= 10) return 'منذ $diff أيام';
  if (diff < 30) {
    final w = diff ~/ 7;
    if (w <= 1) return 'منذ أسبوع';
    if (w == 2) return 'منذ أسبوعين';
    return 'منذ $w أسابيع';
  }
  if (diff < 365) {
    final m = diff ~/ 30;
    if (m <= 1) return 'منذ شهر';
    if (m == 2) return 'منذ شهرين';
    if (m <= 10) return 'منذ $m أشهر';
    return 'منذ $m شهراً';
  }
  final y = diff ~/ 365;
  if (y <= 1) return 'منذ سنة';
  if (y == 2) return 'منذ سنتين';
  if (y <= 10) return 'منذ $y سنوات';
  return 'منذ $y سنة';
}

String greetingForNow() {
  final h = DateTime.now().hour;
  if (h < 12) return 'صباح الخير';
  if (h < 18) return 'مساء الخير';
  return 'مساء الخير';
}
