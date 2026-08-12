import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:lottie/lottie.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_dimens.dart';
import '/core/theme/textfont_styles.dart';
import '/generated/assets.dart';

/// Global navigator key so toasts/loaders can be shown without a [BuildContext].
/// Must be attached to the [MaterialApp]'s `navigatorKey`.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

enum ToastPosition { top, bottom, center }

/// Drop-in replacement for the old flutter_easyloading based dialog.
/// Keeps the same static API (`showToast`, `showLoader`, `closeLoader`,
/// `funcShowSnackBar`) so existing call sites don't need to change.
class ShowToastDialog {
  static OverlayEntry? _loaderEntry;
  static OverlayEntry? _toastEntry;
  static Timer? _toastTimer;

  static OverlayState? get _overlay => appNavigatorKey.currentState?.overlay;

  /// Inserting into the Overlay calls setState on it, which isn't allowed
  /// while the widget tree is mid-build (e.g. from a controller constructor
  /// triggered by a Consumer). In that case, defer until after the frame.
  static void _insert(OverlayState overlay, OverlayEntry entry) {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        overlay.insert(entry);
      });
    } else {
      overlay.insert(entry);
    }
  }

  /// Mirrors [_insert]: only remove once the entry is actually mounted,
  /// otherwise wait until after the frame that inserts it.
  static void _remove(OverlayEntry entry) {
    if (entry.mounted) {
      entry.remove();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (entry.mounted) entry.remove();
      });
    }
  }

  static void showToast(
    String? errorMessage, {
    ToastPosition position = ToastPosition.top,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (errorMessage == null) return;
    final overlay = _overlay;
    if (overlay == null) return;

    final message = extractErrorMessage(errorMessage);

    _toastTimer?.cancel();
    if (_toastEntry != null) _remove(_toastEntry!);

    final entry = OverlayEntry(
      builder: (context) => _ToastWidget(message: message, position: position),
    );
    _toastEntry = entry;
    _insert(overlay, entry);

    _toastTimer = Timer(duration, () {
      _remove(entry);
      if (_toastEntry == entry) _toastEntry = null;
    });
  }

  static void showLoader(String message) {
    final overlay = _overlay;
    if (overlay == null) return;

    closeLoader();
    final entry = OverlayEntry(
      builder: (context) => _LoaderWidget(message: message),
    );
    _loaderEntry = entry;
    _insert(overlay, entry);
  }

  static void closeLoader() {
    final entry = _loaderEntry;
    _loaderEntry = null;
    if (entry != null) _remove(entry);
  }

  static String extractErrorMessage(String error) {
    if (error.contains(']')) {
      return error.split(']').last.trim();
    }
    return error;
  }

  static void funcShowSnackBar(BuildContext context, String messageStr) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1200),
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rSm),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpace.md),
        content: Text(
          messageStr,
          textAlign: TextAlign.center,
          style: getSemiBoldStyle(color: AppColors.onPrimary, fontSize: 13.5),
        ),
      ),
    );
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastPosition position;

  const _ToastWidget({required this.message, required this.position});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> {
  double _opacity = 0;
  double _offset = -12;

  /// Messages that read as failures get the danger accent; everything else
  /// is treated as a confirmation.
  static final _errorHints = RegExp(
    r'error|fail|unable|invalid|required|denied|missing|wrong|no internet|try again',
    caseSensitive: false,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _opacity = 1;
          _offset = 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final alignment = switch (widget.position) {
      ToastPosition.top => Alignment.topCenter,
      ToastPosition.bottom => Alignment.bottomCenter,
      ToastPosition.center => Alignment.center,
    };

    final isError = _errorHints.hasMatch(widget.message);
    final accent = isError ? AppColors.danger : AppColors.success;

    return Positioned.fill(
      child: IgnorePointer(
        child: SafeArea(
          child: Align(
            alignment: alignment,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.sm,
              ),
              child: AnimatedSlide(
                offset: Offset(0, _offset / 100),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: _opacity,
                  duration: const Duration(milliseconds: 200),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.sm + 2,
                        vertical: AppSpace.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.rSm,
                        border: Border.all(
                          color: accent.withValues(alpha: 0.35),
                        ),
                        boxShadow: AppShadow.raised,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isError
                                ? Icons.error_outline_rounded
                                : Icons.check_circle_rounded,
                            size: 19,
                            color: accent,
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Flexible(
                            child: Text(
                              widget.message,
                              style: getMediumStyle(
                                color: AppColors.textColor,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoaderWidget extends StatelessWidget {
  final String message;

  const _LoaderWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: AppColors.scrim,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                Assets.lottie.loading.path,
                width: 64,
                height: 64,
                fit: BoxFit.contain,
              ),
              if (message.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpace.sm),
                Material(
                  color: Colors.transparent,
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: getSemiBoldStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
