import 'package:flutter/material.dart';

import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

/// Controller managing morphological synthesis, injection rail state, and word formation validation.
class WordFormationController extends ChangeNotifier {
  final HapticService _hapticService;
  final SoundService _soundService;

  /// Callback executed when reporting trial outcomes to the BLoC.
  final void Function(bool isCorrect, {GameQuest? quest, String? userAnswer})
  onSubmitAnswer;

  bool _isDisposed = false;

  /// Whether the question trial has been answered.
  bool isAnswered = false;

  /// Whether the response was validated as correct, or `null` if pending.
  bool? isCorrect;

  /// Whether celebration confetti is currently active.
  bool showConfetti = false;

  /// Whether stage 1 (affix injection) has been completed.
  bool isFirstStagePassed = false;

  /// Index of the actively injected suffix option.
  int? activeSuffixIndex;

  /// Index of the suffix currently hovered over the injection rail.
  int? hoveringSuffixIndex;

  /// Index of the last processed vocabulary question.
  int lastProcessedIndex = -1;

  /// The active vocabulary quest item.
  VocabularyQuest? lastQuest;

  /// Creates a [WordFormationController] instance.
  WordFormationController({
    required HapticService hapticService,
    required SoundService soundService,
    required this.onSubmitAnswer,
  }) : _hapticService = hapticService,
       _soundService = soundService;

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Resets controller state for a new quest or retry attempt.
  void reset(VocabularyQuest quest, int index) {
    if (_isDisposed) return;
    lastQuest = quest;
    lastProcessedIndex = index;
    isAnswered = false;
    isCorrect = null;
    isFirstStagePassed = false;
    activeSuffixIndex = null;
    hoveringSuffixIndex = null;
    notifyListeners();
  }

  /// Triggers level-complete celebration confetti.
  void completeGame() {
    if (showConfetti) return;
    showConfetti = true;
    notifyListeners();
  }

  /// Clears active celebration confetti.
  void clearConfetti() {
    showConfetti = false;
    notifyListeners();
  }

  /// Updates the hovering rail index and triggers selection haptic feedback.
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

  /// Validates and applies the injected morphological affix.
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
      onSubmitAnswer(false, quest: lastQuest, userAnswer: suffix);
      return;
    }
    notifyListeners();
  }

  /// Submits the final stage spelling confirmation attempt.
  void submitFinalAnswer(bool nailedIt, {String? wrongWord}) {
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
      onSubmitAnswer(false, quest: lastQuest, userAnswer: wrongWord);
    }
  }
}
