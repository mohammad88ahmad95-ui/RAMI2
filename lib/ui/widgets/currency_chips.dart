import 'package:flutter/material.dart';

import '../../core/constants.dart';
import 'common.dart';

/// اختيار العملة عند وجود أكثر من عملة (لا يوجد تحويل بين العملات).
class CurrencyChips extends StatelessWidget {
  const CurrencyChips({super.key, required this.currencies, required this.selected, required this.onChanged});
  final List<String> currencies;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (currencies.length < 2) return const SizedBox.shrink();
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: currencies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = currencies[i];
          return RamiChip(
            label: '${currencyOf(c).name} (${currencyOf(c).symbol})',
            selected: c == selected,
            icon: Icons.payments_rounded,
            onTap: () => onChanged(c),
          );
        },
      ),
    );
  }
}
