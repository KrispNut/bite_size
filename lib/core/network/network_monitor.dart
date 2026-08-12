import 'dart:io';
import 'dart:async';
import 'package:bite_size/generated/assets.dart';
import 'package:lottie/lottie.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_dimens.dart';
import '/core/theme/textfont_styles.dart';
import 'package:flutter/material.dart';
import '/core/alerts/app_alerts.dart';

class NetworkMonitor {
  static final NetworkMonitor _instance = NetworkMonitor._internal();
  factory NetworkMonitor() => _instance;
  NetworkMonitor._internal();

  bool _isDialogVisible = false;
  bool _hasDetectedDisconnect = false;
  bool _paused = false;
  Timer? _timer;

  final StreamController<bool> _reconnectStreamController =
      StreamController<bool>.broadcast();
  Stream<bool> get onReconnectedStream => _reconnectStreamController.stream;

  void pause() => _paused = true;
  void resume() => _paused = false;

  void startMonitoring({VoidCallback? onReconnected}) {
    _timer?.cancel();
    _paused = false;
    _hasDetectedDisconnect = false;
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_paused) return;
      bool isConnected = await hasInternet();
      final context = appNavigatorKey.currentContext;

      if (context == null) return;

      if (!isConnected) {
        _hasDetectedDisconnect = true;
        if (!_isDialogVisible && context.mounted) {
          showNoInternetDialog(context);
        }
      } else if (_isDialogVisible && _hasDetectedDisconnect) {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        _isDialogVisible = false;
        _reconnectStreamController.add(true);

        onReconnected?.call();
      }
    });
  }

  Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('www.google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void showNoInternetDialog(BuildContext context) {
    if (_isDialogVisible) return;
    _isDialogVisible = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(AppSpace.lg),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.rLg,
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadow.raised,
            ),
            padding: const EdgeInsets.all(AppSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 120,
                  width: 200,
                  child: Lottie.asset(
                    Assets.lottie.noInternet,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.wifi_off_rounded,
                      size: 56,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                Text('Connection lost', style: AppText.h2),
                const SizedBox(height: AppSpace.xxs),
                Text(
                  'Waiting for the network to come back…',
                  textAlign: TextAlign.center,
                  style: AppText.bodySm,
                ),
                const SizedBox(height: AppSpace.md),
                SizedBox(
                  width: 90,
                  child: ClipRRect(
                    borderRadius: AppRadius.rPill,
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: AppColors.primary,
                      backgroundColor: AppColors.surfaceAlt,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }
}
