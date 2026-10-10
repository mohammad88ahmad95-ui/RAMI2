import 'package:flutter/material.dart';

import '../../core/dates.dart';
import '../../core/errors.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../data/invoice_repository.dart';
import '../../data/payment_repository.dart';
import '../../models/ledger_entry.dart';
import '../screens/invoice_form_screen.dart';
import '../screens/payment_form_screen.dart';
import 'common.dart';

/// حركة واحدة (فاتورة شراء أو دفعة) بتمييز بصري واضح.
class EntryTile extends StatelessWidget {
  const EntryTile({super.key, required this.entry, this.showSupplier = false, this.onTap});
  final LedgerEntry entry;
  final bool showSupplier;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    final inv = entry.isInvoice;
    final color = inv ? kOrange : kGreen;
    final sub = inv
        ? (entry.ref.isEmpty ? null : 'فاتورة #${entry.ref}')
        : 'طريقة الدفع: ${entry.methodLabel}';
    return RamiCard(
      onTap: onTap ?? () => showEntrySheet(context, entry),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      radius: 18,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: alpha(color, 0.14), borderRadius: BorderRadius.circular(14)),
            child: Icon(inv ? Icons.receipt_long_rounded : Icons.payments_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(showSupplier ? entry.supplierName : entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 3),
                Text(
                  [if (showSupplier) entry.title, if (sub != null) sub].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: pal.muted, fontSize: 12.5),
                ),
                const SizedBox(height: 2),
                Text(fmtLongIso(entry.date), style: TextStyle(color: pal.muted, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${Money.signed(entry.amount, plus: inv)} ${currencyShort(entry.currency)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15.5),
          ),
        ],
      ),
    );
  }
}

String currencyShort(String code) => Money.withCurrency(0, code).split(' ').last;

/// تفاصيل الحركة مع التعديل والحذف.
Future<void> showEntrySheet(BuildContext context, LedgerEntry e) async {
  final inv = e.isInvoice;
  final color = inv ? kOrange : kGreen;
  await showRamiSheet<void>(context, (ctx) {
    final pal = Palette.of(ctx);
    Widget line(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 96, child: Text(k, style: TextStyle(color: pal.muted))),
              Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w700))),
            ],
          ),
        );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: alpha(color, 0.14), borderRadius: BorderRadius.circular(16)),
                child: Icon(inv ? Icons.receipt_long_rounded : Icons.payments_rounded, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    Text(e.supplierName, style: TextStyle(color: pal.muted)),
                  ],
                ),
              ),
              Text(Money.withCurrency(e.amount, e.currency),
                  style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          line('التاريخ', fmtLongIso(e.date)),
          if (inv && e.ref.isNotEmpty) line('رقم الفاتورة', e.ref),
          if (!inv) line('طريقة الدفع', e.methodLabel),
          if (e.notes.isNotEmpty) line('ملاحظات', e.notes),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => inv
                          ? InvoiceFormScreen(invoiceId: e.id)
                          : PaymentFormScreen(paymentId: e.id),
                    ));
                  },
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('تعديل'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kRed,
                    side: BorderSide(color: alpha(kRed, 0.5), width: 1.4),
                  ),
                  onPressed: () async {
                    final ok = await confirmDialog(
                      ctx,
                      title: inv ? 'حذف الفاتورة' : 'حذف الدفعة',
                      message:
                          'هل أنت متأكد من حذف هذه الحركة؟\nسيؤثر حذفها على رصيد المورد "${e.supplierName}" وسيُعاد حساب الرصيد تلقائياً.',
                      confirmLabel: 'حذف',
                      destructive: true,
                    );
                    if (!ok) return;
                    try {
                      if (inv) {
                        await InvoiceRepository.instance.delete(e.id);
                      } else {
                        await PaymentRepository.instance.delete(e.id);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) showSnack(context, 'تم حذف الحركة');
                    } catch (err) {
                      if (ctx.mounted) showSnack(ctx, friendlyError(err), error: true);
                    }
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('حذف'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  });
}
