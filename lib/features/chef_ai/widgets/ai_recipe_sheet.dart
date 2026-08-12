import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '/core/theme/app_colors.dart';
import '/core/constants/app_constants.dart';
import '/core/theme/app_dimens.dart';
import '/core/theme/textfont_styles.dart';
import '/features/dashboard/dashboard_viewmodel.dart';

/// Streams a Gemini assessment of whether today's food actually covers the room.
class AiRecipeSheet extends StatefulWidget {
  const AiRecipeSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      barrierColor: AppColors.scrim,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (_) => const AiRecipeSheet(),
    );
  }

  @override
  State<AiRecipeSheet> createState() => _AiRecipeSheetState();
}

class _AiRecipeSheetState extends State<AiRecipeSheet> {
  String _recipeText = '';
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateAiRecipe();
    });
  }

  String _buildChefPrompt(DashboardViewModel vm) {
    final headcount = vm.session?.headcount ?? vm.entries.length;
    final totalRotis = vm.session?.totalRotis ?? 0;
    final portions = vm.session?.totalPortions ?? 0;
    final dishes = vm.entries
        .where((e) => e.portions > 0)
        .map((e) => '${e.dishName} (by ${e.userName}, feeds ${e.portions})')
        .join(', ');

    return '''
Act as an expert office lunch coordinator for $headcount team members.

Today's Office Lunch Stats:
- Team Members Eating: $headcount people
- Total Rotis Ordered: $totalRotis fresh tandoor rotis
- Salan Portions Brought: $portions portions
- Dishes Brought: ${dishes.isEmpty ? 'No home dishes brought yet' : dishes}.

Task:
Analyze if the total portions and rotis are enough to comfortably feed the $headcount team members.
If it is enough, assure the team that the food is sufficient.
If there is a deficit, specifically suggest what else we need to order from outside (e.g., more rotis, or an extra dish like Karahi or Daal) to make sure nobody goes hungry. Keep it concise, helpful, and friendly!
''';
  }

  Future<void> _generateAiRecipe() async {
    setState(() {
      _isGenerating = true;
      _recipeText = '';
    });

    final vm = context.read<DashboardViewModel>();
    final promptText = _buildChefPrompt(vm);

    try {
      // 🔑 Get API Key from AppConstants
      final apiKey = AppConstants.geminiApiKey;

      if (apiKey == 'YOUR_API_KEY_HERE' || apiKey.isEmpty) {
        setState(() {
          _recipeText =
              "⚠️ API Key Missing!\n\nPlease paste your Gemini API key in lib/core/constants/app_constants.dart to generate recipes.";
        });
        return;
      }

      // The 1.5 family was retired from the v1beta endpoint — it 404s.
      // `gemini-flash-latest` is the moving alias if you'd rather not pin.
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

      final content = [Content.text(promptText)];
      final responseStream = model.generateContentStream(content);

      await for (final chunk in responseStream) {
        if (!mounted) break;
        if (chunk.text != null && chunk.text!.isNotEmpty) {
          setState(() {
            _recipeText += chunk.text!;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recipeText =
              "❌ Error connecting to Gemini API:\n\n$e\n\nFallback simulated recipe below:\n\n";
        });
        await _generateFallbackStream(vm);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _generateFallbackStream(DashboardViewModel vm) async {
    final headcount = vm.session?.headcount ?? vm.entries.length;
    final rotis = vm.session?.totalRotis ?? 0;
    final portions = vm.session?.totalPortions ?? 0;
    final dishes = vm.entries
        .where((e) => e.portions > 0)
        .map((e) => e.dishName)
        .join(' & ');

    final mockResponse =
        '''
🤖 **AI Lunch Coordinator Assessment**

For today's team of **$headcount members**, we have:
• **$rotis rotis**
• **$portions portions** of ${dishes.isEmpty ? 'food' : dishes}

**Assessment:**
${rotis < headcount * 2 ? 'We might be slightly short on rotis (usually 2 per person is safe). Consider ordering ${headcount * 2 - rotis} more rotis.' : 'Rotis look sufficient!'}
${portions < headcount ? 'We are short on Salan! With $headcount people, $portions portions won\'t be enough. Consider ordering a quick Karahi or Daal from outside.' : 'Salan portions look good to feed everyone!'}

💡 **Tip:** Better to have a little extra than to let someone go hungry!
''';

    final words = mockResponse.split(' ');
    for (final word in words) {
      if (!mounted) break;
      await Future.delayed(const Duration(milliseconds: 30));
      setState(() {
        _recipeText += '$word ';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final headcount = vm.session?.headcount ?? 0;
    final showPlaceholder = _isGenerating && _recipeText.isEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
        AppSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.heroGradient,
                  ),
                  borderRadius: AppRadius.rSm,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 21,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('AI lunch assessment', style: AppText.h3),
                    Text(
                      headcount == 0
                          ? 'Waiting on the roster'
                          : 'Checking food for $headcount ${headcount == 1 ? 'person' : 'people'}',
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: AppRadius.rPill,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),

          Expanded(
            child: showPlaceholder
                ? const _ThinkingState()
                : SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpace.md),
                      decoration: AppDecor.well(),
                      child: _RichAiText(
                        text: _recipeText,
                        showCaret: _isGenerating,
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: AppSpace.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateAiRecipe,
              icon: _isGenerating
                  ? SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.btnDisabledTextColor,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 19),
              label: Text(_isGenerating ? 'Analysing…' : 'Run again'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton-ish placeholder shown before the first token lands.
class _ThinkingState extends StatelessWidget {
  const _ThinkingState();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Skeletonizer(
        enabled: true,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: AppDecor.well(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reading today\'s roster...',
                style: getSemiBoldStyle(
                  fontSize: 16,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                'We have quite a few people today and we need to ensure everyone is well fed.',
                style: getRegularStyle(fontSize: 14, color: AppColors.textColor),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                'Looking at the portions, it seems like we might be a bit short on Salan. Considering ordering extra to be safe.',
                style: getRegularStyle(fontSize: 14, color: AppColors.textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimal markdown renderer for the subset the model actually emits:
/// `**bold**` spans, `•`/`-` bullets and blank-line paragraph breaks.
class _RichAiText extends StatelessWidget {
  final String text;
  final bool showCaret;

  const _RichAiText({required this.text, required this.showCaret});

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
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
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
      widgets.add(const _TypingCaret());
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

class _TypingCaret extends StatefulWidget {
  const _TypingCaret();

  @override
  State<_TypingCaret> createState() => _TypingCaretState();
}

class _TypingCaretState extends State<_TypingCaret>
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
