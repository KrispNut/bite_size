import 'package:flutter/material.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_paddings.dart';
import '/core/theme/textfont_styles.dart';

class CustomDropdownField extends StatefulWidget {
  final String? value;
  final List<String> items;
  final String hintText;
  final void Function(String?)? onChanged;
  final bool enabled;
  final bool title;
  final Widget? prefix;
  final Widget? suffix;
  final double borderRadius;

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
    this.borderRadius = 10.0,
  });

  @override
  State<CustomDropdownField> createState() => _CustomDropdownFieldState();
}

class _CustomDropdownFieldState extends State<CustomDropdownField>
    with SingleTickerProviderStateMixin {
  final GlobalKey _buttonKey = GlobalKey();
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

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

    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _animationController.forward();
    final RenderBox renderBox =
        _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => _DropdownOverlay(
        items: widget.items,
        selectedValue: widget.value,
        offset: offset,
        size: size,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title)
          Text(
            widget.hintText,
            style: getSemiBoldStyle(color: AppColors.textColor, fontSize: 12),
          ),
        if (widget.title) padding8,
        GestureDetector(
          key: _buttonKey,
          onTap: _toggleDropdown,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.textFieldFillColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(color: AppColors.textFieldBorderColor),
            ),
            child: Row(
              children: [
                if (widget.prefix != null) ...[
                  widget.prefix!,
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    widget.value ?? widget.hintText,
                    style: widget.value != null
                        ? getRegularStyle(
                            fontSize: 14, color: AppColors.textColor)
                        : getRegularStyle(
                            fontSize: 14,
                            color: AppColors.textFieldPlaceholderColor),
                  ),
                ),
                if (widget.suffix != null)
                  widget.suffix!
                else
                  RotationTransition(
                    turns: _rotationAnimation,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.iconColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownOverlay extends StatefulWidget {
  final List<String> items;
  final String? selectedValue;
  final Offset offset;
  final Size size;
  final void Function(String) onItemSelected;
  final VoidCallback onDismiss;

  const _DropdownOverlay({
    required this.items,
    required this.selectedValue,
    required this.offset,
    required this.size,
    required this.onItemSelected,
    required this.onDismiss,
  });

  @override
  State<_DropdownOverlay> createState() => _DropdownOverlayState();
}

class _DropdownOverlayState extends State<_DropdownOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dismiss area
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Dropdown menu
        Positioned(
          left: widget.offset.dx,
          top: widget.offset.dy + widget.size.height + 4,
          width: widget.size.width,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: Alignment.topCenter,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                color: AppColors.textFieldFillColor,
                shadowColor: Colors.black26,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: widget.items.length,
                      itemBuilder: (context, index) {
                        final item = widget.items[index];
                        final isSelected = item == widget.selectedValue;
                        return InkWell(
                          onTap: () => widget.onItemSelected(item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item,
                                    style: getRegularStyle(
                                      fontSize: 14,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textColor,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    size: 18,
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
          ),
        ),
      ],
    );
  }
}
