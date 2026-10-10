import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../data/supplier_repository.dart';
import '../../models/supplier.dart';
import '../screens/supplier_form_screen.dart';
import 'common.dart';

/// اختيار مورد من قائمة قابلة للبحث (مع إمكانية إضافة مورد جديد).
Future<SupplierSummary?> pickSupplier(BuildContext context, {int? selectedId}) {
  return showRamiSheet<SupplierSummary>(
    context,
    (ctx) => _PickerSheet(selectedId: selectedId),
  );
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({this.selectedId});
  final int? selectedId;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _addNew({String initialName = ''}) async {
    final id = await Navigator.of(context).push<int>(MaterialPageRoute(
      builder: (_) => SupplierFormScreen(returnIdOnly: true, initialName: initialName),
    ));
    if (id == null) return;
    final s = await SupplierRepository.instance.summary(id);
    if (mounted && s != null) Navigator.pop(context, s);
  }

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.78,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'ابحث بالاسم أو الهاتف أو الشركة',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: DataLoader<List<SupplierSummary>>(
              load: () => SupplierRepository.instance.summaries(),
              skeleton: const SkeletonList(count: 4, height: 68),
              builder: (context, all) {
                final list = applySupplierView(all, query: _search.text, sort: SupplierSort.name);
                if (all.isEmpty) {
                  return EmptyState(
                    icon: Icons.storefront_rounded,
                    title: 'لم تضف أي مورد بعد',
                    message: 'ابدأ بإضافة أول مورد لمتابعة حساباته.',
                    actionLabel: 'إضافة مورد',
                    onAction: _addNew,
                  );
                }
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'لا توجد نتائج',
                    message: 'لم نجد مورداً مطابقاً لبحثك.',
                    actionLabel: 'إضافة مورد جديد',
                    onAction: () => _addNew(initialName: _search.text.trim()),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: list.length + 1,
                  itemBuilder: (context, i) {
                    if (i == list.length) {
                      return TextButton.icon(
                        onPressed: _addNew,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('إضافة مورد جديد'),
                      );
                    }
                    final s = list[i];
                    final sel = s.id == widget.selectedId;
                    return ListTile(
                      onTap: () => Navigator.pop(context, s),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      tileColor: sel ? pal.softOrange : null,
                      leading: AvatarCircle(s.supplier.name, size: 42, color: statusColor(s.status)),
                      title: Text(s.supplier.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(
                        s.supplier.company.isNotEmpty ? s.supplier.company : s.supplier.phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        Money.withCurrency(s.balance.abs(), s.currency),
                        style: TextStyle(color: statusColor(s.status), fontWeight: FontWeight.w800),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
