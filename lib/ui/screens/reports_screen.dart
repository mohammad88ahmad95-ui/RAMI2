import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/ledger_entry.dart';
import '../nav.dart';
import '../widgets/common.dart';
import 'report_screens.dart';

/// تبويب التقارير: التقارير المرتبطة بالموردين فقط.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    Widget item(IconData icon, String title, String sub, Color c, VoidCallback onTap) => RamiCard(
          onTap: onTap,
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: alpha(c, 0.14), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: c),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 3),
                Text(sub, style: TextStyle(color: pal.muted, fontSize: 12.5)),
              ]),
            ),
            Icon(Icons.chevron_left_rounded, color: pal.muted),
          ]),
        );
    void go(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 16),
            child: Text('التقارير', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          ),
          item(Icons.description_rounded, 'كشف حساب مورد', 'اختر مورداً واستخرج كشف حسابه بأي فترة', kOrange,
              () => openStatementPicker(context)),
          item(Icons.groups_rounded, 'كشف حساب جميع الموردين', 'الفواتير والدفعات والرصيد لكل مورد', kBlue,
              () => go(const AllSuppliersReportScreen())),
          item(Icons.receipt_long_rounded, 'تقرير الفواتير خلال فترة', 'فواتير الشراء المسجلة في فترة محددة', kOrange,
              () => go(const PeriodReportScreen(type: EntryType.invoice))),
          item(Icons.payments_rounded, 'تقرير الدفعات خلال فترة', 'الدفعات المسددة في فترة محددة', kGreen,
              () => go(const PeriodReportScreen(type: EntryType.payment))),
          item(Icons.pending_actions_rounded, 'تقرير المستحقات الحالية', 'الموردون الذين عليك لهم مبالغ الآن', const Color(0xFF8E5CF5),
              () => go(const DueReportScreen())),
        ],
      ),
    );
  }
}
