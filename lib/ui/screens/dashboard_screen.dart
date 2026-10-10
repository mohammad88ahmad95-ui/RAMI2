import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../data/ledger_repository.dart';
import '../../data/supplier_repository.dart';
import '../../models/ledger_entry.dart';
import '../../models/supplier.dart';
import '../../state/app_state.dart';
import '../nav.dart';
import '../widgets/common.dart';
import '../widgets/currency_chips.dart';
import '../widgets/entry_tile.dart';
import 'supplier_detail_screen.dart';

class _Dash {
  final List<SupplierSummary> all;
  final List<LedgerEntry> recent;
  _Dash(this.all, this.recent);
}

/// الرئيسية: تركّز على القرار — كم عليّ؟ ومن يحتاج انتباهي؟
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<_Dash> _load() async => _Dash(
        await SupplierRepository.instance.summaries(),
        await LedgerRepository.instance.recent(5),
      );

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return SafeArea(
      bottom: false,
      child: DataLoader<_Dash>(
        load: _load,
        skeleton: ListView(
          padding: const EdgeInsets.all(16),
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            SkeletonBox(height: 40, width: 180),
            SizedBox(height: 16),
            SkeletonBox(height: 190, radius: 28),
            SizedBox(height: 16),
            SkeletonBox(height: 90, radius: 20),
            SizedBox(height: 16),
            SkeletonBox(height: 140, radius: 20),
          ],
        ),
        builder: (context, d) => _Content(data: d, app: app),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.data, required this.app});
  final _Dash data;
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    final currencies = <String>{app.defaultCurrency, ...data.all.map((s) => s.currency)}.toList()
      ..sort((a, b) => kCurrencies.indexWhere((c) => c.code == a).compareTo(kCurrencies.indexWhere((c) => c.code == b)));
    final cur = currencies.contains(app.activeCurrency) ? app.activeCurrency : app.defaultCurrency;
    final list = data.all.where((s) => s.currency == cur).toList();

    var totalInv = 0, totalPay = 0, totalDue = 0;
    var due = 0, settled = 0, credit = 0;
    for (final s in list) {
      totalInv += s.totalInvoices;
      totalPay += s.totalPayments;
      switch (s.status) {
        case AccountStatus.due:
          due++;
          totalDue += s.balance;
          break;
        case AccountStatus.settled:
          settled++;
          break;
        case AccountStatus.credit:
          credit++;
          break;
      }
    }
    final attention = applySupplierView(list, filter: SupplierFilter.due, sort: SupplierSort.highestDue).take(5).toList();
    final maxBal = attention.isEmpty ? 1 : attention.first.balance;
    final top = attention.take(3).toList();
    final topSum = top.fold<int>(0, (a, s) => a + s.balance);
    final pct = totalDue == 0 ? 0 : (topSum * 100 / totalDue).round();

    final greeting = greetingForNow() + (app.userName.isEmpty ? '' : '، ${app.userName}');

    if (data.all.isEmpty) {
      return Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('$greeting 👋', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          ),
        ),
        Expanded(
          child: EmptyState(
            icon: Icons.storefront_rounded,
            title: 'لم تضف أي مورد بعد',
            message: 'ابدأ بإضافة أول مورد لمتابعة حساباته.',
            actionLabel: 'إضافة مورد',
            onAction: () => openNewSupplier(context),
          ),
        ),
      ]);
    }

    Widget stat(IconData icon, String label, String value, Color c) => RamiCard(
          padding: const EdgeInsets.all(14),
          radius: 18,
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: alpha(c, 0.14), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: c, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(color: pal.muted, fontSize: 12)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5)),
                ),
              ]),
            ),
          ]),
        );

    Widget action(IconData icon, String label, VoidCallback onTap, Color c) => Expanded(
          child: RamiCard(
            onTap: onTap,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            radius: 18,
            child: Column(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: alpha(c, 0.14), shape: BoxShape.circle),
                child: Icon(icon, color: c),
              ),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$greeting 👋', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(app.businessName.isEmpty ? 'ملخص الموردين' : 'ملخص الموردين · ${app.businessName}',
                style: TextStyle(color: pal.muted, fontSize: 14)),
          ]),
        ),
        if (currencies.length > 1) ...[
          CurrencyChips(currencies: currencies, selected: cur, onChanged: app.setActiveCurrency),
          const SizedBox(height: 12),
        ],
        // بطاقة إجمالي المستحقات
        RamiCard(
          border: false,
          radius: 28,
          padding: const EdgeInsets.all(22),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [kOrangeLight, kOrange, kOrangeDeep],
          ),
          child: SizedBox(
            width: double.infinity,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                const Text('إجمالي المستحقات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ]),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: AnimatedMoney(
                  minor: totalDue,
                  currency: cur,
                  style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 4),
              const Text('إجمالي المبالغ المستحقة لجميع الموردين', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: const Color(0x2EFFFFFF), borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  Expanded(
                    child: Text('${list.length} مورد', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                  Container(width: 1, height: 18, color: Colors.white38),
                  Expanded(
                    child: Text('$due لديهم مستحقات',
                        textAlign: TextAlign.end, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          action(Icons.person_add_alt_1_rounded, 'مورد جديد', () => openNewSupplier(context), kBlue),
          const SizedBox(width: 8),
          action(Icons.receipt_long_rounded, 'فاتورة شراء', () => openNewInvoice(context), kOrange),
          const SizedBox(width: 8),
          action(Icons.payments_rounded, 'دفعة', () => openNewPayment(context), kGreen),
          const SizedBox(width: 8),
          action(Icons.description_rounded, 'كشف حساب', () => openStatementPicker(context), const Color(0xFF8E5CF5)),
        ]),
        if (attention.isNotEmpty) ...[
          const SectionTitle('يحتاج انتباهك'),
          if (due >= 2)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: pal.softOrange,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: alpha(kOrange, 0.35)),
              ),
              child: Row(children: [
                const Icon(Icons.notifications_active_rounded, color: kOrange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'لديك ${top.length} موردين بإجمالي مستحقات ${Money.withCurrency(topSum, cur)} ($pct% من الإجمالي)',
                    style: const TextStyle(fontWeight: FontWeight.w700, height: 1.45),
                  ),
                ),
              ]),
            ),
          RamiCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(children: [
              for (var i = 0; i < attention.length; i++) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SupplierDetailScreen(supplierId: attention[i].id)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Column(children: [
                      Row(children: [
                        Expanded(
                          child: Text(attention[i].supplier.name,
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                        ),
                        Text(Money.withCurrency(attention[i].balance, cur),
                            style: const TextStyle(fontWeight: FontWeight.w900, color: kOrange)),
                      ]),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: attention[i].balance / maxBal),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => LinearProgressIndicator(
                            value: v.clamp(0.0, 1.0),
                            minHeight: 7,
                            backgroundColor: pal.field,
                            valueColor: const AlwaysStoppedAnimation(kOrange),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                if (i < attention.length - 1) const Divider(),
              ],
            ]),
          ),
        ],
        const SectionTitle('الإحصائيات'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.05,
          children: [
            stat(Icons.groups_rounded, 'عدد الموردين', '${list.length}', kBlue),
            stat(Icons.receipt_long_rounded, 'إجمالي الفواتير', Money.withCurrency(totalInv, cur), kOrange),
            stat(Icons.payments_rounded, 'إجمالي الدفعات', Money.withCurrency(totalPay, cur), kGreen),
            stat(Icons.pending_actions_rounded, 'الموردون المستحقون', '$due', kOrange),
            stat(Icons.check_circle_rounded, 'الموردون المسددون', '$settled', kGreen),
            stat(Icons.savings_rounded, 'رصيد لصالحنا', '$credit', kBlue),
          ],
        ),
        if (data.recent.isNotEmpty) ...[
          const SectionTitle('آخر الحركات'),
          for (final e in data.recent) EntryTile(entry: e, showSupplier: true),
        ],
      ],
    );
  }
}
