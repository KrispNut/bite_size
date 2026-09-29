import 'package:flutter/material.dart';
import '/core/theme/activity_packs.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';

/// The currency marker that sits inside every money field, so it lines up
/// identically whether you're logging a shared cost or settling the bill.
///
/// It reads the symbol from the pack rather than hardcoding one, because a
/// group settling up in dirhams shouldn't be typing into a box labelled `Rs`.
class CurrencyPrefix extends StatelessWidget {
  const CurrencyPrefix({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpace.sm, right: 6),
      child: Text(
        PackService.currency.symbol,
        style: getBoldStyle(fontSize: 13, color: AppColors.textTertiary),
      ),
    );
  }
}
