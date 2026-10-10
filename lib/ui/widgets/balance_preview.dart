import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../models/supplier.dart';
import 'common.dart';

/// معاينة الرصيد بعد حفظ الحركة (تساعد المستخدم قبل التأكيد).
class BalancePreview extends StatelessWidget {
  const BalancePreview({super.key, required this.newBalance, required this.currency});
  final int newBalance;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final status = newBalance > 0
        ? AccountStatus.due
        : newBalance == 0
            ? AccountStatus.settled
            : AccountStatus.credit;
    final c = statusColor(status);
    return RamiCard(
      color: alpha(c, 0.08),
      border: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_rounded, color: c),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الرصيد بعد الحفظ', style: TextStyle(fontSize: 12.5)),
                const SizedBox(height: 2),
                Text(Money.withCurrency(newBalance.abs(), currency),
                    style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 18)),
              ],
            ),
          ),
          Text(balanceCaption(status), style: TextStyle(color: c, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
