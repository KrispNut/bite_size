import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/core/theme/app_colors.dart';
import '/core/theme/app_dimens.dart';
import '/core/theme/textfont_styles.dart';

/// Shared app bar. Flat by default — separation from the content comes from a
/// hairline rule rather than a shadow, which keeps the scroll edge calm.
AppBar reusableAppBar({
  required String title,
  String? subtitle,
  bool centerTitle = false,
  double elevation = 0,
  Widget? leadingIcon,
  List<Widget>? trailingIcon,
  BorderRadiusGeometry? borderRadius,
  Duration animationDuration = const Duration(milliseconds: 400),
  Gradient? gradient,
  TextStyle? titleStyle,
  Color? backgroundColor,
  SystemUiOverlayStyle? systemOverlayStyle,
  bool showDivider = true,
}) {
  return AppBar(
    backgroundColor: backgroundColor ?? AppColors.bgColor,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    systemOverlayStyle: systemOverlayStyle ?? AppColors.systemOverlayStyle,
    elevation: elevation,
    centerTitle: centerTitle,
    titleSpacing: 4,
    toolbarHeight: subtitle == null ? 60 : 68,
    iconTheme: IconThemeData(color: AppColors.textColor, size: 24),
    flexibleSpace: gradient == null
        ? null
        : ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.zero,
            child: AnimatedContainer(
              duration: animationDuration,
              decoration: BoxDecoration(gradient: gradient),
            ),
          ),
    title: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centerTitle
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              titleStyle ??
              getExtraBoldStyle(color: AppColors.textColor, fontSize: 22),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle, style: AppText.caption),
        ],
      ],
    ),
    leading: leadingIcon,
    actions: [
      ...?trailingIcon,
      const SizedBox(width: AppSpace.xxs),
    ],
    bottom: showDivider
        ? PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.divider),
          )
        : null,
  );
}

/// Circular icon button sized for app bars and card headers.
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final Color? background;
  final double size;
  final String? tooltip;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.background,
    this.size = 20,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColors.textSecondary;
    final button = Material(
      color: background ?? AppColors.surfaceAlt,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: size, color: fg),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
