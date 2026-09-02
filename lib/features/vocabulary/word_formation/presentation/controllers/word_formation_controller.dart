import 'package:flutter/material.dart';

import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

class WordFormationController extends ChangeNotifier {
  final HapticService _hapticService;
  final SoundService _soundService;
  final void Function(bool) onSubmitAnswer;

  bool isAnswered = false;
  bool? isCorrect;
  bool showConfetti = false;
  bool isFirstStagePassed = false;
  int? activeSuffixIndex;
  int? hoveringSuffixIndex;

  int lastProcessedIndex = -1;
  VocabularyQuest? lastQuest;

  WordFormationController({
    required HapticService hapticService,
    required SoundService soundService,
    required this.onSubmitAnswer,
  }) : _hapticService = hapticService,
       _soundService = soundService;

  void reset(VocabularyQuest quest, int index) {
    lastQuest = quest;
    lastProcessedIndex = index;
    isAnswered = false;
    isCorrect = null;
    isFirstStagePassed = false;
    activeSuffixIndex = null;
    hoveringSuffixIndex = null;
    notifyListeners();
  }

  void completeGame() {
    if (showConfetti) return;
    showConfetti = true;
    notifyListeners();
  }

  void clearConfetti() {
    showConfetti = false;
    notifyListeners();
  }

  void setHoveringIndex(int? index) {
    if (isAnswered) return;
    if (hoveringSuffixIndex != index) {
      hoveringSuffixIndex = index;
      if (index != null) {
        _hapticService.selection();
      }
      notifyListeners();
    }
  }

  void submitMorph(String suffix, String root, String correct, int index) {
    if (isAnswered) return;

    activeSuffixIndex = index;
    hoveringSuffixIndex = null;

    final target = correct.trim().toLowerCase();
    bool guessedRight = false;
    String cleanS = suffix.replaceAll('-', '').trim().toLowerCase();
    if (target.endsWith(cleanS) || target.startsWith(cleanS)) {
      guessedRight = true;
    }

    if (guessedRight) {
      _hapticService.success();
      isFirstStagePassed = true;
    } else {
      _hapticService.error();
      _soundService.playWrong();
      isAnswered = true;
      isCorrect = false;
      notifyListeners();
      onSubmitAnswer(false);
      return;
    }
    notifyListeners();
  }

  void submitFinalAnswer(bool nailedIt) {
    if (isAnswered) return;

    isAnswered = true;
    isCorrect = nailedIt;
    notifyListeners();

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      onSubmitAnswer(true);
    } else {
      _hapticService.error();
      _soundService.playWrong();
      onSubmitAnswer(false);
    }
  }
}
