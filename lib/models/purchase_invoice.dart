class PurchaseInvoice {
  final int? id;
  final int supplierId;
  final String number;
  final String date; // yyyy-MM-dd
  final int amount; // أصغر وحدة
  final String notes;
  final String createdAt;
  final String updatedAt;

  const PurchaseInvoice({
    this.id,
    required this.supplierId,
    this.number = '',
    required this.date,
    required this.amount,
    this.notes = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'supplier_id': supplierId,
        'invoice_number': number,
        'date': date,
        'amount': amount,
        'notes': notes,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory PurchaseInvoice.fromMap(Map<String, Object?> m) => PurchaseInvoice(
        id: m['id'] as int?,
        supplierId: m['supplier_id'] as int,
        number: (m['invoice_number'] as String?) ?? '',
        date: m['date'] as String,
        amount: m['amount'] as int,
        notes: (m['notes'] as String?) ?? '',
        createdAt: (m['created_at'] as String?) ?? '',
        updatedAt: (m['updated_at'] as String?) ?? '',
      );
}
