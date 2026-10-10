import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/dates.dart';
import '../../core/theme.dart';
import '../../data/database.dart';
import '../../data/ledger_repository.dart';
import '../../models/ledger_entry.dart';
import '../widgets/common.dart';
import '../widgets/entry_tile.dart';

/// تبويب الحركات: كل الفواتير والدفعات مع بحث وتصفية وتحميل تدريجي.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  static const _page = 40;
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;
  EntryType? _type;
  final List<LedgerEntry> _items = [];
  bool _loading = true;
  bool _more = true;
  Object? _error;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    AppDatabase.instance.changes.addListener(_reset);
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) _loadMore();
    });
    _reset();
  }

  @override
  void dispose() {
    AppDatabase.instance.changes.removeListener(_reset);
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    final seq = ++_seq;
    try {
      // نعيد تحميل ما عُرض حتى الآن على الأقل ليبقى موضع التمرير
      final count = _items.isEmpty ? _page : _items.length;
      final rows = await LedgerRepository.instance.query(
        type: _type,
        search: _search.text,
        limit: count,
      );
      if (!mounted || seq != _seq) return;
      setState(() {
        _items
          ..clear()
          ..addAll(rows);
        _more = rows.length >= count;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _newQuery() async {
    _items.clear();
    setState(() => _loading = true);
    await _reset();
  }

  Future<void> _loadMore() async {
    if (_loading || !_more) return;
    final seq = _seq;
    _loading = true;
    try {
      final rows = await LedgerRepository.instance.query(
        type: _type,
        search: _search.text,
        limit: _page,
        offset: _items.length,
      );
      if (!mounted || seq != _seq) return;
      setState(() {
        _items.addAll(rows);
        _more = rows.length >= _page;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    // عناصر مجمّعة بالتاريخ
    final widgets = <Widget>[];
    String? lastDate;
    for (final e in _items) {
      if (e.date != lastDate) {
        lastDate = e.date;
        widgets.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
          child: Text(fmtLongIso(e.date), style: TextStyle(color: pal.muted, fontWeight: FontWeight.w700)),
        ));
      }
      widgets.add(EntryTile(entry: e, showSupplier: true));
    }
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text('الحركات', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _search,
              onChanged: (_) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 250), _newQuery);
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'ابحث باسم المورد أو رقم الفاتورة',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _search.clear();
                          _newQuery();
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                RamiChip(label: 'الكل', selected: _type == null, onTap: () { _type = null; _newQuery(); }),
                const SizedBox(width: 8),
                RamiChip(label: 'فواتير الشراء', selected: _type == EntryType.invoice, onTap: () { _type = EntryType.invoice; _newQuery(); }),
                const SizedBox(width: 8),
                RamiChip(label: 'الدفعات', selected: _type == EntryType.payment, onTap: () { _type = EntryType.payment; _newQuery(); }),
              ],
            ),
          ),
          Expanded(
            child: _error != null && _items.isEmpty
                ? EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'تعذّر تحميل الحركات',
                    actionLabel: 'إعادة المحاولة',
                    onAction: _newQuery,
                  )
                : _loading && _items.isEmpty
                    ? const SkeletonList(height: 72)
                    : _items.isEmpty
                        ? EmptyState(
                            icon: Icons.receipt_long_rounded,
                            title: _search.text.isNotEmpty || _type != null ? 'لا توجد نتائج' : 'لا توجد حركات بعد',
                            message: _search.text.isNotEmpty || _type != null
                                ? 'جرّب تغيير البحث أو التصفية.'
                                : 'ستظهر هنا فواتير الشراء والدفعات بعد تسجيلها.',
                          )
                        : ListView(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                            children: [
                              ...widgets,
                              if (_more)
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator(color: kOrange, strokeWidth: 2.5)),
                                ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}
