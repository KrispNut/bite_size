import 'package:flutter/material.dart';
import '/core/theme/activity_packs.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import '/core/theme/app_colors.dart';
import '/core/constants/app_constants.dart';
import '/core/theme/app_theme.dart';
import '/core/widgets/icon_button.dart';
import '/core/widgets/custom_button.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/sheet_handle.dart';
import '/generated/assets.dart';
import 'ai_thinking_state.dart';
import 'rich_ai_text.dart';
import '/core/theme/text_styles.dart';
import '/features/dashboard/dashboard_viewmodel.dart';

/// Streams a Gemini assessment of whether what has been brought actually
/// covers the room. What "brought" and "covers" mean is the pack's business.
class AdvisorSheet extends StatefulWidget {
  const AdvisorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      barrierColor: AppColors.scrim,
      // The sheet is a bento tile too: the lip carries the same ink stroke
      // as everything it contains.
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.sheet,
        side: BorderSide(color: AppColors.ink, width: AppDecor.strokeWidth),
      ),
      builder: (_) => const AdvisorSheet(),
    );
  }

  @override
  State<AdvisorSheet> createState() => _AiRecipeSheetState();
}

class _AiRecipeSheetState extends State<AdvisorSheet> {
  String _adviceText = '';
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateAdvice();
    });
  }

  /// Builds the prompt from the pack's brief plus the session's own numbers.
  ///
  /// The framing — who the model is being asked to be — is the pack's
  /// [ActivityPack.advisorBrief]. Everything after it is generated from the
  /// labels and the roster, so a group that renames its units gets a prompt
  /// that talks about the right thing without anyone editing this file.
  String _buildAdvisorPrompt(DashboardViewModel vm) {
    final pack = PackService.instance.pack;
    final labels = pack.labels;
    final modules = pack.modules;

    final headcount = vm.session?.headcount ?? vm.entries.length;
    final totalUnits = vm.session?.totalUnits ?? 0;
    final covers = vm.session?.totalCovers ?? 0;
    // covers > 0 means "brought something"; the number itself is only a
    // fact worth telling the model when the pack actually counts coverage.
    final contributions = vm.entries
        .where((e) => e.covers > 0)
        .map(
          (e) => modules.coverage
              ? '${e.contribution} (by ${e.userName}, covers ${e.covers})'
              : '${e.contribution} (by ${e.userName})',
        )
        .join(', ');

    final brief = pack.advisorBrief.isNotEmpty
        ? pack.advisorBrief
        : 'Act as the coordinator for a group of $headcount people sharing '
              'costs. Judge whether what has been contributed is enough, and '
              'say what to do about it if it is not.';

    final facts = <String>[
      'People taking part: $headcount',
      if (modules.units)
        '${labels.unitPluralTitle} needed in total: $totalUnits',
      if (modules.coverage) '${labels.coverageCaps} covered: $covers',
      if (modules.roster)
        'What people ${labels.contributionVerb}: '
            '${contributions.isEmpty ? 'nothing yet' : contributions}',
    ].join('\n- ');

    return '''
$brief

Today's numbers:
- $facts

Task:
Say whether this is enough for $headcount people. If it is, say so plainly.
If it is short, say exactly what to get more of and roughly how much.
Keep it concise, helpful and friendly.
''';
  }

  Future<void> _generateAdvice() async {
    setState(() {
      _isGenerating = true;
      _adviceText = '';
    });

    final vm = context.read<DashboardViewModel>();
    final promptText = _buildAdvisorPrompt(vm);

    try {
      // 🔑 Get API Key from AppConstants
      final apiKey = AppConstants.geminiApiKey;

      if (apiKey == 'YOUR_API_KEY_HERE' || apiKey.isEmpty) {
        setState(() {
          _adviceText =
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
            _adviceText += chunk.text!;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _adviceText =
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

  /// What gets streamed when Gemini is unreachable. Deliberately arithmetic
  /// rather than clever — it is the same shortfall check the tiles do, written
  /// out in the pack's own words.
  Future<void> _generateFallbackStream(DashboardViewModel vm) async {
    final pack = PackService.instance.pack;
    final labels = pack.labels;
    final modules = pack.modules;

    final headcount = vm.session?.headcount ?? vm.entries.length;
    final units = vm.session?.totalUnits ?? 0;
    final covers = vm.session?.totalCovers ?? 0;
    final contributions = vm.entries
        .where((e) => e.covers > 0)
        .map((e) => e.contribution)
        .join(' & ');

    final unitLine = modules.units ? '\n• **${labels.unitCount(units)}**' : '';
    final coverLine = modules.coverage
        ? '\n• **${labels.coverCount(covers)}** of '
              '${contributions.isEmpty ? 'nothing yet' : contributions}'
        : '';

    final unitVerdict = modules.units
        ? (units < headcount * 2
              ? '\nThat looks short on ${labels.unitPlural} — two each is the '
                    'safe figure, so consider ${headcount * 2 - units} more.'
              : '\n${labels.unitPluralTitle} look sufficient.')
        : '';
    final coverVerdict = modules.coverage
        ? (covers < headcount
              ? '\nShort by ${labels.coverCount(headcount - covers)}. With '
                    '$headcount people that will not stretch — get more in.'
              : '\nEveryone is covered.')
        : '';

    final mockResponse =
        '''
🤖 **${labels.advisorName} assessment**

For today's $headcount ${headcount == 1 ? 'person' : 'people'}:$unitLine$coverLine

**Assessment:**$unitVerdict$coverVerdict

💡 **Tip:** better a little spare than somebody going without.
''';

    final words = mockResponse.split(' ');
    for (final word in words) {
      if (!mounted) break;
      await Future.delayed(const Duration(milliseconds: 30));
      setState(() {
        _adviceText += '$word ';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final headcount = vm.session?.headcount ?? 0;
    final showPlaceholder = _isGenerating && _adviceText.isEmpty;

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
                decoration: AppDecor.filled(
                  AppColors.primaryDeep,
                  radius: AppRadius.sm,
                ),
                alignment: Alignment.center,
                child: AppIcon(Assets.svg.sparkle.path, size: 22),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${PackService.labels.advisorName} assessment',
                      style: AppText.h3,
                    ),
                    Text(
                      headcount == 0
                          ? 'Waiting on the roster'
                          : 'Checking for $headcount ${headcount == 1 ? 'person' : 'people'}',
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              AppIconButton(
                icon: Icons.close_rounded,
                onTap: () => Navigator.of(context).pop(),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),

          Expanded(
            child: showPlaceholder
                ? const AiThinkingState()
                : SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpace.md),
                      decoration: AppDecor.well(),
                      child: RichAiText(
                        text: _adviceText,
                        showCaret: _isGenerating,
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: AppSpace.md),
          CustomButton(
            onPress: _isGenerating ? null : _generateAdvice,
            text: _isGenerating ? 'Analysing' : 'Run again',
            btnColor: AppColors.primaryDeep,
            textColor: AppColors.textOnBrand,
            isIcon: true,
            iconData: Icons.refresh_rounded,
            iconColor: AppColors.textOnBrand,
            isBusy: _isGenerating,
            height: 52,
          ),
        ],
      ),
    );
  }
}
