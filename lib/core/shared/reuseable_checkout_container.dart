import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '/core/theme/app_colors.dart';

class ReusableCheckoutContainer extends StatelessWidget {
  final Widget child;
  final Color? color;

  const ReusableCheckoutContainer({super.key, required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor1),
        color: color ?? AppColors.containerColor1,
        boxShadow: const [
          BoxShadow(
            color: Color(0x179E9E9E),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 0),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 200),
      child: child,
    );
  }
}
