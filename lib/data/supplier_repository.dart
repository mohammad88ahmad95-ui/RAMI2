import '../core/errors.dart';
import '../models/supplier.dart';
import 'database.dart';

class SupplierRepository {
  SupplierRepository._();
  static final SupplierRepository instance = SupplierRepository._();
  final _db = AppDatabase.instance;

  static const String _select = '''
SELECT s.*,
  COALESCE((SELECT SUM(i.amount) FROM purchase_invoices i WHERE i.supplier_id = s.id), 0) AS total_invoices,
  COALESCE((SELECT SUM(p.amount) FROM payments p WHERE p.supplier_id = s.id), 0) AS total_payments,
  (SELECT COUNT(*) FROM purchase_invoices i WHERE i.supplier_id = s.id) AS invoice_count,
  (SELECT COUNT(*) FROM payments p WHERE p.supplier_id = s.id) AS payment_count,
  (SELECT MAX(i.date) FROM purchase_invoices i WHERE i.supplier_id = s.id) AS last_invoice_date,
  (SELECT MAX(p.date) FROM payments p WHERE p.supplier_id = s.id) AS last_payment_date
FROM suppliers s
''';

  /// الموردون (النشطون أو المؤرشفون) مع أرصدتهم المحسوبة من الحركات.
  Future<List<SupplierSummary>> summaries({bool archived = false}) => _db.read((db) async {
        final rows = await db.rawQuery('$_select WHERE s.archived = ?', [archived ? 1 : 0]);
        return rows.map(SupplierSummary.fromMap).toList();
      });

  Future<SupplierSummary?> summary(int id) => _db.read((db) async {
        final rows = await db.rawQuery('$_select WHERE s.id = ?', [id]);
        if (rows.isEmpty) return null;
        return SupplierSummary.fromMap(rows.first);
      });

  Future<Supplier?> getById(int id) => _db.read((db) async {
        final rows = await db.query('suppliers', where: 'id = ?', whereArgs: [id], limit: 1);
        return rows.isEmpty ? null : Supplier.fromMap(rows.first);
      });

  Future<int> insert(Supplier s) => _db.write((db) async {
        _validate(s);
        final now = nowIso();
        final map = s.toMap()
          ..remove('id')
          ..['name'] = s.name.trim()
          ..['created_at'] = now
          ..['updated_at'] = now;
        return db.insert('suppliers', map);
      });

  Future<void> update(Supplier s) => _db.write((db) async {
        _validate(s);
        final id = s.id;
        if (id == null) throw const AppException(kSaveError);
        final old = await db.query('suppliers', where: 'id = ?', whereArgs: [id], limit: 1);
        if (old.isEmpty) throw const AppException('المورد غير موجود');
        if (old.first['currency'] != s.currency) {
          final c = await db.rawQuery(
              'SELECT (SELECT COUNT(*) FROM purchase_invoices WHERE supplier_id = ?) + (SELECT COUNT(*) FROM payments WHERE supplier_id = ?) AS c',
              [id, id]);
          if (((c.first['c'] as int?) ?? 0) > 0) {
            throw const AppException('لا يمكن تغيير عملة مورد لديه حركات');
          }
        }
        await db.update(
          'suppliers',
          {
            'name': s.name.trim(),
            'phone': s.phone.trim(),
            'company': s.company.trim(),
            'address': s.address.trim(),
            'notes': s.notes.trim(),
            'currency': s.currency,
            'updated_at': nowIso(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      });

  Future<void> setArchived(int id, bool archived) => _db.write((db) async {
        await db.update('suppliers', {'archived': archived ? 1 : 0, 'updated_at': nowIso()},
            where: 'id = ?', whereArgs: [id]);
      });

  /// حذف نهائي للمورد وجميع حركاته (ON DELETE CASCADE).
  Future<void> delete(int id) => _db.write((db) async {
        await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
      });

  void _validate(Supplier s) {
    if (s.name.trim().isEmpty) throw const AppException('يرجى إدخال اسم المورد');
  }
}
