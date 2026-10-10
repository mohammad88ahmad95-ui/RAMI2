import 'ledger_entry.dart';

class Payment {
  final int? id;
  final int supplierId;
  final String date; // yyyy-MM-dd
  final int amount; // أصغر وحدة
  final PaymentMethod method;
  final String notes;
  final String createdAt;
  final String updatedAt;

  const Payment({
    this.id,
    required this.supplierId,
    required this.date,
    required this.amount,
    this.method = PaymentMethod.cash,
    this.notes = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'supplier_id': supplierId,
        'date': date,
        'amount': amount,
        'method': method.code,
        'notes': notes,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory Payment.fromMap(Map<String, Object?> m) => Payment(
        id: m['id'] as int?,
        supplierId: m['supplier_id'] as int,
        date: m['date'] as String,
        amount: m['amount'] as int,
        method: PaymentMethod.fromCode(m['method'] as String?),
        notes: (m['notes'] as String?) ?? '',
        createdAt: (m['created_at'] as String?) ?? '',
        updatedAt: (m['updated_at'] as String?) ?? '',
      );
}
