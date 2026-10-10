import '../core/dates.dart';

enum PeriodKind {
  all('الكل'),
  today('اليوم'),
  week('هذا الأسبوع'),
  month('هذا الشهر'),
  lastMonth('الشهر الماضي'),
  year('هذه السنة'),
  custom('فترة مخصصة');

  final String label;
  const PeriodKind(this.label);
}

/// مدى زمني شامل للطرفين (تواريخ بدون وقت). null = بلا حد.
class DateRange {
  final DateTime? from;
  final DateTime? to;
  const DateRange({this.from, this.to});

  static const DateRange all = DateRange();

  String? get fromIso => from == null ? null : isoDate(from!);
  String? get toIso => to == null ? null : isoDate(to!);

  bool get isAll => from == null && to == null;

  String get label {
    if (isAll) return 'كل الفترات';
    if (from != null && to != null) return 'من ${fmtShortDate(from!)} إلى ${fmtShortDate(to!)}';
    if (from != null) return 'من ${fmtShortDate(from!)}';
    return 'حتى ${fmtShortDate(to!)}';
  }

  static DateRange forKind(PeriodKind kind, {DateRange? custom, DateTime? now}) {
    final t = now ?? today();
    switch (kind) {
      case PeriodKind.all:
        return DateRange.all;
      case PeriodKind.today:
        return DateRange(from: t, to: t);
      case PeriodKind.week:
        // الأسبوع يبدأ يوم السبت
        final sinceSaturday = (t.weekday + 1) % 7;
        final start = DateTime(t.year, t.month, t.day - sinceSaturday);
        return DateRange(from: start, to: t);
      case PeriodKind.month:
        return DateRange(from: DateTime(t.year, t.month, 1), to: DateTime(t.year, t.month + 1, 0));
      case PeriodKind.lastMonth:
        return DateRange(from: DateTime(t.year, t.month - 1, 1), to: DateTime(t.year, t.month, 0));
      case PeriodKind.year:
        return DateRange(from: DateTime(t.year, 1, 1), to: DateTime(t.year, 12, 31));
      case PeriodKind.custom:
        return custom ?? DateRange.all;
    }
  }
}
