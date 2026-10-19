import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vowl/core/utils/haptic_service.dart';

/// Manages interactive UI mechanics for the Flashcard mini-game.
///
/// Architecture notes:
/// - [ChangeNotifier] manages macro screen state ([isAnswered], [isCorrect], hints, confetti).
/// - [ValueNotifier] is deliberately used for [dragOffset], [dragAngle], and [isFlipped] so
///   high-frequency (60-120 FPS) card dragging and flipping only repaint isolated card widgets
///   without forcing full [VocabularyBaseLayout] rebuilds.
class FlashcardController extends ChangeNotifier {
  final HapticService _hapticService;
  final void Function(bool) onSubmitAnswer;

  bool _isDisposed = false;
  Timer? _hintTimer;

  // High-frequency gesture listenables (isolated card repainting)
  final ValueNotifier<Offset> dragOffset = ValueNotifier(Offset.zero);
  final ValueNotifier<double> dragAngle = ValueNotifier(0.0);
  final ValueNotifier<bool> isFlipped = ValueNotifier(false);

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

  void reset(bool retry) {
    _hintTimer?.cancel();
    isAnswered = false;
    isRetrying = retry;
    isCorrect = null;
    isHintActive = false;
    isFlipped.value = false;
    dragOffset.value = Offset.zero;
    dragAngle.value = 0.0;
    notifyListeners();
  }

  void completeGame() {
    if (showConfetti || _isDisposed) return;
    showConfetti = true;
    notifyListeners();
  }

  void onHorizontalDragUpdate(DragUpdateDetails details) {
    if (isAnswered || _isDisposed) return;
    if (isRetrying) {
      isRetrying = false;
      notifyListeners();
    }
    final oldDx = dragOffset.value.dx;
    dragOffset.value = Offset(oldDx + details.delta.dx, 0);
    dragAngle.value = dragOffset.value.dx / 500;

    if ((dragOffset.value.dx - oldDx).abs() > 0 &&
        (dragOffset.value.dx.abs() % 20 < 2)) {
      _hapticService.selection();
    }
  }

  void onHorizontalDragEnd(DragEndDetails details, double threshold) {
    if (isAnswered || _isDisposed) return;
    if (dragOffset.value.dx.abs() > threshold) {
      submitAnswer(dragOffset.value.dx > 0);
    } else {
      dragOffset.value = Offset.zero;
      dragAngle.value = 0.0;
    }
  }

  void submitAnswer(bool mastered) {
    if (isAnswered || _isDisposed) return;
    _hintTimer?.cancel();

    isAnswered = true;
    isCorrect = mastered;
    dragOffset.value = Offset(mastered ? 1000 : -1000, 0);
    notifyListeners();

    onSubmitAnswer(mastered);
  }

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
    isFlipped.dispose();
    super.dispose();
  }
}
