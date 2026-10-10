import '../core/constants.dart';
import '../core/dates.dart';
import '../core/errors.dart';
import '../models/payment.dart';
import 'database.dart';

class PaymentRepository {
  PaymentRepository._();
  static final PaymentRepository instance = PaymentRepository._();
  final _db = AppDatabase.instance;

  void _validate(Payment p) {
    if (p.amount <= 0) throw const AppException('مبلغ الدفعة يجب أن يكون أكبر من صفر');
    if (p.amount > kMaxAmountMinor) throw const AppException('مبلغ الدفعة كبير جداً');
    if (tryParseIso(p.date) == null) throw const AppException('التاريخ غير صحيح');
  }

  Future<Payment?> getById(int id) => _db.read((db) async {
        final rows = await db.query('payments', where: 'id = ?', whereArgs: [id], limit: 1);
        return rows.isEmpty ? null : Payment.fromMap(rows.first);
      });

  Future<int> insert(Payment p) => _db.write((db) async {
        _validate(p);
        final now = nowIso();
        final map = p.toMap()
          ..remove('id')
          ..['notes'] = p.notes.trim()
          ..['created_at'] = now
          ..['updated_at'] = now;
        return db.insert('payments', map);
      });

  Future<void> update(Payment p) => _db.write((db) async {
        _validate(p);
        if (p.id == null) throw const AppException(kSaveError);
        await db.update(
          'payments',
          {
            'date': p.date,
            'amount': p.amount,
            'method': p.method.code,
            'notes': p.notes.trim(),
            'updated_at': nowIso(),
          },
          where: 'id = ?',
          whereArgs: [p.id],
        );
      });

  Future<void> delete(int id) => _db.write((db) async {
        await db.delete('payments', where: 'id = ?', whereArgs: [id]);
      });
}
