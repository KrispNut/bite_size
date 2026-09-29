import 'package:flutter/material.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import 'ai_typing_caret.dart';

/// Minimal markdown renderer for the subset the model actually emits:
/// `**bold**` spans, `•`/`-` bullets and blank-line paragraph breaks.
class RichAiText extends StatelessWidget {
  final String text;
  final bool showCaret;

  const RichAiText({super.key, required this.text, required this.showCaret});

  @override
  Widget build(BuildContext context) {
    final base = getRegularStyle(
      fontSize: 14,
      color: AppColors.textColor,
    ).copyWith(height: 1.65);
    final strong = getExtraBoldStyle(
      fontSize: 14,
      color: AppColors.textColor,
    ).copyWith(height: 1.65);

    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: AppSpace.xs));
        continue;
      }

      final isBullet =
          line.trimLeft().startsWith('•') ||
          line.trimLeft().startsWith('- ') ||
          line.trimLeft().startsWith('* ');
      final content = isBullet
          ? line.trimLeft().replaceFirst(RegExp(r'^[•\-\*]\s*'), '')
          : line;

      final span = TextSpan(
        style: base,
        children: _parseBold(content, base, strong),
      );

      widgets.add(
        Padding(
          padding: EdgeInsets.only(left: isBullet ? AppSpace.xs : 0, bottom: 2),
          child: isBullet
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 7,
                        right: AppSpace.xs,
                      ),
                      child: Container(
                        width: 6,
                        height: 6,
                        color: AppColors.primary,
                      ),
                    ),
                    Expanded(child: SelectableText.rich(span)),
                  ],
                )
              : SelectableText.rich(span),
        ),
      );
    }

    if (showCaret) {
      widgets.add(const AiTypingCaret());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  List<TextSpan> _parseBold(String input, TextStyle base, TextStyle strong) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    var index = 0;

    for (final match in pattern.allMatches(input)) {
      if (match.start > index) {
        spans.add(TextSpan(text: input.substring(index, match.start)));
      }
      spans.add(TextSpan(text: match.group(1), style: strong));
      index = match.end;
    }
    if (index < input.length) {
      spans.add(TextSpan(text: input.substring(index)));
    }
    return spans.isEmpty ? [TextSpan(text: input)] : spans;
  }
}
