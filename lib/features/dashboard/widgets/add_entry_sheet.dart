import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/core/alerts/app_alerts.dart';
import '/core/shared/custom_button.dart';
import '/core/shared/custom_textfield.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_dimens.dart';
import '/core/theme/textfont_styles.dart';
import '/core/theme/theme_service.dart';
import '/features/dashboard/dashboard_viewmodel.dart';

class AddEntrySheet extends StatefulWidget {
  const AddEntrySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      barrierColor: AppColors.scrim,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (_) => const AddEntrySheet(),
    );
  }

  @override
  State<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<AddEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dishCtrl;

  int _portions = 0;
  int _rotis = 0;
  bool _eatingOnly = false;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<DashboardViewModel>();
    final existing = viewModel.myEntry;

    _dishCtrl = TextEditingController(text: existing?.dishName == 'Nothing' ? '' : existing?.dishName ?? '');
    _portions = existing?.portions ?? 0;
    _rotis = existing?.rotisNeeded ?? 0;
    // An existing entry with no portions means they signed up to eat only.
    _eatingOnly = existing != null && existing.portions == 0;
  }

  @override
  void dispose() {
    _dishCtrl.dispose();
    super.dispose();
  }

  void _toggleEatingOnly(bool value) {
    setState(() {
      _eatingOnly = value;
    });
  }

  Future<void> _submit() async {
    final viewModel = context.read<DashboardViewModel>();
    debugPrint(
      '🖱️ [ON_TAP] Submit entry form button clicked | Name: "${viewModel.myEntry?.userName ?? viewModel.currentUserName}", Dish: "${_dishCtrl.text.trim()}"',
    );
    if (!_formKey.currentState!.validate()) {
      debugPrint('⚠️ [FORM VALIDATION] Form validation failed');
      return;
    }

    Navigator.of(context).pop();
    ShowToastDialog.showLoader('Saving entry...');

    final error = await viewModel.submitEntry(
      userName: viewModel.myEntry?.userName ?? viewModel.currentUserName,
      dishName: _eatingOnly ? 'Nothing' : _dishCtrl.text.trim(),
      portions: _eatingOnly ? 0 : _portions,
      rotisNeeded: _rotis,
    );

    ShowToastDialog.closeLoader();
    ShowToastDialog.showToast(error ?? 'You\'re on today\'s roster! 🍛');
  }

  @override
  Widget build(BuildContext context) {
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
                    isEditing ? 'Edit your entry' : 'Join today\'s lunch',
                    style: AppText.h2,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tell the runner what you brought and how many rotis you need.',
                    style: AppText.bodySm,
                  ),
                  const SizedBox(height: AppSpace.xl),

                  _EatingOnlyToggle(
                    value: _eatingOnly,
                    onChanged: _toggleEatingOnly,
                  ),
                  const SizedBox(height: AppSpace.md),

                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.topCenter,
                    child: _eatingOnly
                        ? const SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextField(
                                context: context,
                                controller: _dishCtrl,
                                enabled: true,
                                label: 'What did you bring?',
                                hintText: 'e.g. Aloo Gosht',
                                type: TextInputType.text,
                                textInputAction: TextInputAction.done,
                                validatorFn: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Enter a dish, or switch off "eating only"'
                                        : null,
                              ),
                              const SizedBox(height: AppSpace.lg),
                              _CounterRow(
                                label: 'How many people does it feed?',
                                value: _portions,
                                max: 20,
                                icon: Icons.restaurant_rounded,
                                accent: AppColors.success,
                                onChanged: (v) => setState(() => _portions = v),
                              ),
                            ],
                          ),
                  ),

                  _CounterRow(
                    label: 'Rotis you need',
                    value: _rotis,
                    max: 15,
                    icon: Icons.local_fire_department_rounded,
                    accent: AppColors.accentWarm,
                    onChanged: (v) => setState(() => _rotis = v),
                  ),

                  const SizedBox(height: AppSpace.xl),
                  CustomButton(
                    onPress: _submit,
                    text: isEditing ? 'Update entry' : 'Count me in',
                    btnColor: AppColors.primary,
                    textColor: AppColors.onPrimary,
                    isIcon: true,
                    iconData: Icons.check_rounded,
                    iconColor: AppColors.onPrimary,
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

class _EatingOnlyToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _EatingOnlyToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: value ? AppColors.primarySoft : AppColors.surfaceAlt,
      borderRadius: AppRadius.rSm,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.xs,
          ),
          child: Row(
            children: [
              Icon(
                value
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 19,
                color: value ? AppColors.primary : AppColors.textTertiary,
              ),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Text(
                  'I didn\'t bring anything — just eating',
                  style: getMediumStyle(
                    fontSize: 13,
                    color: value ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tap-to-step counter. Faster than a keyboard for the 0–15 range these
/// fields actually live in, and it can't produce invalid input.
class _CounterRow extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final IconData icon;
  final Color accent;
  final ValueChanged<int> onChanged;

  const _CounterRow({
    required this.label,
    required this.value,
    required this.max,
    required this.icon,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xs + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.rSm,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: AppSpace.xs),
          Expanded(
            child: Text(
              label,
              style: getSemiBoldStyle(fontSize: 13, color: AppColors.textColor),
            ),
          ),
          _StepButton(
            icon: Icons.remove_rounded,
            enabled: value > 0,
            onTap: () => onChanged(value - 1),
          ),
          SizedBox(
            width: 38,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: getExtraBoldStyle(
                fontSize: 18,
                color: value == 0
                    ? AppColors.textTertiary
                    : AppColors.textColor,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            enabled: value < max,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.surface : Colors.transparent,
      shape: CircleBorder(
        side: BorderSide(
          color: enabled ? AppColors.borderStrong : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.textColor : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
