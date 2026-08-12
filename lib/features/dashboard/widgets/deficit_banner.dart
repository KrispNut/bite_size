import 'package:flutter/material.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_dimens.dart';
import '/core/theme/textfont_styles.dart';
import '/features/dashboard/models/lunch_session.dart';

/// The Deficit Detector readout.
class DeficitBanner extends StatelessWidget {
  final LunchSession session;
  final VoidCallback? onOrderExtra;

  const DeficitBanner({super.key, required this.session, this.onOrderExtra});

  @override
  Widget build(BuildContext context) {
    final deficit = session.portionDeficit;
    final short = session.hasDeficit;
    final accent = short ? AppColors.warning : AppColors.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.sm + 2),
      decoration: AppDecor.tinted(accent),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              short ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
              color: accent,
              size: 21,
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  short
                      ? 'Short by $deficit ${deficit == 1 ? 'portion' : 'portions'}'
                      : 'Salan covered for everyone',
                  style: getBoldStyle(color: accent, fontSize: 13.5),
                ),
                if (short) ...[
                  const SizedBox(height: 2),
                  Text('Time to order extra food?', style: AppText.bodySm),
                ],
              ],
            ),
          ),
          if (short && onOrderExtra != null)
            TextButton(
              onPressed: onOrderExtra,
              style: TextButton.styleFrom(foregroundColor: accent),
              child: Text(
                'Order',
                style: getBoldStyle(color: accent, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
