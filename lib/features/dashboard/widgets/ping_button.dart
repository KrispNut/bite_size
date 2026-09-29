import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/core/alerts/toast.dart';
import '/core/services/sound_service.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/text_styles.dart';
import '/features/dashboard/dashboard_viewmodel.dart';

/// The app bar's one-tap nag to whoever is flagged as the ping target. Solid
/// accent, because being noticed is its whole job. Hidden for the target
/// themselves and in packs without the ping module.
class PingButton extends StatefulWidget {
  const PingButton({super.key});

  @override
  State<PingButton> createState() => _PingButtonState();
}

class _PingButtonState extends State<PingButton> {
  bool _pressed = false;

  void _ping(DashboardViewModel viewModel) {
    final name = viewModel.pingTargetName;
    SoundService.instance.playTapSound();
    ShowToastDialog.whileLoading(
      'Pinging $name...',
      viewModel.ping,
      success: 'Pinged $name 🔔',
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    if (!viewModel.showPing) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
      child: Center(
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            _ping(viewModel);
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedSlide(
            offset: _pressed ? const Offset(0.03, 0.12) : Offset.zero,
            duration: const Duration(milliseconds: 80),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentFill,
                borderRadius: AppRadius.rXs,
                border: AppDecor.stroke,
                boxShadow: _pressed ? const [] : AppShadow.card,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    size: 15,
                    color: AppColors.onAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'PING ${viewModel.pingTargetName.toUpperCase()}',
                    style: getMonoStyle(
                      color: AppColors.onAccent,
                      fontSize: 11,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
