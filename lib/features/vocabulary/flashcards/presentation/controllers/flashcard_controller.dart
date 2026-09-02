import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';

class FlashcardController extends ChangeNotifier {
  final HapticService _hapticService;
  final SoundService _soundService;
  final void Function(bool) onSubmitAnswer;

  Offset dragOffset = Offset.zero;
  double dragAngle = 0.0;
  bool isFlipped = false;
  bool isAnswered = false;
  bool isRetrying = false;
  bool? isCorrect;
  bool showConfetti = false;
  bool isHintActive = false;

  Timer? _hintTimer;

  FlashcardController({
    required HapticService hapticService,
    required SoundService soundService,
    required this.onSubmitAnswer,
  }) : _hapticService = hapticService,
       _soundService = soundService;

  void reset(bool retry) {
    _hintTimer?.cancel();
    isAnswered = false;
    isRetrying = retry;
    isCorrect = null;
    isFlipped = false;
    isHintActive = false;
    dragOffset = Offset.zero;
    dragAngle = 0.0;
    notifyListeners();
  }

  void completeGame() {
    if (showConfetti) return;
    showConfetti = true;
    notifyListeners();
  }

  void onHorizontalDragUpdate(DragUpdateDetails details) {
    if (isAnswered) return;
    if (isRetrying) {
      isRetrying = false;
    }
    final oldDx = dragOffset.dx;
    dragOffset = Offset(dragOffset.dx + details.delta.dx, 0);
    dragAngle = dragOffset.dx / 500;

    if ((dragOffset.dx - oldDx).abs() > 0 && (dragOffset.dx.abs() % 20 < 2)) {
      _hapticService.selection();
    }
    notifyListeners();
  }

  void onHorizontalDragEnd(DragEndDetails details, double threshold) {
    if (isAnswered) return;
    if (dragOffset.dx.abs() > threshold) {
      submitAnswer(dragOffset.dx > 0);
    } else {
      dragOffset = Offset.zero;
      dragAngle = 0.0;
      notifyListeners();
    }
  }

  void submitAnswer(bool mastered) {
    if (isAnswered) return;
    _hintTimer?.cancel();

    if (mastered) {
      _hapticService.success();
      _soundService.playCorrect();
    } else {
      _hapticService.error();
      _soundService.playWrong();
    }

    isAnswered = true;
    isCorrect = mastered;
    dragOffset = Offset(mastered ? 1000 : -1000, 0);
    notifyListeners();

    onSubmitAnswer(mastered);
  }

  void requestHint() {
    if (isFlipped) return;
    isFlipped = true;
    isHintActive = true;
    notifyListeners();

    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 4), () {
      if (!isHintActive || isAnswered) return;
      isFlipped = false;
      isHintActive = false;
      notifyListeners();
    });
  }

  void flipCard() {
    if (isAnswered) return;
    _hapticService.light();
    if (isRetrying) isRetrying = false;
    isFlipped = !isFlipped;
    notifyListeners();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }
}
