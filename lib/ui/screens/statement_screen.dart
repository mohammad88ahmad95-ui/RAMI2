import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../data/ledger_repository.dart';
import '../../models/period.dart';
import '../../models/statement.dart';
import '../../models/supplier.dart';
import '../../reports/report_builders.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/data_table_lite.dart';
import '../widgets/period_selector.dart';
import '../widgets/report_actions.dart';

/// كشف حساب مورد مع فلترة بالفترة وتصدير PDF.
class StatementScreen extends StatefulWidget {
  const StatementScreen({super.key, required this.supplierId});
  final int supplierId;

  @override
  State<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends State<StatementScreen> {
  PeriodKind _kind = PeriodKind.all;
  DateRange _range = DateRange.all;
  StatementData? _last;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    final business = context.watch<AppState>().businessName;
    return Scaffold(
      appBar: AppBar(title: const Text('كشف الحساب')),
      body: DataLoader<StatementData>(
        reloadKey: '$_kind${_range.fromIso}${_range.toIso}',
        load: () => LedgerRepository.instance.statement(widget.supplierId, _range),
        skeleton: const SkeletonList(count: 5, height: 70),
        builder: (context, d) {
          _last = d;
          final cur = d.currency;
          final closing = d.closingBalance;
          final st = closing > 0 ? AccountStatus.due : closing == 0 ? AccountStatus.settled : AccountStatus.credit;
          Widget box(String l, String v, Color c) => Expanded(
                child: RamiCard(
                  padding: const EdgeInsets.all(10),
                  radius: 14,
                  child: Column(children: [
                    Text(l, style: TextStyle(color: pal.muted, fontSize: 11.5)),
                    const SizedBox(height: 4),
                    FittedBox(child: Text(v, style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 14))),
                  ]),
                ),
              );
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(children: [
                  AvatarCircle(d.supplier.name, size: 40, color: statusColor(st)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d.supplier.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      Text(d.range.label, style: TextStyle(color: pal.muted, fontSize: 12.5)),
                    ]),
                  ),
                ]),
              ),
              PeriodSelector(
                kind: _kind,
                range: _range,
                onChanged: (k, r) => setState(() {
                  _kind = k;
                  _range = r;
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(children: [
                  box('إجمالي الفواتير', Money.withCurrency(d.totalInvoices, cur), kOrange),
                  const SizedBox(width: 8),
                  box('إجمالي الدفعات', Money.withCurrency(d.totalPayments, cur), kGreen),
                  const SizedBox(width: 8),
                  box('الرصيد النهائي', Money.withCurrency(closing.abs(), cur), statusColor(st)),
                ]),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: d.rows.isEmpty && d.openingBalance == 0
                      ? const EmptyState(
                          icon: Icons.description_outlined,
                          title: 'لا توجد حركات',
                          message: 'لا توجد حركات لهذا المورد ضمن الفترة المحددة.',
                        )
                      : DataTableLite(
                          minWidth: 640,
                          columns: const [
                            TableCol('التاريخ', 2),
                            TableCol('البيان', 3.2),
                            TableCol('رقم الفاتورة', 2),
                            TableCol('مدين (فواتير)', 2.4, end: true),
                            TableCol('دائن (دفعات)', 2.4, end: true),
                            TableCol('الرصيد', 2.4, end: true),
                          ],
                          rowCount: d.rows.length,
                          leadingCells: (_range.isAll && d.openingBalance == 0)
                              ? null
                              : [
                                  cellText(''),
                                  cellText('الرصيد الافتتاحي', bold: true),
                                  cellText(''),
                                  cellText(''),
                                  cellText(''),
                                  cellText(Money.format(d.openingBalance), bold: true),
                                ],
                          cellBuilder: (ctx, r, c) {
                            final row = d.rows[r];
                            final e = row.entry;
                            switch (c) {
                              case 0:
                                return cellText(fmtShort(e.date));
                              case 1:
                                return cellText(e.notes.isEmpty ? e.description : '${e.description}\n${e.notes}');
                              case 2:
                                return cellText(e.isInvoice && e.ref.isNotEmpty ? e.ref : '—');
                              case 3:
                                return cellText(e.isInvoice ? Money.format(e.amount) : '—', color: e.isInvoice ? kOrange : null, bold: e.isInvoice);
                              case 4:
                                return cellText(e.isInvoice ? '—' : Money.format(e.amount), color: e.isInvoice ? null : kGreen, bold: !e.isInvoice);
                              default:
                                return cellText(Money.format(row.balanceAfter), bold: true);
                            }
                          },
                          footer: [
                            cellText(''),
                            cellText('الإجمالي', bold: true),
                            cellText(''),
                            cellText(Money.format(d.totalInvoices), bold: true),
                            cellText(Money.format(d.totalPayments), bold: true),
                            cellText(Money.format(closing), bold: true),
                          ],
                        ),
                ),
              ),
              ReportActions(
                title: 'كشف حساب ${d.supplier.name}',
                fileName: 'كشف_حساب_${d.supplier.name}_${isoDate(today())}',
                shareLabel: 'مشاركة كشف الحساب',
                build: () => statementPdf(_last ?? d, business),
              ),
            ],
          );
        },
      ),
    );
  }
}
