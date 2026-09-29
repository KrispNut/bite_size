import 'package:flutter/material.dart';

import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';

/// Shared app bar. Flat, always — separation from the content comes from the
/// 2px ink rule underneath rather than an elevation shadow.
///
/// The gradient / elevation / animated-flexible-space knobs this used to take
/// have gone: there is no surface in the app that wants any of them.
AppBar reusableAppBar({
  required String title,
  Widget? titleWidget,
  String? subtitle,
  Widget? leadingIcon,
  List<Widget>? trailingIcon,
  Color? backgroundColor,
  bool showDivider = true,
}) {
  return AppBar(
    backgroundColor: backgroundColor ?? AppColors.bgColor,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    systemOverlayStyle: AppColors.systemOverlayStyle,
    elevation: 0,
    centerTitle: false,
    titleSpacing: 4,
    toolbarHeight: subtitle == null ? 60 : 68,
    iconTheme: IconThemeData(color: AppColors.textColor, size: 24),
    title:
        titleWidget ??
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: getExtraBoldStyle(
                color: AppColors.textColor,
                fontSize: 22,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle.toUpperCase(), style: AppText.monoLabel),
            ],
          ],
        ),
    leading: leadingIcon,
    actions: [
      ...?trailingIcon,
      const SizedBox(width: AppSpace.xs),
    ],
    // The bar is the top edge of the page's first container, so it closes
    // with the same 2px ink rule everything else is drawn with.
    bottom: showDivider
        ? PreferredSize(
            preferredSize: Size.fromHeight(AppDecor.strokeWidth),
            child: Container(
              height: AppDecor.strokeWidth,
              color: AppColors.ink,
            ),
          )
        : null,
  );
}
