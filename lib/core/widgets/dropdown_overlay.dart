import 'package:flutter/material.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';

/// The menu [CustomDropdownField] raises into the overlay when it opens.
///
/// Deliberately not a `Material` with an elevation: it is a bento tile like
/// everything else, so it carries the ink stroke and the hard offset rather
/// than a soft drop shadow.
class DropdownOverlay extends StatefulWidget {
  final List<String> items;
  final String? selectedValue;
  final Offset offset;
  final Size size;
  final void Function(String) onItemSelected;
  final VoidCallback onDismiss;

  const DropdownOverlay({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.offset,
    required this.size,
    required this.onItemSelected,
    required this.onDismiss,
  });

  @override
  State<DropdownOverlay> createState() => _DropdownOverlayState();
}

class _DropdownOverlayState extends State<DropdownOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 160),
    vsync: this,
  )..forward();

  late final Animation<double> _scale = Tween<double>(
    begin: 0.96,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onDismiss,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: widget.offset.dx,
            // Clears the field's own 2px stroke plus its shadow.
            top: widget.offset.dy + widget.size.height + AppSpace.xxs,
            width: widget.size.width,
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                alignment: Alignment.topCenter,
                child: Container(
                  decoration: AppDecor.card(radius: AppRadius.sm),
                  clipBehavior: Clip.antiAlias,
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: widget.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      final isSelected = item == widget.selectedValue;

                      return GestureDetector(
                        onTap: () => widget.onItemSelected(item),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.sm,
                            vertical: AppSpace.sm,
                          ),
                          color: isSelected
                              ? AppColors.primarySoft
                              : AppColors.surface,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item,
                                  style: getMonoStyle(
                                    fontSize: 13,
                                    color: AppColors.textColor,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_rounded,
                                  size: 17,
                                  color: AppColors.primary,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
