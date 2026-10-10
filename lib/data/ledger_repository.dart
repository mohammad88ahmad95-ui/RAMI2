import '../core/errors.dart';
import '../models/ledger_entry.dart';
import '../models/period.dart';
import '../models/statement.dart';
import 'database.dart';
import 'supplier_repository.dart';

/// استعلامات الحركات الموحدة (فواتير + دفعات) وكشوف الحساب.
class LedgerRepository {
  LedgerRepository._();
  static final LedgerRepository instance = LedgerRepository._();
  final _db = AppDatabase.instance;

  static const String _union = '''
SELECT 'invoice' AS type, i.id AS id, i.supplier_id AS supplier_id, s.name AS supplier_name,
  s.currency AS currency, s.archived AS archived, i.date AS date, i.amount AS amount,
  i.invoice_number AS ref, '' AS method, i.notes AS notes, i.created_at AS created_at
FROM purchase_invoices i JOIN suppliers s ON s.id = i.supplier_id
UNION ALL
SELECT 'payment', p.id, p.supplier_id, s.name, s.currency, s.archived, p.date, p.amount,
  '', p.method, p.notes, p.created_at
FROM payments p JOIN suppliers s ON s.id = p.supplier_id
''';

  Future<List<LedgerEntry>> query({
    EntryType? type,
    int? supplierId,
    String? currency,
    DateRange range = DateRange.all,
    String search = '',
    bool includeArchived = false,
    bool newestFirst = true,
    int? limit,
    int offset = 0,
  }) =>
      _db.read((db) async {
        final where = <String>[];
        final args = <Object?>[];
        if (type != null) {
          where.add('type = ?');
          args.add(type == EntryType.invoice ? 'invoice' : 'payment');
        }
        if (supplierId != null) {
          where.add('supplier_id = ?');
          args.add(supplierId);
        } else if (!includeArchived) {
          where.add('archived = 0');
        }
        if (currency != null) {
          where.add('currency = ?');
          args.add(currency);
        }
        if (range.fromIso != null) {
          where.add('date >= ?');
          args.add(range.fromIso);
        }
        if (range.toIso != null) {
          where.add('date <= ?');
          args.add(range.toIso);
        }
        final q = search.trim();
        if (q.isNotEmpty) {
          where.add('(supplier_name LIKE ? OR ref LIKE ? OR notes LIKE ?)');
          args.addAll(['%$q%', '%$q%', '%$q%']);
        }
        final dir = newestFirst ? 'DESC' : 'ASC';
        final sql = StringBuffer('SELECT * FROM ($_union)');
        if (where.isNotEmpty) sql.write(' WHERE ${where.join(' AND ')}');
        sql.write(' ORDER BY date $dir, created_at $dir, id $dir');
        if (limit != null) {
          sql.write(' LIMIT ? OFFSET ?');
          args.addAll([limit, offset]);
        }
        final rows = await db.rawQuery(sql.toString(), args);
        return rows.map(LedgerEntry.fromMap).toList();
      });

  Future<List<LedgerEntry>> recent(int limit) => query(limit: limit);

  /// كل الحركات (بما فيها المؤرشفة) للتصدير.
  Future<List<LedgerEntry>> everything() => query(includeArchived: true, newestFirst: false);

  Future<StatementData> statement(int supplierId, DateRange range) async {
    final supplier = await SupplierRepository.instance.getById(supplierId);
    if (supplier == null) throw const AppException('المورد غير موجود');

    var opening = 0;
    if (range.fromIso != null) {
      opening = await _db.read((db) async {
        final r = await db.rawQuery(
          '''
SELECT
 COALESCE((SELECT SUM(amount) FROM purchase_invoices WHERE supplier_id = ? AND date < ?), 0) -
 COALESCE((SELECT SUM(amount) FROM payments WHERE supplier_id = ? AND date < ?), 0) AS opening
''',
          [supplierId, range.fromIso, supplierId, range.fromIso],
        );
        return (r.first['opening'] as int?) ?? 0;
      });
    }

    final entries = await query(
      supplierId: supplierId,
      range: range,
      newestFirst: false,
      includeArchived: true,
    );

    var running = opening;
    var inv = 0;
    var pay = 0;
    final rows = <StatementRow>[];
    for (final e in entries) {
      if (e.isInvoice) {
        running += e.amount;
        inv += e.amount;
      } else {
        running -= e.amount;
        pay += e.amount;
      }
      rows.add(StatementRow(e, running));
    }
    return StatementData(
      supplier: supplier,
      range: range,
      openingBalance: opening,
      rows: rows,
      totalInvoices: inv,
      totalPayments: pay,
    );
  }
}
