import 'ledger_entry.dart';
import 'period.dart';
import 'supplier.dart';

class StatementRow {
  final LedgerEntry entry;
  final int balanceAfter;
  const StatementRow(this.entry, this.balanceAfter);
}

/// كشف حساب مورد خلال فترة.
class StatementData {
  final Supplier supplier;
  final DateRange range;
  final int openingBalance;
  final List<StatementRow> rows;
  final int totalInvoices;
  final int totalPayments;

  const StatementData({
    required this.supplier,
    required this.range,
    required this.openingBalance,
    required this.rows,
    required this.totalInvoices,
    required this.totalPayments,
  });

  int get closingBalance => openingBalance + totalInvoices - totalPayments;
  String get currency => supplier.currency;
}
