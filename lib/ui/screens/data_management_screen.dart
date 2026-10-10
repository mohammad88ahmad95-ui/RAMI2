import 'package:flutter/material.dart';

import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../services/backup_service.dart';
import '../../services/csv_service.dart';
import '../widgets/common.dart';
import 'archived_suppliers_screen.dart';

class DataManagementScreen extends StatelessWidget {
  const DataManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    Widget tile(IconData icon, String title, String sub, Color c, VoidCallback onTap) => RamiCard(
          onTap: onTap,
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: alpha(c, 0.14), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: c),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                const SizedBox(height: 3),
                Text(sub, style: TextStyle(color: pal.muted, fontSize: 12.5)),
              ]),
            ),
          ]),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة البيانات')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        tile(Icons.inventory_2_rounded, 'الموردون المؤرشفون', 'عرض المؤرشفين واسترجاعهم', kBlue,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArchivedSuppliersScreen()))),
        tile(Icons.table_view_rounded, 'تصدير البيانات (CSV)', 'جدول بكل الحركات يُفتح في Excel', kGreen, () async {
          try {
            await CsvService.exportAllAndShare();
          } catch (e) {
            if (context.mounted) showSnack(context, friendlyError(e), error: true);
          }
        }),
        tile(Icons.delete_forever_rounded, 'حذف جميع البيانات', 'حذف كل الموردين والفواتير والدفعات نهائياً', kRed, () async {
          final ok1 = await confirmDialog(
            context,
            title: 'حذف جميع البيانات',
            message: 'سيتم حذف كل الموردين والفواتير والدفعات نهائياً. يُنصح بتصدير نسخة احتياطية أولاً.',
            confirmLabel: 'متابعة',
            destructive: true,
          );
          if (!ok1 || !context.mounted) return;
          final ok2 = await confirmDialog(
            context,
            title: 'تأكيد أخير',
            message: 'هل أنت متأكد تماماً؟ لا يمكن التراجع عن هذه العملية.',
            confirmLabel: 'نعم، احذف كل شيء',
            destructive: true,
          );
          if (!ok2) return;
          try {
            await BackupService.wipeAll();
            if (context.mounted) showSnack(context, 'تم حذف جميع البيانات');
          } catch (e) {
            if (context.mounted) showSnack(context, friendlyError(e), error: true);
          }
        }),
      ]),
    );
  }
}
