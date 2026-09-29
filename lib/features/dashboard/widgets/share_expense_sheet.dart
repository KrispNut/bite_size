import 'package:flutter/material.dart';
import '/core/theme/activity_packs.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '/core/alerts/toast.dart';
import '/core/widgets/custom_button.dart';
import '/core/widgets/custom_textfield.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/widgets/pill_button.dart';
import '/core/widgets/currency_prefix.dart';
import '/core/widgets/sheet_handle.dart';
import '/core/widgets/sheet_header_card.dart';
import 'share_person_row.dart';
import '/core/theme/font_weights.dart';
import '/core/theme/text_styles.dart';
import '/features/dashboard/dashboard_viewmodel.dart';
import '/core/widgets/custom_dropdown_field.dart';
import '/features/auth/models/app_user.dart';

class ShareExpenseSheet extends StatefulWidget {
  const ShareExpenseSheet({super.key});

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
      builder: (_) => const ShareExpenseSheet(),
    );
  }

  @override
  State<ShareExpenseSheet> createState() => _ShareExpenseSheetState();
}

class _ShareExpenseSheetState extends State<ShareExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();

  late final Set<String> _selected;
  late final String _me;
  String? _paidById;

  @override
  void initState() {
    super.initState();
    _me = context.read<DashboardViewModel>().currentUid;
    _selected = {if (_me.isNotEmpty) _me};
    _paidById = _me.isNotEmpty ? _me : null;
    _costController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _costController.removeListener(_refresh);
    _descriptionController.dispose();
    _costController.dispose();
    super.dispose();
  }

  double get _cost => double.tryParse(_costController.text.trim()) ?? 0;

  static String _labelFor(AppUser user, String me) =>
      user.uid == me ? '${user.name} (you)' : user.name;

  /// Each selected person's share in minor units. The leftover paisa go to
  /// the first few people so the shares add back up to the cost exactly.
  Map<String, int> get _sharesByUser {
    final people = _selected.toList();
    if (people.isEmpty || _cost <= 0) return const {};
    final totalMinor = PackService.currency.toMinor(_cost);
    final base = totalMinor ~/ people.length;
    final leftover = totalMinor - base * people.length;
    return {
      for (var i = 0; i < people.length; i++)
        people[i]: base + (i < leftover ? 1 : 0),
    };
  }

  Future<void> _submit(DashboardViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selected.isEmpty) {
      ShowToastDialog.showToast('Pick at least one person sharing this.');
      return;
    }

    final invitees = _selected.where((id) => id != _paidById).length;

    Navigator.of(context).pop();
    await ShowToastDialog.whileLoading(
      'Sending the invites...',
      () => viewModel.addSharedExpense(
        description: _descriptionController.text.trim(),
        cost: _cost,
        participantIds: _selected.toList(),
        paidById: _paidById,
      ),
      success: invitees == 0
          ? 'Added to your tab 🥘'
          : 'Asked $invitees ${invitees == 1 ? 'person' : 'people'} '
                'to confirm 🥘',
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    final people = viewModel.allUsers;
    final sharesByUser = _sharesByUser;
    final perHead = sharesByUser.isEmpty ? 0 : sharesByUser.values.first;

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
                  SheetHeaderCard(
                    title: 'Share a ${PackService.labels.expense}',
                    subtitle:
                        'Everyone you pick gets asked to confirm — only the '
                        'ones who accept get charged.',
                  ),
                  const SizedBox(height: AppSpace.sm),

                  CustomTextField(
                    context: context,
                    controller: _descriptionController,
                    label: 'What are you splitting?',
                    hintText: 'What it was',
                    type: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    validatorFn: (v) => (v == null || v.trim().isEmpty)
                        ? 'Give it a name'
                        : null,
                  ),
                  const SizedBox(height: AppSpace.md),

                  CustomTextField(
                    context: context,
                    controller: _costController,
                    label: 'What did it cost?',
                    hintText: 'e.g. 450',
                    type: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    prefix: const CurrencyPrefix(),
                    validatorFn: (v) {
                      final parsed = double.tryParse((v ?? '').trim()) ?? 0;
                      return parsed <= 0 ? 'Enter a cost above zero' : null;
                    },
                  ),
                  const SizedBox(height: AppSpace.lg),

                  Text('Who paid for it?', style: AppText.label),
                  const SizedBox(height: AppSpace.xs),
                  CustomDropdownField(
                    title: false,
                    hintText: 'Select who paid',
                    items: [for (final user in people) _labelFor(user, _me)],
                    value: _paidById == null
                        ? null
                        : _labelFor(
                            people.firstWhere(
                              (user) => user.uid == _paidById,
                              orElse: () => people.isEmpty
                                  ? const AppUser(uid: '', name: '', email: '')
                                  : people.first,
                            ),
                            _me,
                          ),
                    onChanged: (label) {
                      if (label == null) return;
                      for (final user in people) {
                        if (_labelFor(user, _me) == label) {
                          setState(() {
                            _paidById = user.uid;
                            _selected.add(user.uid);
                          });
                          return;
                        }
                      }
                    },
                  ),
                  const SizedBox(height: AppSpace.lg),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Who are you asking?',
                          style: AppText.label,
                        ),
                      ),
                      PillButton(
                        label: _selected.length == people.length
                            ? 'Just me'
                            : 'Everyone',
                        onTap: () => setState(() {
                          if (_selected.length == people.length) {
                            _selected
                              ..clear()
                              ..addAll({?_paidById, if (_me.isNotEmpty) _me});
                          } else {
                            _selected
                              ..clear()
                              ..addAll(people.map((user) => user.uid));
                          }
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),

                  if (people.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpace.sm),
                      decoration: AppDecor.well(radius: AppRadius.sm),
                      child: Text(
                        'Still loading the office list...',
                        style: AppText.caption,
                      ),
                    )
                  else
                    Container(
                      constraints: const BoxConstraints(maxHeight: 240),
                      decoration: AppDecor.well(radius: AppRadius.sm),
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpace.xxs,
                        ),
                        children: [
                          for (final user in people)
                            SharePersonRow(
                              user: user,
                              isMe: user.uid == _me,
                              selected: _selected.contains(user.uid),
                              amountMinor: sharesByUser[user.uid] ?? 0,
                              onTap: () => setState(() {
                                if (!_selected.remove(user.uid)) {
                                  _selected.add(user.uid);
                                }
                              }),
                            ),
                        ],
                      ),
                    ),

                  const SizedBox(height: AppSpace.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpace.sm + 2),
                    decoration: AppDecor.tinted(AppColors.accentWarm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selected.isEmpty
                                    ? 'Pick who is splitting this'
                                    : 'Split ${_selected.length} '
                                          '${_selected.length == 1 ? 'way' : 'ways'}',
                                style: getSemiBoldStyle(
                                  fontSize: 13,
                                  color: AppColors.textColor,
                                ),
                              ),
                              if (_selected.length > 1)
                                Text(
                                  'if everyone accepts',
                                  style: AppText.caption,
                                ),
                            ],
                          ),
                        ),
                        Text(
                          perHead > 0
                              ? '~${PackService.currency.format(perHead, decimals: false)}'
                              : '—',
                          style: getMonoStyle(
                            fontSize: 22,
                            weight: FontWeightManager.extraBold,
                            color: AppColors.accentWarm,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpace.lg),
                  CustomButton(
                    onPress: () => _submit(viewModel),
                    text: _selected.length > 1 ? 'Send invites' : 'Add it',
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
