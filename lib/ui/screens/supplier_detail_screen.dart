import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/errors.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../data/ledger_repository.dart';
import '../../data/supplier_repository.dart';
import '../../models/ledger_entry.dart';
import '../../models/supplier.dart';
import '../widgets/common.dart';
import '../widgets/entry_tile.dart';
import 'invoice_form_screen.dart';
import 'payment_form_screen.dart';
import 'statement_screen.dart';
import 'supplier_form_screen.dart';

class _Detail {
  final SupplierSummary? summary;
  final List<LedgerEntry> entries;
  _Detail(this.summary, this.entries);
}

class SupplierDetailScreen extends StatelessWidget {
  const SupplierDetailScreen({super.key, required this.supplierId});
  final int supplierId;

  Future<_Detail> _load() async {
    final s = await SupplierRepository.instance.summary(supplierId);
    if (s == null) return _Detail(null, const []);
    final e = await LedgerRepository.instance.query(supplierId: supplierId, includeArchived: true);
    return _Detail(s, e);
  }

  @override
  Widget build(BuildContext context) {
    return DataLoader<_Detail>(
      load: _load,
      skeleton: Scaffold(appBar: AppBar(), body: const SkeletonList(count: 4, height: 110)),
      builder: (context, d) {
        if (d.summary == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && Navigator.canPop(context)) Navigator.pop(context);
          });
          return const Scaffold(body: SizedBox.shrink());
        }
        return _Body(summary: d.summary!, entries: d.entries);
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.summary, required this.entries});
  final SupplierSummary summary;
  final List<LedgerEntry> entries;

  void _addMenu(BuildContext context) {
    showRamiSheet<void>(context, (ctx) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SheetOption(
              icon: Icons.receipt_long_rounded,
              title: 'فاتورة شراء',
              subtitle: 'تزيد المبلغ المستحق للمورد',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceFormScreen(supplierId: summary.id)));
              },
            ),
            SheetOption(
              icon: Icons.payments_rounded,
              title: 'دفعة',
              subtitle: 'تخفض المبلغ المستحق للمورد',
              color: kGreen,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentFormScreen(supplierId: summary.id)));
              },
            ),
          ]),
        ));
  }

  Future<void> _menu(BuildContext context, String v) async {
    final repo = SupplierRepository.instance;
    try {
      if (v == 'edit') {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => SupplierFormScreen(supplierId: summary.id)));
      } else if (v == 'archive') {
        final due = summary.balance != 0;
        final ok = await confirmDialog(
          context,
          title: 'أرشفة المورد',
          message: due
              ? 'سيختفي المورد من القائمة الرئيسية وتُستثنى مبالغه من إجماليات لوحة الرئيسية والتقارير، مع الاحتفاظ بكل بياناته. رصيده الحالي ليس صفراً، هل تريد المتابعة؟'
              : 'سيختفي المورد من القائمة الرئيسية مع الاحتفاظ بكل بياناته، ويمكنك استرجاعه في أي وقت.',
          confirmLabel: 'أرشفة',
        );
        if (!ok) return;
        await repo.setArchived(summary.id, true);
        if (context.mounted) {
          showSnack(context, 'تمت أرشفة المورد');
          Navigator.pop(context);
        }
      } else if (v == 'unarchive') {
        await repo.setArchived(summary.id, false);
        if (context.mounted) showSnack(context, 'تم استرجاع المورد');
      } else if (v == 'delete') {
        final has = summary.movementCount > 0;
        final ok = await confirmDialog(
          context,
          title: 'حذف المورد نهائياً',
          message: has
              ? 'هذا المورد لديه ${summary.movementCount} حركة (فواتير ودفعات) وسيتم حذفها جميعاً ولا يمكن التراجع. يُفضّل استخدام "أرشفة المورد" بدلاً من الحذف. هل أنت متأكد؟'
              : 'هل أنت متأكد من حذف هذا المورد؟',
          confirmLabel: 'حذف نهائي',
          destructive: true,
        );
        if (!ok) return;
        await repo.delete(summary.id);
        if (context.mounted) {
          showSnack(context, 'تم حذف المورد');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (context.mounted) showSnack(context, friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    final s = summary;
    final sup = s.supplier;
    final color = statusColor(s.status);
    Widget stat(String label, String value, {Color? c}) => Expanded(
          child: RamiCard(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            radius: 16,
            child: Column(children: [
              FittedBox(
                child: Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: c)),
              ),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: pal.muted, fontSize: 11.5), textAlign: TextAlign.center),
            ]),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(sup.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => _menu(context, v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('تعديل بيانات المورد')),
              PopupMenuItem(value: sup.archived ? 'unarchive' : 'archive', child: Text(sup.archived ? 'استرجاع المورد' : 'أرشفة المورد')),
              const PopupMenuItem(value: 'delete', child: Text('حذف المورد', style: TextStyle(color: kRed))),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addMenu(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة حركة'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                RamiCard(
                  child: Column(children: [
                    Row(children: [
                      AvatarCircle(sup.name, color: color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(sup.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                          if (sup.company.isNotEmpty) Text(sup.company, style: TextStyle(color: pal.muted)),
                        ]),
                      ),
                      if (sup.archived)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: pal.field, borderRadius: BorderRadius.circular(20)),
                          child: Text('مؤرشف', style: TextStyle(color: pal.muted, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                    ]),
                    if (sup.phone.isNotEmpty || sup.address.isNotEmpty || sup.notes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 6),
                    ],
                    if (sup.phone.isNotEmpty)
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: sup.phone));
                          showSnack(context, 'تم نسخ رقم الهاتف');
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(children: [
                            Icon(Icons.phone_rounded, size: 18, color: pal.muted),
                            const SizedBox(width: 8),
                            Directionality(textDirection: TextDirection.ltr, child: Text(sup.phone, style: const TextStyle(fontWeight: FontWeight.w600))),
                            const Spacer(),
                            Icon(Icons.copy_rounded, size: 16, color: pal.muted),
                          ]),
                        ),
                      ),
                    if (sup.address.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(children: [
                          Icon(Icons.location_on_rounded, size: 18, color: pal.muted),
                          const SizedBox(width: 8),
                          Expanded(child: Text(sup.address)),
                        ]),
                      ),
                    if (sup.notes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(Icons.notes_rounded, size: 18, color: pal.muted),
                          const SizedBox(width: 8),
                          Expanded(child: Text(sup.notes, style: TextStyle(color: pal.muted))),
                        ]),
                      ),
                  ]),
                ),
                const SizedBox(height: 14),
                RamiCard(
                  border: false,
                  padding: const EdgeInsets.all(22),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: s.status == AccountStatus.due
                        ? const [kOrangeLight, kOrangeDeep]
                        : s.status == AccountStatus.settled
                            ? const [Color(0xFF2BC48A), Color(0xFF138A5C)]
                            : const [Color(0xFF5B9DF5), Color(0xFF1F63C9)],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('الرصيد الحالي', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 6),
                      AnimatedMoney(
                        minor: s.balance.abs(),
                        currency: s.currency,
                        style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(20)),
                        child: Text(balanceCaption(s.status),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  stat('إجمالي الفواتير', Money.format(s.totalInvoices), c: kOrange),
                  const SizedBox(width: 8),
                  stat('إجمالي الدفعات', Money.format(s.totalPayments), c: kGreen),
                  const SizedBox(width: 8),
                  stat('الرصيد', Money.format(s.balance), c: color),
                  const SizedBox(width: 8),
                  stat('عدد الحركات', '${s.movementCount}'),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => StatementScreen(supplierId: s.id))),
                      icon: const Icon(Icons.description_rounded, color: kOrange),
                      label: const Text('كشف الحساب'),
                    ),
                  ),
                ]),
                const SectionTitle('الحركات'),
              ]),
            ),
          ),
          if (entries.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 280,
                  child: EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'لا توجد حركات بعد',
                    message: 'سجّل أول فاتورة شراء أو دفعة لهذا المورد.',
                    actionLabel: 'إضافة حركة',
                    onAction: () => _addMenu(context),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList.builder(
                itemCount: entries.length,
                itemBuilder: (_, i) => EntryTile(entry: entries[i]),
              ),
            ),
        ],
      ),
    );
  }
}
