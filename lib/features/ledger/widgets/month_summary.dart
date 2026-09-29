import 'package:flutter/material.dart';
import '/core/theme/activity_packs.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/features/ledger/ledger_viewmodel.dart';
import '/core/widgets/bento_tile.dart';
import '/generated/assets.dart';

/// Headline numbers side-by-side in a Row with 20px horizontal padding.
class MonthSummary extends StatelessWidget {
  final LedgerViewModel vm;

  const MonthSummary({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final me = vm.currentUid;
    final myCost = vm.userTotalCost(me);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: BentoTile(
            label: 'Your ${PackService.labels.unitPlural}',
            value: '${vm.userTotalUnits(me)}',
            caption: myCost > 0
                ? PackService.currency.formatMajor(myCost, decimals: false)
                : 'not billed yet',
            svgAsset: Assets.svg.roti.path,
            fill: AppColors.primaryDeep,
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: BentoTile(
            label: 'Total ${PackService.labels.unitPlural}',
            value: '${vm.grandTotalUnits}',
            caption: vm.grandTotalCost > 0
                ? PackService.currency.formatMajor(
                    vm.grandTotalCost,
                    decimals: false,
                  )
                : 'not billed yet',
            svgAsset: Assets.svg.team.path,
            fill: AppColors.accentFill,
            darkText: true,
          ),
        ),
      ],
    );
  }
}
