import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../data/ledger_repository.dart';
import '../../data/supplier_repository.dart';
import '../../models/ledger_entry.dart';
import '../../models/period.dart';
import '../../models/supplier.dart';
import '../../reports/report_builders.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/currency_chips.dart';
import '../widgets/data_table_lite.dart';
import '../widgets/period_selector.dart';
import '../widgets/report_actions.dart';
import 'supplier_detail_screen.dart';

List<String> currenciesOf(List<SupplierSummary> all, String def) {
  final set = <String>{def, ...all.map((s) => s.currency)}.toList();
  set.sort((a, b) => kCurrencies.indexWhere((c) => c.code == a).compareTo(kCurrencies.indexWhere((c) => c.code == b)));
  return set;
}

// ---------------------------------------------------------------- كشف حساب جميع الموردين
class AllSuppliersReportScreen extends StatefulWidget {
  const AllSuppliersReportScreen({super.key});
  @override
  State<AllSuppliersReportScreen> createState() => _AllState();
}

class _AllState extends State<AllSuppliersReportScreen> {
  SupplierFilter _filter = SupplierFilter.all;
  SupplierSort _sort = SupplierSort.highestDue;
  String? _currency;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('كشف حساب الموردين'),
        actions: [
          PopupMenuButton<SupplierSort>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'ترتيب',
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => [for (final s in SupplierSort.values) PopupMenuItem(value: s, child: Text(s.label))],
          ),
        ],
      ),
      body: DataLoader<List<SupplierSummary>>(
        load: () => SupplierRepository.instance.summaries(),
        skeleton: const SkeletonList(),
        builder: (context, all) {
          final currencies = currenciesOf(all, app.defaultCurrency);
          final cur = currencies.contains(_currency) ? _currency! : (currencies.contains(app.activeCurrency) ? app.activeCurrency : app.defaultCurrency);
          final rows = applySupplierView(all, filter: _filter, sort: _sort, currency: cur);
          var inv = 0, pay = 0, bal = 0;
          for (final r in rows) {
            inv += r.totalInvoices;
            pay += r.totalPayments;
            bal += r.balance;
          }
          return Column(children: [
            CurrencyChips(currencies: currencies, selected: cur, onChanged: (c) => setState(() => _currency = c)),
            if (currencies.length > 1) const SizedBox(height: 8),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: SupplierFilter.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final f = SupplierFilter.values[i];
                  return RamiChip(label: f.label, selected: _filter == f, onTap: () => setState(() => _filter = f));
                },
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: rows.isEmpty
                    ? const EmptyState(icon: Icons.groups_2_outlined, title: 'لا يوجد موردون', message: 'لا يوجد موردون مطابقون للتصفية الحالية.')
                    : DataTableLite(
                        minWidth: 620,
                        columns: const [
                          TableCol('المورد', 4),
                          TableCol('إجمالي الفواتير', 3, end: true),
                          TableCol('إجمالي الدفعات', 3, end: true),
                          TableCol('الرصيد المستحق', 3, end: true),
                          TableCol('الحالة', 2.4),
                        ],
                        rowCount: rows.length,
                        cellBuilder: (ctx, r, c) {
                          final s = rows[r];
                          switch (c) {
                            case 0:
                              return InkWell(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SupplierDetailScreen(supplierId: s.id))),
                                child: cellText(s.supplier.name, bold: true),
                              );
                            case 1:
                              return cellText(Money.format(s.totalInvoices));
                            case 2:
                              return cellText(Money.format(s.totalPayments));
                            case 3:
                              return cellText(Money.format(s.balance), bold: true, color: statusColor(s.status));
                            default:
                              return StatusChip(s.status);
                          }
                        },
                        footer: [
                          cellText('الإجمالي (${rows.length})', bold: true),
                          cellText(Money.format(inv), bold: true),
                          cellText(Money.format(pay), bold: true),
                          cellText(Money.format(bal), bold: true),
                          cellText(''),
                        ],
                      ),
              ),
            ),
            ReportActions(
              title: 'كشف حساب الموردين',
              fileName: 'كشف_حساب_الموردين_${isoDate(today())}',
              enabled: rows.isNotEmpty,
              build: () => suppliersReportPdf(
                rows: rows,
                currency: cur,
                filterLabel: _filter.label,
                sortLabel: _sort.label,
                businessName: app.businessName,
              ),
            ),
          ]);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- تقرير الفواتير / الدفعات خلال فترة
class PeriodReportScreen extends StatefulWidget {
  const PeriodReportScreen({super.key, required this.type});
  final EntryType type;
  @override
  State<PeriodReportScreen> createState() => _PeriodState();
}

class _PeriodState extends State<PeriodReportScreen> {
  PeriodKind _kind = PeriodKind.month;
  DateRange _range = DateRange.forKind(PeriodKind.month);
  String? _currency;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isInv = widget.type == EntryType.invoice;
    final title = isInv ? 'تقرير فواتير الشراء' : 'تقرير الدفعات';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: DataLoader<List<SupplierSummary>>(
        load: () => SupplierRepository.instance.summaries(),
        builder: (context, all) {
          final currencies = currenciesOf(all, app.defaultCurrency);
          final cur = currencies.contains(_currency) ? _currency! : (currencies.contains(app.activeCurrency) ? app.activeCurrency : app.defaultCurrency);
          return DataLoader<List<LedgerEntry>>(
            reloadKey: '$cur${_range.fromIso}${_range.toIso}',
            load: () => LedgerRepository.instance.query(type: widget.type, range: _range, currency: cur, newestFirst: false),
            skeleton: const SkeletonList(),
            builder: (context, entries) {
              final total = entries.fold<int>(0, (a, e) => a + e.amount);
              return Column(children: [
                CurrencyChips(currencies: currencies, selected: cur, onChanged: (c) => setState(() => _currency = c)),
                if (currencies.length > 1) const SizedBox(height: 8),
                PeriodSelector(kind: _kind, range: _range, onChanged: (k, r) => setState(() { _kind = k; _range = r; })),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: Row(children: [
                    Expanded(
                      child: RamiCard(
                        padding: const EdgeInsets.all(12),
                        radius: 16,
                        child: Column(children: [
                          Text(isInv ? 'عدد الفواتير' : 'عدد الدفعات', style: TextStyle(color: Palette.of(context).muted, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('${entries.length}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: RamiCard(
                        padding: const EdgeInsets.all(12),
                        radius: 16,
                        child: Column(children: [
                          Text(isInv ? 'إجمالي الفواتير' : 'إجمالي الدفعات', style: TextStyle(color: Palette.of(context).muted, fontSize: 12)),
                          const SizedBox(height: 4),
                          FittedBox(
                            child: Text(Money.withCurrency(total, cur),
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isInv ? kOrange : kGreen)),
                          ),
                        ]),
                      ),
                    ),
                  ]),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: entries.isEmpty
                        ? EmptyState(
                            icon: isInv ? Icons.receipt_long_rounded : Icons.payments_rounded,
                            title: 'لا توجد بيانات',
                            message: 'لا توجد ${isInv ? 'فواتير' : 'دفعات'} ضمن هذه الفترة.',
                          )
                        : DataTableLite(
                            minWidth: 600,
                            columns: [
                              const TableCol('التاريخ', 2.2),
                              const TableCol('المورد', 3.5),
                              TableCol(isInv ? 'رقم الفاتورة' : 'طريقة الدفع', 2.4),
                              const TableCol('المبلغ', 3, end: true),
                            ],
                            rowCount: entries.length,
                            cellBuilder: (ctx, r, c) {
                              final e = entries[r];
                              switch (c) {
                                case 0:
                                  return cellText(fmtShort(e.date));
                                case 1:
                                  return cellText(e.supplierName, bold: true);
                                case 2:
                                  return cellText(isInv ? (e.ref.isEmpty ? '—' : e.ref) : e.methodLabel);
                                default:
                                  return cellText(Money.format(e.amount), bold: true, color: isInv ? kOrange : kGreen);
                              }
                            },
                            footer: [
                              cellText(''),
                              cellText('الإجمالي (${entries.length})', bold: true),
                              cellText(''),
                              cellText(Money.format(total), bold: true),
                            ],
                          ),
                  ),
                ),
                ReportActions(
                  title: title,
                  fileName: '${isInv ? 'تقرير_الفواتير' : 'تقرير_الدفعات'}_${isoDate(today())}',
                  enabled: entries.isNotEmpty,
                  build: () => periodReportPdf(
                    type: widget.type,
                    entries: entries,
                    range: _range,
                    currency: cur,
                    businessName: app.businessName,
                  ),
                ),
              ]);
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- تقرير المستحقات الحالية
class DueReportScreen extends StatefulWidget {
  const DueReportScreen({super.key});
  @override
  State<DueReportScreen> createState() => _DueState();
}

class _DueState extends State<DueReportScreen> {
  String? _currency;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('المستحقات الحالية')),
      body: DataLoader<List<SupplierSummary>>(
        load: () => SupplierRepository.instance.summaries(),
        skeleton: const SkeletonList(),
        builder: (context, all) {
          final currencies = currenciesOf(all, app.defaultCurrency);
          final cur = currencies.contains(_currency) ? _currency! : (currencies.contains(app.activeCurrency) ? app.activeCurrency : app.defaultCurrency);
          final rows = applySupplierView(all, filter: SupplierFilter.due, sort: SupplierSort.highestDue, currency: cur);
          final total = rows.fold<int>(0, (a, s) => a + s.balance);
          return Column(children: [
            CurrencyChips(currencies: currencies, selected: cur, onChanged: (c) => setState(() => _currency = c)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: RamiCard(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: kOrange),
                  const SizedBox(width: 10),
                  Expanded(child: Text('إجمالي المستحقات (${rows.length} مورد)', style: const TextStyle(fontWeight: FontWeight.w700))),
                  Text(Money.withCurrency(total, cur), style: const TextStyle(color: kOrange, fontWeight: FontWeight.w900, fontSize: 17)),
                ]),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: rows.isEmpty
                    ? const EmptyState(icon: Icons.check_circle_outline_rounded, title: 'لا توجد مستحقات', message: 'جميع حسابات الموردين مسددة.')
                    : DataTableLite(
                        minWidth: 560,
                        columns: const [
                          TableCol('#', 0.8),
                          TableCol('المورد', 4),
                          TableCol('آخر حركة', 2.6),
                          TableCol('المبلغ المستحق', 3, end: true),
                        ],
                        rowCount: rows.length,
                        cellBuilder: (ctx, r, c) {
                          final s = rows[r];
                          switch (c) {
                            case 0:
                              return cellText('${r + 1}');
                            case 1:
                              return InkWell(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SupplierDetailScreen(supplierId: s.id))),
                                child: cellText(s.supplier.name, bold: true),
                              );
                            case 2:
                              return cellText(s.lastMovementDate == null ? '—' : fmtShort(s.lastMovementDate!));
                            default:
                              return cellText(Money.format(s.balance), bold: true, color: kOrange);
                          }
                        },
                        footer: [cellText(''), cellText('الإجمالي', bold: true), cellText(''), cellText(Money.format(total), bold: true)],
                      ),
              ),
            ),
            ReportActions(
              title: 'تقرير المستحقات الحالية',
              fileName: 'المستحقات_الحالية_${isoDate(today())}',
              enabled: rows.isNotEmpty,
              build: () => dueReportPdf(rows: rows, currency: cur, businessName: app.businessName),
            ),
          ]);
        },
      ),
    );
  }
}
