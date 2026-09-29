import 'package:flutter/services.dart';

/// Centralized service providing crisp audio and tactile haptic feedback
/// across all interactions, buttons, cards, and tiles.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  bool _soundEnabled = true;
  bool get isSoundEnabled => _soundEnabled;

  void toggleSound(bool enabled) {
    _soundEnabled = enabled;
  }

  /// Soft tactile tap feedback for cards, tiles, and containers.
  Future<void> playTapSound() async {
    if (!_soundEnabled) return;
    try {
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Feedback for counter increments, decrements, and step adjustments.
  Future<void> playStepSound() async {
    if (!_soundEnabled) return;
    try {
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Feedback for toggles, checkboxes, and radio buttons.
  Future<void> playToggleSound() async {
    if (!_soundEnabled) return;
    try {
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Feedback for major actions (e.g. Save, Claim, Submit).
  Future<void> playActionSound() async {
    if (!_soundEnabled) return;
    try {
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}
