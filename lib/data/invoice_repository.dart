import '../core/constants.dart';
import '../core/dates.dart';
import '../core/errors.dart';
import '../models/purchase_invoice.dart';
import 'database.dart';

class InvoiceRepository {
  InvoiceRepository._();
  static final InvoiceRepository instance = InvoiceRepository._();
  final _db = AppDatabase.instance;

  void _validate(PurchaseInvoice i) {
    if (i.amount <= 0) throw const AppException('قيمة الفاتورة يجب أن تكون أكبر من صفر');
    if (i.amount > kMaxAmountMinor) throw const AppException('قيمة الفاتورة كبيرة جداً');
    if (tryParseIso(i.date) == null) throw const AppException('التاريخ غير صحيح');
  }

  Future<PurchaseInvoice?> getById(int id) => _db.read((db) async {
        final rows = await db.query('purchase_invoices', where: 'id = ?', whereArgs: [id], limit: 1);
        return rows.isEmpty ? null : PurchaseInvoice.fromMap(rows.first);
      });

  Future<int> insert(PurchaseInvoice i) => _db.write((db) async {
        _validate(i);
        final now = nowIso();
        final map = i.toMap()
          ..remove('id')
          ..['invoice_number'] = i.number.trim()
          ..['notes'] = i.notes.trim()
          ..['created_at'] = now
          ..['updated_at'] = now;
        return db.insert('purchase_invoices', map);
      });

  Future<void> update(PurchaseInvoice i) => _db.write((db) async {
        _validate(i);
        if (i.id == null) throw const AppException(kSaveError);
        await db.update(
          'purchase_invoices',
          {
            'invoice_number': i.number.trim(),
            'date': i.date,
            'amount': i.amount,
            'notes': i.notes.trim(),
            'updated_at': nowIso(),
          },
          where: 'id = ?',
          whereArgs: [i.id],
        );
      });

  Future<void> delete(int id) => _db.write((db) async {
        await db.delete('purchase_invoices', where: 'id = ?', whereArgs: [id]);
      });
}
