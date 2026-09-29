import 'package:flutter/material.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';

/// Indeterminate "still working" bar.
///
/// Material's circular and linear indicators both draw a soft, tapering stroke
/// that fights the flat ink language everywhere else, so this replaces them
/// app-wide: an ink-stroked track with a solid block shuttling across it.
/// Nothing here fades or blurs — the block has hard edges and full opacity.
class NeoProgressBar extends StatefulWidget {
  final double width;
  final double height;

  /// The travelling block. Defaults to the brand colour.
  final Color? color;

  /// The track behind it. Defaults to the recessed surface.
  final Color? trackColor;

  const NeoProgressBar({
    super.key,
    this.width = 90,
    this.height = 12,
    this.color,
    this.trackColor,
  });

  @override
  State<NeoProgressBar> createState() => _NeoProgressBarState();
}

class _NeoProgressBarState extends State<NeoProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.trackColor ?? AppColors.surfaceAlt,
        borderRadius: AppRadius.rXs,
        border: Border.all(color: AppColors.ink, width: AppDecor.strokeWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Align(
          // -1 → 1 puts the block flush against each end, so it reads as a
          // shuttle rather than something that slides off and disappears.
          alignment: Alignment(_controller.value * 2 - 1, 0),
          child: FractionallySizedBox(
            widthFactor: 0.42,
            heightFactor: 1,
            child: ColoredBox(color: widget.color ?? AppColors.primary),
          ),
        ),
      ),
    );
  }
}
