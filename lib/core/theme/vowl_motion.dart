import 'package:flutter/widgets.dart';

/// Centralised motion design tokens for the Vowl app.
///
/// Provides standardised durations and curves so every animation across the
/// codebase shares a consistent, intentional feel — eliminating the "random
/// timings everywhere" problem that makes apps feel auto-generated.
///
/// Follows the same singleton-constant pattern as [AppDimensions].
///
/// ### Quick reference
/// | Token              | Value   | Use for                          |
/// |--------------------|---------|----------------------------------|
/// | [fast]             | 200 ms  | Micro-interactions (tap, toggle)  |
/// | [medium]           | 350 ms  | Content swaps, selection changes  |
/// | [slow]             | 500 ms  | Page transitions, overlays        |
/// | [entrance]         | 400 ms  | First-appear entrance animations  |
/// | [entranceCurve]    | easeOutCubic | Natural deceleration on enter |
/// | [exitCurve]        | easeInCubic  | Natural acceleration on exit  |
/// | [defaultCurve]     | easeInOut    | General-purpose curve         |
class VowlMotion {
  VowlMotion._();

  // ── Durations ─────────────────────────────────────────────────────────────

  /// Micro-interactions: button scale, toggle, haptic.
  static const Duration fast = Duration(milliseconds: 200);

  /// Content swaps, selection highlights, state changes.
  static const Duration medium = Duration(milliseconds: 350);

  /// Overlays, modals, full-screen transitions.
  static const Duration slow = Duration(milliseconds: 500);

  /// First-appear entrance animations (fade-in, slide-in).
  static const Duration entrance = Duration(milliseconds: 400);

  /// Staggered-item delay between consecutive list entries.
  static const Duration staggerDelay = Duration(milliseconds: 50);

  // ── Curves ────────────────────────────────────────────────────────────────

  /// Entrance animations — fast start, gentle deceleration.
  static const Curve entranceCurve = Curves.easeOutCubic;

  /// Exit / dismiss animations — gentle start, fast finish.
  static const Curve exitCurve = Curves.easeInCubic;

  /// General-purpose symmetric ease.
  static const Curve defaultCurve = Curves.easeInOut;

  /// Bouncy feedback for playful interactions (e.g., game rewards).
  static const Curve bounceCurve = Curves.easeOutBack;

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// In-app setting toggle that forces motion reduction even if the OS allows it.
  /// This is controlled by the user in the SettingsScreen.
  static final ValueNotifier<bool> lowAnimationModeOverride = ValueNotifier(false);

  /// Returns `true` when the OS "Reduce Motion" accessibility setting is
  /// enabled, or when the user has enabled "Low Animation Mode" in the app settings.
  ///
  /// Use this to gate decorative animations:
  /// ```dart
  /// if (!VowlMotion.shouldReduceMotion(context)) {
  ///   widget = widget.animate().fadeIn();
  /// }
  /// ```
  static bool shouldReduceMotion(BuildContext context) {
    if (lowAnimationModeOverride.value) return true;
    return MediaQuery.disableAnimationsOf(context);
  }
}
