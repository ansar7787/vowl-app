import 'package:shared_preferences/shared_preferences.dart';

/// Manages the one-time age gate that determines whether the user sees
/// personalized or non-personalized ads.
///
/// ### Why this exists
/// Without an age gate, ALL users get non-personalized ads (COPPA safe-default),
/// which have 2-3x lower eCPM than personalized ads. By asking once whether the
/// user is 16+, we can legally serve personalized ads to adults while keeping
/// children protected.
///
/// ### Storage
/// A single SharedPreferences key: `age_gate_completed`.
/// - `null` → never asked (show age gate)
/// - `true`  → user said they are 16+ (personalized ads allowed)
/// - `false` → user said they are under 16 (non-personalized only)
class AgeGateService {
  static const String _keyAgeGateCompleted = 'age_gate_completed';
  static const String _keyIsAdult = 'age_gate_is_adult';

  /// Whether the age gate has been shown and answered.
  static Future<bool> isAgeGateCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyAgeGateCompleted);
  }

  /// Whether the user declared themselves as 16+.
  /// Returns `false` if age gate hasn't been completed yet (safe default).
  static Future<bool> isAdult() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsAdult) ?? false;
  }

  /// Synchronous version — only call after [loadCached] has been called.
  static bool get isAdultCached => _cachedIsAdult;
  static bool get isCompletedCached => _cachedIsCompleted;

  static bool _cachedIsAdult = false;
  static bool _cachedIsCompleted = false;

  /// Pre-loads the age gate state into memory for synchronous access.
  /// Call once during app startup (e.g., in DI initialization).
  static Future<void> loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedIsCompleted = prefs.containsKey(_keyAgeGateCompleted);
    _cachedIsAdult = prefs.getBool(_keyIsAdult) ?? false;
  }

  /// Records the user's age declaration. Called once from the age gate screen.
  static Future<void> completeAgeGate({required bool isAdult}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAgeGateCompleted, true);
    await prefs.setBool(_keyIsAdult, isAdult);
    _cachedIsCompleted = true;
    _cachedIsAdult = isAdult;
  }

  /// Resets the age gate so it will be shown again on next route evaluation.
  /// Called from Settings → "Reset Age Verification".
  static Future<void> resetAgeGate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAgeGateCompleted);
    await prefs.remove(_keyIsAdult);
    _cachedIsCompleted = false;
    _cachedIsAdult = false;
  }
}
