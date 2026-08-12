import 'package:flutter/material.dart';
import '/core/theme/app_colors.dart';

class ReusableContainer extends StatelessWidget {
  const ReusableContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.containerColor5,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
