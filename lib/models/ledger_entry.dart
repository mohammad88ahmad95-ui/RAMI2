enum EntryType { invoice, payment }

enum PaymentMethod {
  cash('cash', 'نقدي'),
  transfer('transfer', 'تحويل'),
  remittance('remittance', 'حوالة'),
  other('other', 'أخرى');

  final String code;
  final String label;
  const PaymentMethod(this.code, this.label);

  static PaymentMethod fromCode(String? c) =>
      PaymentMethod.values.firstWhere((m) => m.code == c, orElse: () => PaymentMethod.other);
}

/// حركة موحدة (فاتورة شراء أو دفعة) لعرضها في القوائم وكشوف الحساب.
class LedgerEntry {
  final EntryType type;
  final int id;
  final int supplierId;
  final String supplierName;
  final String currency;
  final String date; // yyyy-MM-dd
  final int amount; // أصغر وحدة
  final String ref; // رقم الفاتورة
  final String method; // كود طريقة الدفع
  final String notes;
  final String createdAt;

  const LedgerEntry({
    required this.type,
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.currency,
    required this.date,
    required this.amount,
    required this.ref,
    required this.method,
    required this.notes,
    required this.createdAt,
  });

  bool get isInvoice => type == EntryType.invoice;
  String get title => isInvoice ? 'فاتورة شراء' : 'دفعة';
  String get methodLabel => PaymentMethod.fromCode(method).label;

  /// النص الذي يظهر في خانة البيان.
  String get description {
    if (isInvoice) return ref.isEmpty ? 'فاتورة شراء' : 'فاتورة شراء #$ref';
    return 'دفعة ($methodLabel)';
  }

  factory LedgerEntry.fromMap(Map<String, Object?> m) {
    final isInv = m['type'] == 'invoice';
    return LedgerEntry(
      type: isInv ? EntryType.invoice : EntryType.payment,
      id: m['id'] as int,
      supplierId: m['supplier_id'] as int,
      supplierName: (m['supplier_name'] as String?) ?? '',
      currency: (m['currency'] as String?) ?? 'SYP',
      date: m['date'] as String,
      amount: m['amount'] as int,
      ref: (m['ref'] as String?) ?? '',
      method: (m['method'] as String?) ?? '',
      notes: (m['notes'] as String?) ?? '',
      createdAt: (m['created_at'] as String?) ?? '',
    );
  }
}
