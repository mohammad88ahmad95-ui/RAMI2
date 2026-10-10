import 'dart:typed_data';

import '../core/constants.dart';
import '../core/dates.dart';
import '../core/money.dart';
import '../core/theme.dart';
import '../models/ledger_entry.dart';
import '../models/period.dart';
import '../models/statement.dart';
import '../models/supplier.dart';
import 'pdf_report.dart';

String _m(int minor, String currency) => Money.withCurrency(minor, currency);

/// كشف حساب مورد (مدين = فواتير الشراء، دائن = الدفعات، كما في كشف المورد).
Future<Uint8List> statementPdf(StatementData d, String businessName) {
  final cur = d.currency;
  final s = d.supplier;
  final closing = d.closingBalance;
  final status = closing > 0
      ? AccountStatus.due
      : closing == 0
          ? AccountStatus.settled
          : AccountStatus.credit;
  final rows = [
    for (final r in d.rows)
      [
        fmtShort(r.entry.date),
        r.entry.notes.isEmpty ? r.entry.description : '${r.entry.description} - ${r.entry.notes}',
        r.entry.isInvoice ? r.entry.ref : '',
        r.entry.isInvoice ? Money.format(r.entry.amount) : '',
        r.entry.isInvoice ? '' : Money.format(r.entry.amount),
        Money.format(r.balanceAfter),
      ],
  ];
  return buildPdfReport(PdfReportSpec(
    title: 'كشف حساب مورد',
    businessName: businessName,
    subtitleLines: [
      'المورد: ${s.name}${s.company.isEmpty ? '' : ' - ${s.company}'}',
      if (s.phone.isNotEmpty) 'الهاتف: ${s.phone}',
      'الفترة: ${d.range.label}',
      'العملة: ${currencySymbol(cur)}',
    ],
    summary: [
      PdfSummaryItem('إجمالي الفواتير', _m(d.totalInvoices, cur)),
      PdfSummaryItem('إجمالي الدفعات', _m(d.totalPayments, cur)),
      PdfSummaryItem('الرصيد النهائي (${balanceCaption(status)})', _m(closing.abs(), cur)),
    ],
    columns: const [
      PdfColumn('التاريخ', 2),
      PdfColumn('البيان', 4),
      PdfColumn('رقم الفاتورة', 2),
      PdfColumn('مدين (فواتير)', 3, numeric: true),
      PdfColumn('دائن (دفعات)', 3, numeric: true),
      PdfColumn('الرصيد', 3, numeric: true),
    ],
    openingRow: d.openingBalance == 0 && d.range.isAll
        ? null
        : ['', 'الرصيد الافتتاحي', '', '', '', Money.format(d.openingBalance)],
    rows: rows,
    footerRow: ['', 'الإجمالي', '', Money.format(d.totalInvoices), Money.format(d.totalPayments), Money.format(closing)],
    emptyMessage: 'لا توجد حركات ضمن هذه الفترة.',
  ));
}

/// كشف حساب جميع الموردين.
Future<Uint8List> suppliersReportPdf({
  required List<SupplierSummary> rows,
  required String currency,
  required String filterLabel,
  required String sortLabel,
  required String businessName,
}) {
  var inv = 0, pay = 0, bal = 0;
  for (final r in rows) {
    inv += r.totalInvoices;
    pay += r.totalPayments;
    bal += r.balance;
  }
  return buildPdfReport(PdfReportSpec(
    title: 'كشف حساب الموردين',
    businessName: businessName,
    subtitleLines: [
      'العملة: ${currencySymbol(currency)}',
      'التصفية: $filterLabel · الترتيب: $sortLabel',
      'عدد الموردين: ${rows.length}',
    ],
    summary: [
      PdfSummaryItem('إجمالي الفواتير', _m(inv, currency)),
      PdfSummaryItem('إجمالي الدفعات', _m(pay, currency)),
      PdfSummaryItem('صافي الرصيد', _m(bal, currency)),
    ],
    columns: const [
      PdfColumn('المورد', 5),
      PdfColumn('إجمالي الفواتير', 3, numeric: true),
      PdfColumn('إجمالي الدفعات', 3, numeric: true),
      PdfColumn('الرصيد المستحق', 3, numeric: true),
      PdfColumn('الحالة', 2),
    ],
    rows: [
      for (final r in rows)
        [
          r.supplier.company.isEmpty ? r.supplier.name : '${r.supplier.name} (${r.supplier.company})',
          Money.format(r.totalInvoices),
          Money.format(r.totalPayments),
          Money.format(r.balance),
          r.status.label,
        ],
    ],
    footerRow: ['الإجمالي', Money.format(inv), Money.format(pay), Money.format(bal), ''],
    emptyMessage: 'لا يوجد موردون مطابقون.',
  ));
}

/// تقرير الفواتير أو الدفعات خلال فترة.
Future<Uint8List> periodReportPdf({
  required EntryType type,
  required List<LedgerEntry> entries,
  required DateRange range,
  required String currency,
  required String businessName,
}) {
  final isInv = type == EntryType.invoice;
  var total = 0;
  for (final e in entries) {
    total += e.amount;
  }
  return buildPdfReport(PdfReportSpec(
    title: isInv ? 'تقرير فواتير الشراء' : 'تقرير الدفعات',
    businessName: businessName,
    subtitleLines: [
      'الفترة: ${range.label}',
      'العملة: ${currencySymbol(currency)}',
    ],
    summary: [
      PdfSummaryItem(isInv ? 'عدد الفواتير' : 'عدد الدفعات', '${entries.length}'),
      PdfSummaryItem(isInv ? 'إجمالي الفواتير' : 'إجمالي الدفعات', _m(total, currency)),
    ],
    columns: [
      const PdfColumn('التاريخ', 2),
      const PdfColumn('المورد', 4),
      PdfColumn(isInv ? 'رقم الفاتورة' : 'طريقة الدفع', 3),
      const PdfColumn('ملاحظات', 4),
      const PdfColumn('المبلغ', 3, numeric: true),
    ],
    rows: [
      for (final e in entries)
        [
          fmtShort(e.date),
          e.supplierName,
          isInv ? (e.ref.isEmpty ? '—' : e.ref) : e.methodLabel,
          e.notes,
          Money.format(e.amount),
        ],
    ],
    footerRow: ['', 'الإجمالي (${entries.length})', '', '', Money.format(total)],
  ));
}

/// المستحقات الحالية (الموردون الذين عليهم رصيد).
Future<Uint8List> dueReportPdf({
  required List<SupplierSummary> rows,
  required String currency,
  required String businessName,
}) {
  var total = 0;
  for (final r in rows) {
    total += r.balance;
  }
  return buildPdfReport(PdfReportSpec(
    title: 'تقرير المستحقات الحالية',
    businessName: businessName,
    subtitleLines: [
      'العملة: ${currencySymbol(currency)}',
      'بتاريخ: ${fmtLong(today())}',
    ],
    summary: [
      PdfSummaryItem('عدد الموردين المستحقين', '${rows.length}'),
      PdfSummaryItem('إجمالي المستحقات', _m(total, currency)),
    ],
    columns: const [
      PdfColumn('#', 1),
      PdfColumn('المورد', 5),
      PdfColumn('الهاتف', 3),
      PdfColumn('آخر حركة', 3),
      PdfColumn('المبلغ المستحق', 3, numeric: true),
    ],
    rows: [
      for (var i = 0; i < rows.length; i++)
        [
          '${i + 1}',
          rows[i].supplier.company.isEmpty
              ? rows[i].supplier.name
              : '${rows[i].supplier.name} (${rows[i].supplier.company})',
          rows[i].supplier.phone.isEmpty ? '—' : rows[i].supplier.phone,
          rows[i].lastMovementDate == null ? '—' : fmtShort(rows[i].lastMovementDate!),
          Money.format(rows[i].balance),
        ],
    ],
    footerRow: ['', 'الإجمالي', '', '', Money.format(total)],
    emptyMessage: 'لا توجد مستحقات حالياً. جميع الحسابات مسددة.',
  ));
}
