import '../core/text_utils.dart';
import 'ledger_entry.dart';

class Supplier {
  final int? id;
  final String name;
  final String phone;
  final String company;
  final String address;
  final String notes;
  final String currency;
  final bool archived;
  final String createdAt;
  final String updatedAt;

  const Supplier({
    this.id,
    required this.name,
    this.phone = '',
    this.company = '',
    this.address = '',
    this.notes = '',
    this.currency = 'SYP',
    this.archived = false,
    this.createdAt = '',
    this.updatedAt = '',
  });

  Supplier copyWith({
    String? name,
    String? phone,
    String? company,
    String? address,
    String? notes,
    String? currency,
    bool? archived,
  }) =>
      Supplier(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        company: company ?? this.company,
        address: address ?? this.address,
        notes: notes ?? this.notes,
        currency: currency ?? this.currency,
        archived: archived ?? this.archived,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'company': company,
        'address': address,
        'notes': notes,
        'currency': currency,
        'archived': archived ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory Supplier.fromMap(Map<String, Object?> m) => Supplier(
        id: m['id'] as int?,
        name: (m['name'] as String?) ?? '',
        phone: (m['phone'] as String?) ?? '',
        company: (m['company'] as String?) ?? '',
        address: (m['address'] as String?) ?? '',
        notes: (m['notes'] as String?) ?? '',
        currency: (m['currency'] as String?) ?? 'SYP',
        archived: ((m['archived'] as int?) ?? 0) == 1,
        createdAt: (m['created_at'] as String?) ?? '',
        updatedAt: (m['updated_at'] as String?) ?? '',
      );
}

enum AccountStatus {
  due('مستحق'),
  settled('مسدد'),
  credit('رصيد لصالحنا');

  final String label;
  const AccountStatus(this.label);
}

/// مورد + أرصدته المحسوبة من الحركات (الرصيد لا يُخزَّن أبداً).
class SupplierSummary {
  final Supplier supplier;
  final int totalInvoices;
  final int totalPayments;
  final int invoiceCount;
  final int paymentCount;
  final String? lastInvoiceDate;
  final String? lastPaymentDate;

  const SupplierSummary({
    required this.supplier,
    required this.totalInvoices,
    required this.totalPayments,
    required this.invoiceCount,
    required this.paymentCount,
    this.lastInvoiceDate,
    this.lastPaymentDate,
  });

  int get id => supplier.id!;
  String get currency => supplier.currency;

  /// الرصيد المستحق = إجمالي الفواتير - إجمالي الدفعات
  int get balance => totalInvoices - totalPayments;

  AccountStatus get status {
    final b = balance;
    if (b > 0) return AccountStatus.due;
    if (b == 0) return AccountStatus.settled;
    return AccountStatus.credit;
  }

  int get movementCount => invoiceCount + paymentCount;

  String? get lastMovementDate {
    final a = lastInvoiceDate;
    final b = lastPaymentDate;
    if (a == null) return b;
    if (b == null) return a;
    return a.compareTo(b) > 0 ? a : b;
  }

  EntryType? get lastMovementType {
    final a = lastInvoiceDate;
    final b = lastPaymentDate;
    if (a == null && b == null) return null;
    if (a == null) return EntryType.payment;
    if (b == null) return EntryType.invoice;
    return a.compareTo(b) > 0 ? EntryType.invoice : EntryType.payment;
  }

  factory SupplierSummary.fromMap(Map<String, Object?> m) => SupplierSummary(
        supplier: Supplier.fromMap(m),
        totalInvoices: (m['total_invoices'] as int?) ?? 0,
        totalPayments: (m['total_payments'] as int?) ?? 0,
        invoiceCount: (m['invoice_count'] as int?) ?? 0,
        paymentCount: (m['payment_count'] as int?) ?? 0,
        lastInvoiceDate: m['last_invoice_date'] as String?,
        lastPaymentDate: m['last_payment_date'] as String?,
      );
}

enum SupplierFilter {
  all('جميع الموردين'),
  due('لديهم مستحقات'),
  settled('مسددون'),
  credit('رصيد لصالحنا');

  final String label;
  const SupplierFilter(this.label);
}

enum SupplierSort {
  highestDue('أعلى مبلغ مستحق'),
  lowestDue('أقل مبلغ'),
  name('اسم المورد'),
  latest('أحدث حركة');

  final String label;
  const SupplierSort(this.label);
}

/// تطبيق البحث والفلترة والترتيب محلياً (فوري أثناء الكتابة).
List<SupplierSummary> applySupplierView(
  List<SupplierSummary> source, {
  String query = '',
  SupplierFilter filter = SupplierFilter.all,
  SupplierSort sort = SupplierSort.highestDue,
  String? currency,
}) {
  final q = normalizeForSearch(query);
  final qDigits = onlyDigits(query);
  final out = source.where((s) {
    if (currency != null && s.currency != currency) return false;
    switch (filter) {
      case SupplierFilter.all:
        break;
      case SupplierFilter.due:
        if (s.status != AccountStatus.due) return false;
        break;
      case SupplierFilter.settled:
        if (s.status != AccountStatus.settled) return false;
        break;
      case SupplierFilter.credit:
        if (s.status != AccountStatus.credit) return false;
        break;
    }
    if (q.isEmpty) return true;
    if (normalizeForSearch(s.supplier.name).contains(q)) return true;
    if (normalizeForSearch(s.supplier.company).contains(q)) return true;
    if (qDigits.length >= 2 && onlyDigits(s.supplier.phone).contains(qDigits)) return true;
    return false;
  }).toList();

  int cmpName(SupplierSummary a, SupplierSummary b) =>
      normalizeForSearch(a.supplier.name).compareTo(normalizeForSearch(b.supplier.name));

  switch (sort) {
    case SupplierSort.highestDue:
      out.sort((a, b) {
        final c = b.balance.compareTo(a.balance);
        return c != 0 ? c : cmpName(a, b);
      });
      break;
    case SupplierSort.lowestDue:
      out.sort((a, b) {
        final c = a.balance.compareTo(b.balance);
        return c != 0 ? c : cmpName(a, b);
      });
      break;
    case SupplierSort.name:
      out.sort(cmpName);
      break;
    case SupplierSort.latest:
      out.sort((a, b) {
        final da = a.lastMovementDate ?? '';
        final db = b.lastMovementDate ?? '';
        final c = db.compareTo(da);
        return c != 0 ? c : cmpName(a, b);
      });
      break;
  }
  return out;
}
