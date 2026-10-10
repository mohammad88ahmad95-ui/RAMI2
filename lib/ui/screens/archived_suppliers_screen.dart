import 'package:flutter/material.dart';

import '../../core/errors.dart';
import '../../data/supplier_repository.dart';
import '../../models/supplier.dart';
import '../widgets/common.dart';
import '../widgets/supplier_card.dart';
import 'supplier_detail_screen.dart';

class ArchivedSuppliersScreen extends StatelessWidget {
  const ArchivedSuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الموردون المؤرشفون')),
      body: DataLoader<List<SupplierSummary>>(
        load: () => SupplierRepository.instance.summaries(archived: true),
        skeleton: const SkeletonList(count: 4),
        builder: (context, list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'لا يوجد موردون مؤرشفون',
              message: 'المورد المؤرشف يختفي من القائمة الرئيسية ويحتفظ بكل بياناته.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final s = list[i];
              return Column(children: [
                SupplierCard(
                  summary: s,
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => SupplierDetailScreen(supplierId: s.id))),
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed: () async {
                      try {
                        await SupplierRepository.instance.setArchived(s.id, false);
                        if (context.mounted) showSnack(context, 'تم استرجاع المورد');
                      } catch (e) {
                        if (context.mounted) showSnack(context, friendlyError(e), error: true);
                      }
                    },
                    icon: const Icon(Icons.unarchive_rounded),
                    label: const Text('استرجاع'),
                  ),
                ),
              ]);
            },
          );
        },
      ),
    );
  }
}
