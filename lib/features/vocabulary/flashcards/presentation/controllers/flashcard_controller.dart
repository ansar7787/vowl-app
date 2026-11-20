import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vowl/core/utils/haptic_service.dart';

/// Manages interactive UI mechanics for the Flashcard mini-game.
///
/// Architecture notes:
/// - [ChangeNotifier] manages macro screen state ([isAnswered], [isCorrect], hints, confetti).
/// - [ValueNotifier] is deliberately used for [dragOffset], [dragAngle], [dragProgress],
///   [comboStreak], and [isFlipped] so high-frequency (60-120 FPS) card dragging and flipping
///   only repaint isolated card widgets without forcing full [VocabularyBaseLayout] rebuilds.
class FlashcardController extends ChangeNotifier {
  final HapticService _hapticService;
  final void Function(bool) onSubmitAnswer;

  bool _isDisposed = false;
  Timer? _hintTimer;

  // High-frequency gesture listenables (isolated card repainting)
  final ValueNotifier<Offset> dragOffset = ValueNotifier(Offset.zero);
  final ValueNotifier<double> dragAngle = ValueNotifier(0.0);
  final ValueNotifier<double> dragProgress = ValueNotifier(0.0);
  final ValueNotifier<bool> isFlipped = ValueNotifier(false);
  final ValueNotifier<int> comboStreak = ValueNotifier(0);

  // Macro screen state properties
  bool isAnswered = false;
  bool isRetrying = false;
  bool? isCorrect;
  bool showConfetti = false;
  bool isHintActive = false;

  FlashcardController({
    required HapticService hapticService,
    required this.onSubmitAnswer,
  }) : _hapticService = hapticService;

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  /// Resets controller state for a new flashcard trial or retry attempt.
  void reset(bool retry) {
    _hintTimer?.cancel();
    isAnswered = false;
    isRetrying = retry;
    isCorrect = null;
    isHintActive = false;
    isFlipped.value = false;
    dragOffset.value = Offset.zero;
    dragAngle.value = 0.0;
    dragProgress.value = 0.0;
    if (retry) {
      comboStreak.value = 0;
    }
    notifyListeners();
  }

  /// Triggers level-complete celebration confetti.
  void completeGame() {
    if (showConfetti || _isDisposed) return;
    showConfetti = true;
    notifyListeners();
  }

  /// Handles horizontal card dragging gestures and updates card orientation.
  void onHorizontalDragUpdate(
    DragUpdateDetails details, [
    double threshold = 120.0,
  ]) {
    if (isAnswered || _isDisposed) return;
    if (isRetrying) {
      isRetrying = false;
      notifyListeners();
    }
    final oldDx = dragOffset.value.dx;
    final newDx = oldDx + details.delta.dx;
    dragOffset.value = Offset(newDx, 0);
    dragAngle.value = newDx / 500;
    dragProgress.value = (newDx / threshold).clamp(-1.0, 1.0);

    if ((newDx - oldDx).abs() > 0 && (newDx.abs() % 20 < 2)) {
      _hapticService.selection();
    }
  }

  /// Evaluates swipe velocity and displacement upon release against the drag [threshold].
  void onHorizontalDragEnd(DragEndDetails details, double threshold) {
    if (isAnswered || _isDisposed) return;
    if (dragOffset.value.dx.abs() > threshold) {
      submitAnswer(dragOffset.value.dx > 0);
    } else {
      dragOffset.value = Offset.zero;
      dragAngle.value = 0.0;
      dragProgress.value = 0.0;
    }
  }

  /// Submits whether the learner mastered or missed the vocabulary card.
  void submitAnswer(bool mastered) {
    if (isAnswered || _isDisposed) return;
    _hintTimer?.cancel();

    isAnswered = true;
    isCorrect = mastered;
    dragOffset.value = Offset(mastered ? 1000 : -1000, 0);
    dragProgress.value = mastered ? 1.0 : -1.0;

    if (mastered) {
      comboStreak.value++;
      _hapticService.success();
    } else {
      comboStreak.value = 0;
      _hapticService.error();
    }

    notifyListeners();
    onSubmitAnswer(mastered);
  }

  /// Reveals the definition card face temporarily as a pedagogical hint.
  void requestHint() {
    if (isFlipped.value || isAnswered || _isDisposed) return;
    isFlipped.value = true;
    isHintActive = true;
    notifyListeners();

    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 4), () {
      if (_isDisposed || !isHintActive || isAnswered) return;
      isFlipped.value = false;
      isHintActive = false;
      notifyListeners();
    });
  }

  /// Flips the card between prompt and definition faces.
  void flipCard() {
    if (isAnswered || _isDisposed) return;
    _hapticService.light();
    if (isRetrying) {
      isRetrying = false;
      notifyListeners();
    }
    isFlipped.value = !isFlipped.value;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _hintTimer?.cancel();
    dragOffset.dispose();
    dragAngle.dispose();
    dragProgress.dispose();
    isFlipped.dispose();
    comboStreak.dispose();
    super.dispose();
  }
}
