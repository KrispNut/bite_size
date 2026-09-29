import 'package:flutter/material.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/text_styles.dart';
import 'dropdown_overlay.dart';

class CustomDropdownField extends StatefulWidget {
  final String? value;
  final List<String> items;
  final String hintText;
  final void Function(String?)? onChanged;
  final bool enabled;

  final bool title;
  final Widget? prefix;
  final Widget? suffix;

  const CustomDropdownField({
    super.key,
    required this.items,
    this.value,
    required this.hintText,
    this.onChanged,
    this.enabled = true,
    this.title = true,
    this.prefix,
    this.suffix,
  });

  @override
  State<CustomDropdownField> createState() => _CustomDropdownFieldState();
}

class _CustomDropdownFieldState extends State<CustomDropdownField>
    with SingleTickerProviderStateMixin {
  final GlobalKey _buttonKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  late final AnimationController _animationController = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  );

  late final Animation<double> _rotation = Tween<double>(begin: 0, end: 0.5)
      .animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
      );

  @override
  void dispose() {
    _animationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleDropdown() {
    if (!widget.enabled) return;
    _isOpen ? _closeDropdown() : _openDropdown();
  }

  void _openDropdown() {
    _animationController.forward();

    final renderBox =
        _buttonKey.currentContext!.findRenderObject() as RenderBox;

    _overlayEntry = OverlayEntry(
      builder: (context) => DropdownOverlay(
        items: widget.items,
        selectedValue: widget.value,
        offset: renderBox.localToGlobal(Offset.zero),
        size: renderBox.size,
        onItemSelected: (value) {
          widget.onChanged?.call(value);
          _closeDropdown();
        },
        onDismiss: _closeDropdown,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _animationController.reverse();
    _removeOverlay();
    setState(() => _isOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value != null;

    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title) ...[
            Text(widget.hintText.toUpperCase(), style: AppText.monoLabel),
            const SizedBox(height: AppSpace.xs),
          ],
          GestureDetector(
            key: _buttonKey,
            onTap: _toggleDropdown,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.sm,
                vertical: AppSpace.sm + 2,
              ),
              decoration: AppDecor.well(),
              child: Row(
                children: [
                  if (widget.prefix != null) ...[
                    widget.prefix!,
                    const SizedBox(width: AppSpace.xs),
                  ],
                  Expanded(
                    child: Text(
                      hasValue ? widget.value! : widget.hintText,
                      style: getMonoStyle(
                        fontSize: 13,
                        color: hasValue
                            ? AppColors.textColor
                            : AppColors.textFieldPlaceholderColor,
                      ),
                    ),
                  ),
                  widget.suffix ??
                      RotationTransition(
                        turns: _rotation,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.iconColor,
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
