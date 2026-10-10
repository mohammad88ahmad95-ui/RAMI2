import 'package:flutter/material.dart';

import '../../core/text_utils.dart';
import '../../core/theme.dart';
import '../../data/supplier_repository.dart';
import '../../models/supplier.dart';
import '../widgets/common.dart';
import '../widgets/supplier_card.dart';
import 'archived_suppliers_screen.dart';
import 'supplier_detail_screen.dart';
import 'supplier_form_screen.dart';

/// تبويب الموردون: بحث فوري + فلترة + ترتيب.
class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _search = TextEditingController();
  SupplierFilter _filter = SupplierFilter.all;
  SupplierSort _sort = SupplierSort.highestDue;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _add({String name = ''}) {
    final digits = onlyDigits(name);
    final isPhone = digits.length >= 5 && digits.length == name.replaceAll(RegExp(r'[\s+\-]'), '').length;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SupplierFormScreen(
          initialName: isPhone ? '' : name,
          initialPhone: isPhone ? name : '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
            child: Row(children: [
              const Expanded(child: Text('الموردون', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900))),
              PopupMenuButton<SupplierSort>(
                tooltip: 'ترتيب',
                icon: const Icon(Icons.sort_rounded),
                initialValue: _sort,
                onSelected: (v) => setState(() => _sort = v),
                itemBuilder: (_) => [
                  for (final s in SupplierSort.values) PopupMenuItem(value: s, child: Text(s.label)),
                ],
              ),
              IconButton(
                tooltip: 'الموردون المؤرشفون',
                icon: const Icon(Icons.inventory_2_outlined),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArchivedSuppliersScreen())),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو الهاتف أو الشركة',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(_search.clear),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: SupplierFilter.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = SupplierFilter.values[i];
                return RamiChip(label: f.label, selected: _filter == f, onTap: () => setState(() => _filter = f));
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: DataLoader<List<SupplierSummary>>(
              load: () => SupplierRepository.instance.summaries(),
              skeleton: const SkeletonList(),
              builder: (context, all) {
                if (all.isEmpty) {
                  return EmptyState(
                    icon: Icons.storefront_rounded,
                    title: 'لم تضف أي مورد بعد',
                    message: 'ابدأ بإضافة أول مورد لمتابعة حساباته.',
                    actionLabel: 'إضافة مورد',
                    onAction: _add,
                  );
                }
                final list = applySupplierView(all, query: _search.text, filter: _filter, sort: _sort);
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'لا توجد نتائج',
                    message: 'لم نجد موردين مطابقين. جرّب كلمة أخرى أو غيّر التصفية.',
                    actionLabel: 'إضافة مورد جديد',
                    onAction: () => _add(name: _search.text.trim()),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                  itemCount: list.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8, right: 4),
                        child: Text('${list.length} مورد · ${_sort.label}',
                            style: TextStyle(color: pal.muted, fontSize: 12.5)),
                      );
                    }
                    final s = list[i - 1];
                    return SupplierCard(
                      summary: s,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SupplierDetailScreen(supplierId: s.id)),
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
