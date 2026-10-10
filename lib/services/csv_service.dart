import 'dart:convert';

import '../core/constants.dart';
import '../core/dates.dart';
import '../core/errors.dart';
import '../core/money.dart';
import '../data/ledger_repository.dart';
import 'file_service.dart';

/// تصدير كل الحركات إلى CSV (UTF-8 مع BOM ليفتح بالعربية في Excel).
class CsvService {
  CsvService._();

  static String _cell(String s) {
    final needs = s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r');
    final e = s.replaceAll('"', '""');
    return needs ? '"$e"' : e;
  }

  static Future<void> exportAllAndShare() async {
    final entries = await LedgerRepository.instance.everything();
    if (entries.isEmpty) throw const AppException('لا توجد حركات لتصديرها.');
    final b = StringBuffer();
    b.writeln(['التاريخ', 'النوع', 'المورد', 'العملة', 'رقم الفاتورة', 'المبلغ', 'طريقة الدفع', 'ملاحظات']
        .map(_cell)
        .join(','));
    for (final e in entries) {
      b.writeln([
        e.date,
        e.title,
        e.supplierName,
        currencyOf(e.currency).code,
        e.ref,
        Money.toInput(e.amount),
        e.isInvoice ? '' : e.methodLabel,
        e.notes,
      ].map(_cell).join(','));
    }
    final bytes = <int>[0xEF, 0xBB, 0xBF, ...utf8.encode(b.toString())];
    final file = await writeTempFile('rami_movements_${isoDate(DateTime.now())}.csv', bytes);
    await shareFile(file, mime: 'text/csv', subject: 'حركات الموردين - رامي');
  }
}
