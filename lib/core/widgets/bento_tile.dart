import 'package:flutter/material.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/font_weights.dart';
import '/core/theme/text_styles.dart';
import 'app_icon.dart';
import 'tactile_container.dart';

class BentoTile extends StatefulWidget {
  final String label;
  final String value;
  final String? caption;
  final String? svgAsset;

  /// Anything animated or otherwise not an SVG — a Lottie — drawn in the
  /// bottom-right where [svgAsset] would go. Takes precedence over it.
  final Widget? art;

  /// Fired on tap regardless of [expandedContent]. Lets a tile drive its own
  /// [art] — the TEAM tile plays its person once per tap.
  final VoidCallback? onTap;
  final Widget? expandedContent;
  final Color fill;
  final bool darkText;
  final bool initiallyExpanded;

  const BentoTile({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.svgAsset,
    this.art,
    this.onTap,
    this.expandedContent,
    required this.fill,
    this.darkText = false,
    this.initiallyExpanded = false,
  });

  @override
  State<BentoTile> createState() => _BentoTileState();
}

class _BentoTileState extends State<BentoTile> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.darkText ? AppColors.textColor : AppColors.textOnBrand;

    return TactileContainer(
      onTap: (widget.expandedContent != null || widget.onTap != null)
          ? () {
              widget.onTap?.call();
              if (widget.expandedContent != null) _toggleExpand();
            }
          : null,
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.all(AppSpace.sm),
        decoration: AppDecor.filled(widget.fill, shadow: !pressed),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (widget.art != null)
              Positioned(
                right: -6,
                bottom: -8,
                child: SizedBox(width: 84, height: 84, child: widget.art),
              )
            else if (widget.svgAsset != null)
              Positioned(
                right: -22,
                bottom: -24,
                child: Opacity(
                  opacity: 0.55,
                  child: AppIcon(widget.svgAsset!, size: 92),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      fit: FlexFit.loose,
                      child: Text(
                        widget.label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: getMonoStyle(
                          fontSize: 11,
                          color: fg.withValues(alpha: 0.75),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    if (widget.expandedContent != null) ...[
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: fg.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.value,
                    style: getMonoStyle(
                      fontSize: 38,
                      weight: FontWeightManager.extraBold,
                      color: fg,
                      letterSpacing: -1.5,
                    ),
                  ),
                ),
                if (widget.caption != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: getMonoStyle(
                      fontSize: 10.5,
                      color: fg.withValues(alpha: 0.8),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
                if (widget.expandedContent != null)
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: AppSpace.sm),
                      child: widget.expandedContent!,
                    ),
                    crossFadeState: _isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 250),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
