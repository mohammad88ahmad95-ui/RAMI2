import 'package:flutter_test/flutter_test.dart';
import 'package:rami/core/money.dart';
import 'package:rami/core/text_utils.dart';
import 'package:rami/models/period.dart';
import 'package:rami/models/supplier.dart';

SupplierSummary _s(String name, int inv, int pay, {String? li, String? lp}) => SupplierSummary(
      supplier: Supplier(id: name.hashCode, name: name),
      totalInvoices: inv,
      totalPayments: pay,
      invoiceCount: 1,
      paymentCount: 1,
      lastInvoiceDate: li,
      lastPaymentDate: lp,
    );

void main() {
  group('Money', () {
    test('parse', () {
      expect(Money.parse('2,500,000'), 250000000);
      expect(Money.parse('1500.5'), 150050);
      expect(Money.parse('١٢٣٤'), 123400);
      expect(Money.parse('abc'), isNull);
      expect(Money.parse(''), isNull);
    });
    test('format', () {
      expect(Money.format(250000000), '2,500,000');
      expect(Money.format(150050), '1,500.50');
      expect(Money.withCurrency(100, 'SYP'), '1 ل.س');
    });
  });

  group('Balance & status', () {
    test('due / settled / credit computed from movements', () {
      expect(_s('a', 250000000, 100000000).balance, 150000000);
      expect(_s('a', 250000000, 100000000).status, AccountStatus.due);
      expect(_s('b', 5, 5).status, AccountStatus.settled);
      expect(_s('c', 5, 9).status, AccountStatus.credit);
    });
    test('last movement', () {
      final s = _s('a', 1, 1, li: '2026-10-01', lp: '2026-10-05');
      expect(s.lastMovementDate, '2026-10-05');
    });
  });

  group('Search & sort', () {
    final list = [_s('شركة النور', 30, 0), _s('شركة الأمل', 10, 10), _s('مؤسسة البركة', 20, 5)];
    test('arabic normalization', () {
      expect(normalizeForSearch('الأمل'), normalizeForSearch('الامل'));
      expect(applySupplierView(list, query: 'الامل').length, 1);
    });
    test('filter + sort', () {
      final due = applySupplierView(list, filter: SupplierFilter.due, sort: SupplierSort.highestDue);
      expect(due.map((e) => e.supplier.name).toList(), ['شركة النور', 'مؤسسة البركة']);
    });
  });

  group('Periods', () {
    final now = DateTime(2026, 10, 8); // Thursday
    test('month', () {
      final r = DateRange.forKind(PeriodKind.month, now: now);
      expect(r.fromIso, '2026-10-01');
      expect(r.toIso, '2026-10-31');
    });
    test('last month', () {
      final r = DateRange.forKind(PeriodKind.lastMonth, now: now);
      expect(r.fromIso, '2026-09-01');
      expect(r.toIso, '2026-09-30');
    });
    test('week starts Saturday', () {
      final r = DateRange.forKind(PeriodKind.week, now: now);
      expect(r.fromIso, '2026-10-03');
    });
  });
}
