import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '/core/alerts/app_alerts.dart';
import '/core/shared/custom_button.dart';
import '/core/shared/custom_textfield.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_dimens.dart';
import '/core/theme/textfont_styles.dart';
import '/core/theme/theme_service.dart';
import '/features/dashboard/dashboard_viewmodel.dart';
import '/features/dashboard/models/extra_order.dart';

class SettleBillSheet extends StatefulWidget {
  const SettleBillSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      barrierColor: AppColors.scrim,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (ctx) => const SettleBillSheet(),
    );
  }

  @override
  State<SettleBillSheet> createState() => _SettleBillSheetState();
}

class _SettleBillSheetState extends State<SettleBillSheet> {
  final _formKey = GlobalKey<FormState>();
  final _rotiCostCtrl = TextEditingController();
  final _extraNameCtrl = TextEditingController();
  final _extraCostCtrl = TextEditingController();

  final List<ExtraOrder> _extraOrders = [];

  @override
  void initState() {
    super.initState();
    // Keeps the split preview in sync as the runner types.
    _rotiCostCtrl.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  double get _rotiCost => double.tryParse(_rotiCostCtrl.text.trim()) ?? 0;

  double get _extrasTotal =>
      _extraOrders.fold<double>(0, (sum, o) => sum + o.cost);

  double get _grandTotal => _rotiCost + _extrasTotal;

  void _addExtraItem(DashboardViewModel vm) {
    final name = _extraNameCtrl.text.trim();
    final cost = double.tryParse(_extraCostCtrl.text.trim()) ?? 0;
    if (name.isEmpty || cost <= 0) {
      ShowToastDialog.showToast('Add an item name and a cost above zero.');
      return;
    }

    setState(() {
      _extraOrders.add(
        ExtraOrder(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sessionId: vm.sessionId,
          description: name,
          cost: cost,
          paidById: vm.currentUid,
          paidByName: vm.currentUserName.isEmpty
              ? 'Runner'
              : vm.currentUserName,
          sharedByIds: vm.entries.map((e) => e.userId).toList(),
        ),
      );
      _extraNameCtrl.clear();
      _extraCostCtrl.clear();
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _submit(DashboardViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop();
    ShowToastDialog.showLoader('Settling daily bill...');

    final error = await vm.settleBilling(
      totalRotiCost: _rotiCost,
      extraOrders: _extraOrders,
    );

    ShowToastDialog.closeLoader();
    ShowToastDialog.showToast(error ?? 'Bill settled & ledger updated! 💰');
  }

  @override
  void dispose() {
    _rotiCostCtrl.removeListener(_refresh);
    _rotiCostCtrl.dispose();
    _extraNameCtrl.dispose();
    _extraCostCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final digitsOnly = [FilteringTextInputFormatter.digitsOnly];
    final headcount = vm.session?.headcount ?? vm.entries.length;
    final perHead = headcount > 0 ? _grandTotal / headcount : 0.0;

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
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accentWarm.withValues(alpha: 0.13),
                          borderRadius: AppRadius.rSm,
                        ),
                        alignment: Alignment.center,
                        child: const Text('🧾', style: TextStyle(fontSize: 19)),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Settle today\'s bill', style: AppText.h3),
                            Text(
                              'Split across $headcount ${headcount == 1 ? 'person' : 'people'}',
                              style: AppText.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xl),

                    CustomTextField(
                      context: context,
                      controller: _rotiCostCtrl,
                      label: 'Bread / rotis total',
                      hintText: 'e.g. 240',
                      helperText:
                          'For ${vm.session?.totalRotis ?? 0} rotis ordered today',
                      type: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: digitsOnly,
                      prefix: const _RsPrefix(),
                      validatorFn: (v) => null, // Optional if no rotis were ordered
                    ),
                  const SizedBox(height: AppSpace.lg),

                  Text('Extra salan / side orders', style: AppText.label),
                  const SizedBox(height: AppSpace.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: CustomTextField(
                          context: context,
                          controller: _extraNameCtrl,
                          title: false,
                          hintText: 'Item, e.g. Karahi',
                          type: TextInputType.text,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Expanded(
                        flex: 2,
                        child: CustomTextField(
                          context: context,
                          controller: _extraCostCtrl,
                          title: false,
                          hintText: 'Cost',
                          type: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          inputFormatters: digitsOnly,
                          prefix: const _RsPrefix(),
                          onFieldSubmitted: (_) => _addExtraItem(vm),
                        ),
                      ),
                      const SizedBox(width: AppSpace.xs),
                      _AddButton(onTap: () => _addExtraItem(vm)),
                    ],
                  ),

                  if (_extraOrders.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.sm),
                    Container(
                      decoration: AppDecor.well(radius: AppRadius.sm),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.sm,
                        vertical: AppSpace.xxs,
                      ),
                      child: Column(
                        children: [
                          for (final item in _extraOrders)
                            _ExtraRow(
                              item: item,
                              onRemove: () => setState(
                                () => _extraOrders.removeWhere(
                                  (x) => x.id == item.id,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpace.lg),
                  _SplitSummary(
                    rotiCost: _rotiCost,
                    extrasTotal: _extrasTotal,
                    total: _grandTotal,
                    perHead: perHead,
                    headcount: headcount,
                  ),

                  const SizedBox(height: AppSpace.lg),
                  CustomButton(
                    onPress: () => _submit(vm),
                    text: 'Confirm & settle',
                    btnColor: AppColors.primary,
                    textColor: AppColors.onPrimary,
                    isIcon: true,
                    iconData: Icons.receipt_long_rounded,
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

class _RsPrefix extends StatelessWidget {
  const _RsPrefix();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpace.sm, right: 6),
      child: Text(
        'Rs',
        style: getBoldStyle(fontSize: 13, color: AppColors.textTertiary),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: AppRadius.rSm,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(Icons.add_rounded, color: AppColors.onPrimary, size: 22),
        ),
      ),
    );
  }
}

class _ExtraRow extends StatelessWidget {
  final ExtraOrder item;
  final VoidCallback onRemove;

  const _ExtraRow({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.fastfood_rounded, size: 15, color: AppColors.accentWarm),
          const SizedBox(width: AppSpace.xs),
          Expanded(
            child: Text(
              item.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: getMediumStyle(fontSize: 13, color: AppColors.textColor),
            ),
          ),
          Text(
            'Rs ${item.cost.toInt()}',
            style: getExtraBoldStyle(fontSize: 13, color: AppColors.textColor),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            borderRadius: AppRadius.rPill,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 15,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Live preview of what each person owes, so the runner can sanity-check the
/// numbers before writing them to the ledger.
class _SplitSummary extends StatelessWidget {
  final double rotiCost;
  final double extrasTotal;
  final double total;
  final double perHead;
  final int headcount;

  const _SplitSummary({
    required this.rotiCost,
    required this.extrasTotal,
    required this.total,
    required this.perHead,
    required this.headcount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.sm + 2),
      decoration: AppDecor.tinted(AppColors.primary),
      child: Column(
        children: [
          _Line(label: 'Bread', value: rotiCost),
          if (extrasTotal > 0) ...[
            const SizedBox(height: 6),
            _Line(label: 'Extras', value: extrasTotal),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
            child: Divider(color: AppColors.primaryBorder, height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Each of $headcount pays',
                  style: getSemiBoldStyle(
                    fontSize: 13,
                    color: AppColors.textColor,
                  ),
                ),
              ),
              Text(
                'Rs ${perHead.round()}',
                style: getExtraBoldStyle(
                  fontSize: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Total Rs ${total.round()}', style: AppText.caption),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final double value;

  const _Line({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: getRegularStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          'Rs ${value.round()}',
          style: getSemiBoldStyle(fontSize: 13, color: AppColors.textColor),
        ),
      ],
    );
  }
}
