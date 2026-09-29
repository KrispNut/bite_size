import 'package:flutter/material.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';

/// The little grab handle at the top of every bottom sheet.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      // A solid ink bar, not a soft rounded lozenge.
      child: Container(
        width: 44,
        height: 5,
        margin: const EdgeInsets.only(bottom: AppSpace.lg),
        color: AppColors.ink,
      ),
    );
  }
}
