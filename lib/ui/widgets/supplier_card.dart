import 'package:flutter/material.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../models/ledger_entry.dart';
import '../../models/supplier.dart';
import 'common.dart';

String lastMovementText(SupplierSummary s) {
  final d = s.lastMovementDate;
  if (d == null) return 'لا توجد حركات بعد';
  final what = s.lastMovementType == EntryType.invoice ? 'فاتورة' : 'دفعة';
  return '$what ${relativeDay(d)}';
}

/// بطاقة المورد في قائمة الموردين.
class SupplierCard extends StatelessWidget {
  const SupplierCard({super.key, required this.summary, required this.onTap});
  final SupplierSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    final s = summary;
    final color = statusColor(s.status);
    final label = s.status == AccountStatus.due
        ? 'المستحق'
        : s.status == AccountStatus.settled
            ? 'الرصيد'
            : 'رصيد لصالحك';
    return RamiCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          AvatarCircle(s.supplier.name, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.supplier.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                if (s.supplier.company.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(s.supplier.company,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: pal.muted, fontSize: 13)),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.history_rounded, size: 14, color: pal.muted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(lastMovementText(s),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: pal.muted, fontSize: 12.5)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(label, style: TextStyle(color: pal.muted, fontSize: 11.5)),
              const SizedBox(height: 2),
              Text(Money.withCurrency(s.balance.abs(), s.currency),
                  style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 6),
              StatusChip(s.status),
            ],
          ),
        ],
      ),
    );
  }
}
