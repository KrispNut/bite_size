import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '/core/alerts/toast.dart';
import '/core/theme/activity_packs.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import '/core/widgets/currency_prefix.dart';
import '/core/widgets/custom_button.dart';
import '/core/widgets/custom_textfield.dart';
import '/core/widgets/sheet_handle.dart';
import '/features/ledger/ledger_viewmodel.dart';
import 'bill_total_tile.dart';

/// The admin bills the month in one go: one price per roti, applied to every
/// day that hasn't been settled yet.
class SettleMonthSheet extends StatefulWidget {
  final LedgerViewModel viewModel;

  const SettleMonthSheet({super.key, required this.viewModel});

  static Future<void> show(BuildContext context, LedgerViewModel viewModel) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      barrierColor: AppColors.scrim,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.sheet,
        side: BorderSide(color: AppColors.ink, width: AppDecor.strokeWidth),
      ),
      builder: (_) => SettleMonthSheet(viewModel: viewModel),
    );
  }

  @override
  State<SettleMonthSheet> createState() => _SettleMonthSheetState();
}

class _SettleMonthSheetState extends State<SettleMonthSheet> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _priceController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _priceController.removeListener(_refresh);
    _priceController.dispose();
    super.dispose();
  }

  double get _unitPrice => double.tryParse(_priceController.text.trim()) ?? 0;

  String get _monthName =>
      DateFormat('MMMM').format(widget.viewModel.currentMonth);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final viewModel = widget.viewModel;
    final price = _unitPrice;
    final month = _monthName;

    Navigator.of(context).pop();
    await ShowToastDialog.whileLoading(
      'Settling $month...',
      () => viewModel.settleMonth(price),
      success: '$month settled 💰',
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = PackService.labels;
    final viewModel = widget.viewModel;
    final units = viewModel.unsettledUnits;
    final days = viewModel.unsettledSessionIds.length;

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
              BillTotalTile(
                total: units * _unitPrice,
                caption: viewModel.monthLabel,
              ),
              const SizedBox(height: AppSpace.md),
              CustomTextField(
                context: context,
                controller: _priceController,
                label: 'Price per ${labels.unit}',
                hintText: 'e.g. 25',
                helperText:
                    '${labels.unitCount(units)} across $days '
                    '${days == 1 ? 'day' : 'days'}',
                type: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                prefix: const CurrencyPrefix(),
                validatorFn: (_) => units > 0 && _unitPrice <= 0
                    ? 'Enter the price per ${labels.unit}'
                    : null,
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                '${labels.expensePluralTitle} are billed too, at the split '
                'everyone already agreed to.',
                style: AppText.caption,
              ),
              const SizedBox(height: AppSpace.lg),
              CustomButton(
                onPress: _submit,
                text: 'Settle $_monthName',
                btnColor: AppColors.primaryDeep,
                textColor: AppColors.textOnBrand,
                isIcon: true,
                iconData: Icons.check_circle_outline_rounded,
                iconColor: AppColors.textOnBrand,
                height: 56,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
