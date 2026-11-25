import 'dart:async';
import 'package:flutter/foundation.dart';

/// State and logic controller for Prefix & Suffix game modes (Practice & Mastery).
///
/// Encapsulates:
/// - Vault cracker state for Practice phase (slotting, lock/jam/unlock).
/// - 5-second countdown timer with fractional progress for Mastery arcade phase.
/// - Hit-testing validation for morpheme seam slicing.
/// - Dynamic streak and combo multiplier tracking (1x up to 10x).
class PrefixSuffixController extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // Practice Phase State (Vault Combination Cracker)
  // ---------------------------------------------------------------------------
  String? _slottedAffix;
  bool _isJammed = false;
  bool _isUnlocked = false;
  int _hintsUsed = 0;

  String? get slottedAffix => _slottedAffix;
  bool get isJammed => _isJammed;
  bool get isUnlocked => _isUnlocked;
  int get hintsUsed => _hintsUsed;

  /// Slots an affix into the vault combination lock.
  ///
  /// Returns `true` if the affix matches [correctAffix], `false` otherwise.
  bool slotAffix(String affix, String correctAffix) {
    _slottedAffix = affix;
    final isCorrect =
        affix.trim().toUpperCase() == correctAffix.trim().toUpperCase();

    if (isCorrect) {
      _isUnlocked = true;
      _isJammed = false;
    } else {
      _isUnlocked = false;
      _isJammed = true;
    }
    notifyListeners();
    return isCorrect;
  }

  /// Resets the slotted affix and clears jamming feedback.
  void clearSlot() {
    _slottedAffix = null;
    _isJammed = false;
    _isUnlocked = false;
    notifyListeners();
  }

  /// Increments the hint count for practice drills.
  void useHint() {
    _hintsUsed++;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Mastery Phase State (Morpheme Precision Slicer)
  // ---------------------------------------------------------------------------
  Timer? _masteryTimer;
  int _totalMilliseconds = 10000;
  int _remainingMilliseconds = 10000;
  bool _isPaused = false;
  bool _isAnswered = false;
  bool _isSliced = false;
  bool _isWrongCut = false;
  int _streak = 0;
  int _comboMultiplier = 1;

  double get timeFraction => _totalMilliseconds > 0
      ? _remainingMilliseconds / _totalMilliseconds
      : 0.0;

  int get secondsRemaining => (_remainingMilliseconds / 1000).ceil();
  bool get isAnswered => _isAnswered;
  bool get isSliced => _isSliced;
  bool get isWrongCut => _isWrongCut;
  int get streak => _streak;
  int get comboMultiplier => _comboMultiplier;

  /// Pauses the countdown timer during pause menus or dialogs.
  void pauseMasteryTimer() {
    _isPaused = true;
  }

  /// Resumes the countdown timer when gameplay resumes.
  void resumeMasteryTimer() {
    _isPaused = false;
  }

  /// Starts or resets the 10-second countdown timer for a Mastery quest.
  void startMasteryTimer({int durationSeconds = 10, VoidCallback? onExpired}) {
    stopMasteryTimer();
    _isPaused = false;
    _totalMilliseconds = durationSeconds * 1000;
    _remainingMilliseconds = _totalMilliseconds;
    _isAnswered = false;
    _isSliced = false;
    _isWrongCut = false;
    notifyListeners();

    _masteryTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isPaused) return;
      if (_remainingMilliseconds > 100) {
        _remainingMilliseconds -= 100;
        notifyListeners();
      } else {
        _remainingMilliseconds = 0;
        _isAnswered = true;
        stopMasteryTimer();
        notifyListeners();
        onExpired?.call();
      }
    });
  }

  /// Halts the active mastery countdown timer.
  void stopMasteryTimer() {
    _masteryTimer?.cancel();
    _masteryTimer = null;
  }

  /// Evaluates a slice attempt at [cutIndex] against [correctCutIndex] or optional [secondaryCutIndex].
  ///
  /// Returns `true` if the cut severed a legitimate morpheme seam.
  bool evaluateSlice({
    required int cutIndex,
    required int correctCutIndex,
    int? secondaryCutIndex,
  }) {
    if (_isAnswered) return false;

    _isAnswered = true;
    stopMasteryTimer();

    final isCorrect =
        cutIndex == correctCutIndex ||
        (secondaryCutIndex != null && cutIndex == secondaryCutIndex);
    if (isCorrect) {
      _isSliced = true;
      _isWrongCut = false;
      _streak++;
      _comboMultiplier = (_streak ~/ 2 + 1).clamp(1, 10);
    } else {
      _isSliced = false;
      _isWrongCut = true;
      _streak = 0;
      _comboMultiplier = 1;
    }

    notifyListeners();
    return isCorrect;
  }

  /// Resets state for a new quest round.
  void resetForNextQuest() {
    stopMasteryTimer();
    _slottedAffix = null;
    _isJammed = false;
    _isUnlocked = false;
    _isAnswered = false;
    _isSliced = false;
    _isWrongCut = false;
    _remainingMilliseconds = _totalMilliseconds;
    notifyListeners();
  }

  @override
  void dispose() {
    stopMasteryTimer();
    super.dispose();
  }
}
