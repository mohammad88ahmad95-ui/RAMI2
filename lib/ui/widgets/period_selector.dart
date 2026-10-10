import 'package:flutter/material.dart';

import '../../core/dates.dart';
import '../../models/period.dart';
import 'common.dart';

/// شريط اختيار الفترة (اليوم، هذا الأسبوع ... فترة مخصصة).
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.kind,
    required this.range,
    required this.onChanged,
    this.kinds = const [
      PeriodKind.all,
      PeriodKind.today,
      PeriodKind.week,
      PeriodKind.month,
      PeriodKind.lastMonth,
      PeriodKind.year,
      PeriodKind.custom,
    ],
  });

  final PeriodKind kind;
  final DateRange range;
  final void Function(PeriodKind kind, DateRange range) onChanged;
  final List<PeriodKind> kinds;

  Future<void> _pick(BuildContext context) async {
    final now = today();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: range.from != null && range.to != null
          ? DateTimeRange(start: range.from!, end: range.to!)
          : DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
      locale: const Locale('ar'),
      helpText: 'اختر الفترة',
      cancelText: 'إلغاء',
      confirmText: 'تطبيق',
      saveText: 'تطبيق',
    );
    if (r != null) {
      onChanged(
        PeriodKind.custom,
        DateRange(
          from: DateTime(r.start.year, r.start.month, r.start.day),
          to: DateTime(r.end.year, r.end.month, r.end.day),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: kinds.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final k = kinds[i];
          return RamiChip(
            label: k.label,
            selected: k == kind,
            icon: k == PeriodKind.custom ? Icons.date_range_rounded : null,
            onTap: () {
              if (k == PeriodKind.custom) {
                _pick(context);
              } else {
                onChanged(k, DateRange.forKind(k));
              }
            },
          );
        },
      ),
    );
  }
}
