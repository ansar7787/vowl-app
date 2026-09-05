import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';

class FlashcardController extends ChangeNotifier {
  final HapticService _hapticService;
  final SoundService _soundService;
  final void Function(bool) onSubmitAnswer;

  final ValueNotifier<Offset> dragOffset = ValueNotifier(Offset.zero);
  final ValueNotifier<double> dragAngle = ValueNotifier(0.0);
  final ValueNotifier<bool> isFlipped = ValueNotifier(false);

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
    isFlipped.value = false;
    isHintActive = false;
    dragOffset.value = Offset.zero;
    dragAngle.value = 0.0;
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
    if (isAnswered) return;
    if (dragOffset.value.dx.abs() > threshold) {
      submitAnswer(dragOffset.value.dx > 0);
    } else {
      dragOffset.value = Offset.zero;
      dragAngle.value = 0.0;
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
    dragOffset.value = Offset(mastered ? 1000 : -1000, 0);
    notifyListeners();

    onSubmitAnswer(mastered);
  }

  void requestHint() {
    if (isFlipped.value) return;
    isFlipped.value = true;
    isHintActive = true;
    notifyListeners();

    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 4), () {
      if (!isHintActive || isAnswered) return;
      isFlipped.value = false;
      isHintActive = false;
      notifyListeners();
    });
  }

  void flipCard() {
    if (isAnswered) return;
    _hapticService.light();
    if (isRetrying) {
      isRetrying = false;
      notifyListeners();
    }
    isFlipped.value = !isFlipped.value;
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    dragOffset.dispose();
    dragAngle.dispose();
    isFlipped.dispose();
    super.dispose();
  }
}
