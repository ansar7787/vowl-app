import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vowl/core/utils/haptic_service.dart';

/// Objective arcade controller for Flashcard Speed Collocation Slam & Precision Strike.
///
/// Features isolated [ValueNotifier] listenables for 60-120 FPS timer progress,
/// stage progression, lives, combo streaks, and selections.
class FlashcardMasteryController extends ChangeNotifier {
  final HapticService _hapticService;
  final void Function({required bool isCorrect, required bool speedBonus})
  onSubmitResult;

  bool _isDisposed = false;
  Timer? _countdownTimer;

  // ── High-frequency isolated listenables (60-120 FPS) ─────────────────────
  final ValueNotifier<double> timerProgress = ValueNotifier<double>(1.0);
  final ValueNotifier<bool> isStage2 = ValueNotifier<bool>(false);
  final ValueNotifier<int> comboStreak = ValueNotifier<int>(0);
  final ValueNotifier<int?> selectedCollocationIndex = ValueNotifier<int?>(
    null,
  );
  final ValueNotifier<int?> selectedCandidateIndex = ValueNotifier<int?>(null);

  // ── Macro state ───────────────────────────────────────────────────────────
  bool isAnswered = false;
  bool? isCorrect;
  bool showConfetti = false;
  bool isTimeout = false;

  static const int totalSeconds = 5;
  static const int tickMilliseconds = 50;
  static const int totalTicks = (totalSeconds * 1000) ~/ tickMilliseconds;
  int _currentTick = 0;

  FlashcardMasteryController({
    required HapticService hapticService,
    required this.onSubmitResult,
  }) : _hapticService = hapticService;

  bool isPaused = false;

  void pauseTimer() {
    isPaused = true;
  }

  void resumeTimer() {
    isPaused = false;
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  /// Starts or restarts the 5-second countdown timer.
  void startTimer() {
    _countdownTimer?.cancel();
    _currentTick = 0;
    timerProgress.value = 1.0;
    isTimeout = false;

    _countdownTimer = Timer.periodic(
      const Duration(milliseconds: tickMilliseconds),
      (timer) {
        if (_isDisposed) {
          timer.cancel();
          return;
        }
        if (isPaused) return;

        _currentTick++;
        final progress = (totalTicks - _currentTick) / totalTicks;
        if (progress <= 0.0) {
          timer.cancel();
          timerProgress.value = 0.0;
          _handleTimeout();
        } else {
          timerProgress.value = progress;
        }
      },
    );
  }

  void _handleTimeout() {
    if (isAnswered || _isDisposed) return;
    isAnswered = true;
    isCorrect = false;
    isTimeout = true;
    comboStreak.value = 0;
    _hapticService.error();
    notifyListeners();
    onSubmitResult(isCorrect: false, speedBonus: false);
  }

  /// Evaluates Stage 1 (Collocation Slam).
  void slamCollocation({
    required int index,
    required bool isMatchCorrect,
    required VoidCallback onAdvanceToStage2,
  }) {
    if (isAnswered || isStage2.value || _isDisposed) return;
    selectedCollocationIndex.value = index;

    if (isMatchCorrect) {
      HapticFeedback.mediumImpact();
      _hapticService.selection();
      // Advance to Stage 2 with remaining timer
      Future.delayed(const Duration(milliseconds: 250), () {
        if (_isDisposed || isAnswered) return;
        isStage2.value = true;
        onAdvanceToStage2();
      });
    } else {
      // Wrong collocation selected
      _countdownTimer?.cancel();
      isAnswered = true;
      isCorrect = false;
      comboStreak.value = 0;
      HapticFeedback.heavyImpact();
      _hapticService.error();
      notifyListeners();
      onSubmitResult(isCorrect: false, speedBonus: false);
    }
  }

  /// Evaluates Stage 2 (Precision Sentence Strike).
  void strikeCandidateWord({
    required int index,
    required String selectedWord,
    required String targetWord,
  }) {
    if (isAnswered || !isStage2.value || _isDisposed) return;
    selectedCandidateIndex.value = index;
    _countdownTimer?.cancel();

    final isMatch =
        selectedWord.trim().toLowerCase() == targetWord.trim().toLowerCase();
    isAnswered = true;
    isCorrect = isMatch;

    if (isMatch) {
      final isSpeedBonus = timerProgress.value >= 0.5; // Answered in <2.5s
      comboStreak.value++;
      HapticFeedback.heavyImpact();
      _hapticService.success();
      notifyListeners();
      onSubmitResult(isCorrect: true, speedBonus: isSpeedBonus);
    } else {
      comboStreak.value = 0;
      HapticFeedback.heavyImpact();
      _hapticService.error();
      notifyListeners();
      onSubmitResult(isCorrect: false, speedBonus: false);
    }
  }

  /// Resets controller state for a new quest or retry attempt.
  void reset({required bool isRetry}) {
    _countdownTimer?.cancel();
    isAnswered = false;
    isCorrect = null;
    isTimeout = false;
    isStage2.value = false;
    selectedCollocationIndex.value = null;
    selectedCandidateIndex.value = null;
    timerProgress.value = 1.0;
    if (isRetry) {
      comboStreak.value = 0;
    }
    notifyListeners();
    startTimer();
  }

  /// Triggers celebration confetti on level completion.
  void triggerVictoryCelebration() {
    _countdownTimer?.cancel();
    if (showConfetti || _isDisposed) return;
    HapticFeedback.heavyImpact();
    showConfetti = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _countdownTimer?.cancel();
    timerProgress.dispose();
    isStage2.dispose();
    comboStreak.dispose();
    selectedCollocationIndex.dispose();
    selectedCandidateIndex.dispose();
    super.dispose();
  }
}
