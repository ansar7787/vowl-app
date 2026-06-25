import 'package:flutter/foundation.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

/// Abstract interface representing the haptic feedback coordinator for Vowl.
///
/// Adheres to the Dependency Inversion Principle, facilitating easy mocking and testing.
abstract class HapticService {
  /// Default factory constructor returning the concrete thread-safe implementation.
  ///
  /// Guarantees 100% backwards compatibility with existing GetIt registers and tests.
  factory HapticService() => HapticServiceImpl();

  /// Global toggle to enable or disable haptic sensations across the application.
  bool get isHapticsEnabled;
  set isHapticsEnabled(bool value);

  /// Triggers a success haptic feedback pattern.
  Future<void> success();

  /// Triggers an error haptic feedback pattern.
  Future<void> error();

  /// Triggers a selection tick feedback pattern.
  Future<void> selection();

  /// Triggers a light haptic sensation.
  Future<void> light();

  /// Triggers a warning haptic sensation.
  Future<void> warning();

  /// Triggers a heavy haptic sensation.
  Future<void> heavy();

  /// Triggers a rhythmic dual-tick haptic feedback sequence.
  Future<void> rhythmicTick();
}

/// Concrete production-grade implementation of [HapticService].
///
/// Implements future memoization to avoid redundant platform channel crossings,
/// global haptic configuration controls, and robust exception boundaries.
class HapticServiceImpl implements HapticService {
  HapticServiceImpl._internal();

  static final HapticServiceImpl _instance = HapticServiceImpl._internal();

  /// Returns the singleton instance of [HapticServiceImpl].
  factory HapticServiceImpl() => _instance;

  bool _isHapticsEnabled = true;
  Future<bool>? _vibrationSupportFuture;

  @override
  bool get isHapticsEnabled => _isHapticsEnabled;

  @override
  set isHapticsEnabled(bool value) => _isHapticsEnabled = value;

  /// Verifies platform vibration support safely, caching the future
  /// to prevent concurrent channel crossings.
  Future<bool> _checkVibrate() async {
    if (!_isHapticsEnabled) return false;

    _vibrationSupportFuture ??= _checkPlatformSupport();
    try {
      return await _vibrationSupportFuture!;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('HapticService: vibration support check failed: $e');
      }
      return false;
    }
  }

  /// Performs the actual platform capability query safely.
  Future<bool> _checkPlatformSupport() async {
    try {
      return await Haptics.canVibrate();
    } catch (e) {
      if (kDebugMode) debugPrint('HapticService: canVibrate() failed: $e');
      return false;
    }
  }

  /// Triggers a haptic event on the native channel, wrapping calls in safety blocks.
  Future<void> _safeVibrate(HapticsType type) async {
    try {
      if (await _checkVibrate()) {
        await Haptics.vibrate(type);
      }
    } catch (e) {
      // Safe fallback: absorb exceptions to prevent crashes on simulators
      // or unsupported hardware. Haptics are a non-critical enhancement,
      // never worth crashing or blocking a user action over.
      if (kDebugMode) debugPrint('HapticService: vibrate($type) failed: $e');
    }
  }

  @override
  Future<void> success() => _safeVibrate(HapticsType.success);

  @override
  Future<void> error() => _safeVibrate(HapticsType.error);

  @override
  Future<void> selection() => _safeVibrate(HapticsType.selection);

  @override
  Future<void> light() => _safeVibrate(HapticsType.light);

  @override
  Future<void> warning() => _safeVibrate(HapticsType.warning);

  @override
  Future<void> heavy() => _safeVibrate(HapticsType.heavy);

  @override
  Future<void> rhythmicTick() async {
    try {
      if (await _checkVibrate()) {
        await Haptics.vibrate(HapticsType.light);
        await Future.delayed(const Duration(milliseconds: 100));
        await Haptics.vibrate(HapticsType.selection);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('HapticService: rhythmicTick() failed: $e');
    }
  }
}
