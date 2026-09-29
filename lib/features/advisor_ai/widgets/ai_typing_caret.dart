import 'package:flutter/material.dart';
import '/core/theme/app_colors.dart';

/// The blinking block that trails streaming AI output.
class AiTypingCaret extends StatefulWidget {
  const AiTypingCaret({super.key});

  @override
  State<AiTypingCaret> createState() => _AiTypingCaretState();
}

class _AiTypingCaretState extends State<AiTypingCaret>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 15,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
