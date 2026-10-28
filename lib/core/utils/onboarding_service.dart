import 'package:shared_preferences/shared_preferences.dart';

/// Central service managing the first-time user onboarding state.
///
/// ### Architecture & Performance
/// Synchronous memory caching via [loadCached] ensures that [AppRouter] and [SplashPage]
/// evaluate routing decisions with zero async latency, eliminating splash screen flashes,
/// redirection glitches, and popup collisions.
///
/// ### Storage
/// Persisted in [SharedPreferences] under the canonical key:
/// `has_seen_vowl_welcome_showcase`.
class OnboardingService {
  OnboardingService._();

  /// Canonical SharedPreferences key used to persist onboarding completion status.
  /// Maintained for backwards compatibility with existing user sessions.
  static const String prefsKeyHasSeenOnboarding =
      'has_seen_vowl_welcome_showcase';

  static bool _cachedIsCompleted = false;

  /// Returns whether the onboarding experience has been completed or bypassed.
  ///
  /// Safe to call synchronously in router redirects and widget builds after
  /// [loadCached] has executed during app startup.
  static bool get isCompletedCached => _cachedIsCompleted;

  /// Pre-loads the onboarding completion state into memory.
  ///
  /// Executed in parallel with other essential services in `main.dart`.
  static Future<void> loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedIsCompleted = prefs.getBool(prefsKeyHasSeenOnboarding) ?? false;
    } catch (_) {
      // In case of I/O failure, safe-default to true if user state is already known,
      // or false to ensure users aren't locked out.
      _cachedIsCompleted = false;
    }
  }

  /// Marks the onboarding flow as completed.
  ///
  /// Updates in-memory cache immediately, then writes to persistent storage.
  static Future<void> completeOnboarding() async {
    _cachedIsCompleted = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefsKeyHasSeenOnboarding, true);
    } catch (_) {}
  }

  /// Evaluates an authenticated user's progress.
  ///
  /// If a returning user reinstalls the app on a new device but has already
  /// completed levels ([totalLevelsCompleted] > 0), mark onboarding as complete
  /// so seasoned players are not forced through beginner slides.
  static Future<void> evaluateUserProgress(int totalLevelsCompleted) async {
    if (totalLevelsCompleted > 0 && !_cachedIsCompleted) {
      await completeOnboarding();
    }
  }

  /// Resets the onboarding state.
  ///
  /// Used for developer testing, automated UI verification, or user-facing "Replay Intro".
  static Future<void> resetOnboarding() async {
    _cachedIsCompleted = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefsKeyHasSeenOnboarding);
    } catch (_) {}
  }
}

