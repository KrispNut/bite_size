import 'package:flutter/material.dart';
import '/core/theme/activity_packs.dart';
import 'package:provider/provider.dart';
import '/core/alerts/toast.dart';
import '/core/services/sound_service.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/counter_row.dart';
import '/core/widgets/custom_button.dart';
import '/core/widgets/custom_textfield.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import '/core/widgets/sheet_handle.dart';
import '/features/dashboard/dashboard_viewmodel.dart';
import '/generated/assets.dart';

/// Join or edit today's roster. Three questions, in the order people answer
/// them: are you bringing something, what is it, how many units do you need.
///
/// It used to open with a deep-teal title card, a negatively phrased switch
/// ("I didn't bring anything"), and two stepper tiles side by side, one of
/// which asked how many people the dish covers. That number is gone: nobody
/// counted portions honestly, so it only ever produced false alarms. What's
/// left is a plain heading, a two-way choice, one field and one stepper.
class AddEntrySheet extends StatefulWidget {
  const AddEntrySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      barrierColor: AppColors.scrim,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.sheet,
        side: BorderSide(color: AppColors.ink, width: AppDecor.strokeWidth),
      ),
      builder: (_) => const AddEntrySheet(),
    );
  }

  @override
  State<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<AddEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dishCtrl;

  int _units = 0;
  bool _eatingOnly = false;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<DashboardViewModel>();
    final existing = viewModel.myEntry;

    _dishCtrl = TextEditingController(
      text: existing?.contribution == 'Nothing'
          ? ''
          : existing?.contribution ?? '',
    );
    _units = existing?.unitsTaken ?? 0;
    _eatingOnly = existing != null && existing.covers == 0;
  }

  @override
  void dispose() {
    _dishCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final viewModel = context.read<DashboardViewModel>();
    debugPrint(
      '🖱️ [ON_TAP] Submit entry form button clicked | Name: "${viewModel.myEntry?.userName ?? viewModel.currentUserName}", Dish: "${_dishCtrl.text.trim()}", eatingOnly: $_eatingOnly',
    );
    if (!_formKey.currentState!.validate()) {
      debugPrint('⚠️ [FORM VALIDATION] Form validation failed');
      return;
    }

    Navigator.of(context).pop();
    await ShowToastDialog.whileLoading(
      'Saving entry...',
      () => viewModel.submitEntry(
        userName: viewModel.myEntry?.userName ?? viewModel.currentUserName,
        contribution: _eatingOnly ? 'Nothing' : _dishCtrl.text.trim(),
        // The portions column now only carries one bit: 0 is "brought
        // nothing", anything else is "brought something". The roster tile
        // and the AI check both read it that way; nobody asks for the number.
        covers: _eatingOnly ? 0 : 1,
        unitsTaken: _units,
      ),
      success: 'You\'re on today\'s roster! 🍛',
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = PackService.labels;
    final modules = PackService.modules;
    final isEditing = context.read<DashboardViewModel>().myEntry != null;

    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpace.lg,
            right: AppSpace.lg,
            top: AppSpace.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpace.xl,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SheetHandle(),
                  Text(
                    isEditing
                        ? 'Edit your entry'
                        : "Join today's ${labels.sessionNoun}",
                    style: AppText.h2,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    modules.units
                        ? 'What you ${labels.contributionVerb}, and how many '
                              '${labels.unitPlural} you need.'
                        : 'What you ${labels.contributionVerb}.',
                    style: AppText.bodySm,
                  ),
                  const SizedBox(height: AppSpace.md),

                  Row(
                    children: [
                      Expanded(
                        child: _Choice(
                          label: 'Bringing a ${labels.contribution}',
                          svgAsset: Assets.svg.salan.path,
                          selected: !_eatingOnly,
                          onTap: () => setState(() => _eatingOnly = false),
                        ),
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Expanded(
                        child: _Choice(
                          label: labels.attendingOnly,
                          icon: Icons.restaurant_rounded,
                          selected: _eatingOnly,
                          onTap: () => setState(() => _eatingOnly = true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),

                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.topCenter,
                    child: _eatingOnly
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(bottom: AppSpace.sm),
                            child: CustomTextField(
                              context: context,
                              controller: _dishCtrl,
                              enabled: true,
                              label: 'What did you ${labels.contributionVerb}?',
                              hintText: 'Your ${labels.contribution}',
                              type: TextInputType.text,
                              textInputAction: TextInputAction.done,
                              validatorFn: (v) =>
                                  (v == null || v.trim().isEmpty)
                                  ? 'Name the ${labels.contribution}, or pick '
                                        '${labels.attendingOnly.toLowerCase()}'
                                  : null,
                            ),
                          ),
                  ),

                  if (modules.units)
                    CounterRow(
                      label: '${labels.unitPluralTitle} you need',
                      value: _units,
                      max: 15,
                      icon: Icons.local_fire_department_rounded,
                      accent: AppColors.accentWarm,
                      onChanged: (v) => setState(() => _units = v),
                    ),

                  const SizedBox(height: AppSpace.lg),
                  CustomButton(
                    onPress: _submit,
                    text: isEditing ? 'Update entry' : 'Count me in',
                    btnColor: AppColors.primaryDeep,
                    textColor: AppColors.textOnBrand,
                    isIcon: true,
                    iconData: Icons.check_rounded,
                    iconColor: AppColors.textOnBrand,
                    height: 56,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One half of the bringing / eating-only choice. Selected reads as the
/// pressed-in option: brand tint, ink stroke, bold; the other sits as a
/// recessed well. Stating both options beats a switch whose off state has
/// to be read as a double negative.
class _Choice extends StatelessWidget {
  final String label;
  final String? svgAsset;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _Choice({
    required this.label,
    this.svgAsset,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (selected) return;
        SoundService.instance.playTapSound();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppSpace.sm,
        ),
        decoration: selected
            ? AppDecor.card(
                color: AppColors.primarySoft,
                radius: AppRadius.sm,
                borderColor: AppColors.ink,
                shadow: false,
              )
            : AppDecor.well(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (svgAsset != null)
              AppIcon(svgAsset!, size: 20)
            else
              Icon(
                icon,
                size: 19,
                color: selected ? AppColors.primary : AppColors.textTertiary,
              ),
            const SizedBox(width: AppSpace.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: selected
                    ? getBoldStyle(fontSize: 13.5, color: AppColors.textColor)
                    : getMediumStyle(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
