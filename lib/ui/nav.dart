import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'screens/invoice_form_screen.dart';
import 'screens/payment_form_screen.dart';
import 'screens/statement_screen.dart';
import 'screens/supplier_form_screen.dart';
import 'widgets/common.dart';
import 'widgets/supplier_picker.dart';

void openNewSupplier(BuildContext c) =>
    Navigator.push(c, MaterialPageRoute(builder: (_) => const SupplierFormScreen()));

void openNewInvoice(BuildContext c) =>
    Navigator.push(c, MaterialPageRoute(builder: (_) => const InvoiceFormScreen()));

void openNewPayment(BuildContext c) =>
    Navigator.push(c, MaterialPageRoute(builder: (_) => const PaymentFormScreen()));

Future<void> openStatementPicker(BuildContext c) async {
  final s = await pickSupplier(c);
  if (s != null && c.mounted) {
    Navigator.push(c, MaterialPageRoute(builder: (_) => StatementScreen(supplierId: s.id)));
  }
}

/// القائمة السريعة: إضافة مورد / فاتورة شراء / دفعة من أي مكان.
void showQuickAddSheet(BuildContext context) {
  showRamiSheet<void>(
    context,
    (ctx) => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SheetOption(
          icon: Icons.receipt_long_rounded,
          title: 'فاتورة شراء',
          subtitle: 'تسجيل فاتورة جديدة من مورد',
          onTap: () {
            Navigator.pop(ctx);
            openNewInvoice(context);
          },
        ),
        SheetOption(
          icon: Icons.payments_rounded,
          title: 'دفعة',
          subtitle: 'تسجيل مبلغ دفعته لمورد',
          color: kGreen,
          onTap: () {
            Navigator.pop(ctx);
            openNewPayment(context);
          },
        ),
        SheetOption(
          icon: Icons.person_add_alt_1_rounded,
          title: 'مورد جديد',
          subtitle: 'إضافة مورد إلى القائمة',
          color: kBlue,
          onTap: () {
            Navigator.pop(ctx);
            openNewSupplier(context);
          },
        ),
      ]),
    ),
  );
}
