import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

class PrefixSuffixController extends ChangeNotifier {
  final HapticService _hapticService;
  final SoundService _soundService;
  final TtsService _ttsService;
  final void Function(bool) onSubmitAnswer;

  Offset dragOffset = Offset.zero;
  bool isAnswered = false;
  bool? isCorrect;
  bool showConfetti = false;
  bool isFirstStagePassed = false;
  
  int lastProcessedIndex = -1;
  VocabularyQuest? lastQuest;
  BoxConstraints? lastConstraints;

  PrefixSuffixController({
    required HapticService hapticService,
    required SoundService soundService,
    required TtsService ttsService,
    required this.onSubmitAnswer,
  })  : _hapticService = hapticService,
        _soundService = soundService,
        _ttsService = ttsService;

  void reset(VocabularyQuest? quest, int index) {
    lastQuest = quest;
    lastProcessedIndex = index;
    isAnswered = false;
    isCorrect = null;
    isFirstStagePassed = false;
    dragOffset = Offset.zero;
    notifyListeners();
  }
  
  void setAnswered(bool correct) {
    isAnswered = true;
    isCorrect = correct;
    notifyListeners();
  }

  void completeGame() {
    if (showConfetti) return;
    showConfetti = true;
    notifyListeners();
  }

  void updateConstraints(BoxConstraints constraints) {
    lastConstraints = constraints;
  }

  void onRoverDrag(Offset delta) {
    if (isAnswered || isFirstStagePassed) return;
    dragOffset += delta;
    notifyListeners();
  }

  void onRoverRelease(VocabularyQuest quest, bool isCompact) {
    if (isAnswered || isFirstStagePassed) return;
    if (lastConstraints == null) return;

    final options = quest.options ?? [];
    int? dockedIndex;

    // Check collision with terminals - dynamically scale collision radius
    final double collisionDistance = isCompact ? 65.0 : 90.0;
    for (int i = 0; i < options.length; i++) {
      final terminalPos = getTerminalPosition(
        i,
        options.length,
        lastConstraints!,
        isCompact,
      );
      final roverPos = Offset.zero + dragOffset;

      if ((roverPos - terminalPos).distance < collisionDistance) {
        dockedIndex = i;
        break;
      }
    }

    if (dockedIndex != null) {
      // Visual Snap to terminal
      dragOffset = getTerminalPosition(
        dockedIndex,
        options.length,
        lastConstraints!,
        isCompact,
      );
      notifyListeners();
      _submitAffix(options[dockedIndex], quest);
    } else {
      dragOffset = Offset.zero;
      _hapticService.light();
      notifyListeners();
    }
  }

  /// DRY Helper: Consistently evaluates if an affix matches the target word.
  bool _isAffixMatch(String option, String correctWord) {
    final cleanOption = option.replaceAll('-', '').trim().toLowerCase();
    
    if (option.endsWith('-')) {
      // Prefix (e.g., UN-)
      return correctWord.startsWith(cleanOption);
    } else if (option.startsWith('-')) {
      // Suffix (e.g., -NESS)
      return correctWord.endsWith(cleanOption);
    }
    
    return correctWord.contains(cleanOption);
  }

  void _submitAffix(String option, VocabularyQuest quest) {
    final correctWord = quest.correctAnswer?.toLowerCase() ?? "";
    final isCorrectAns = _isAffixMatch(option, correctWord);

    if (isCorrectAns) {
      _soundService.playCorrect();
      _hapticService.success();
      
      // Wait a moment for the user to register the success, then transition!
      Future.delayed(const Duration(milliseconds: 600), () {
        isFirstStagePassed = true;
        notifyListeners();
      });
    } else {
      _soundService.playWrong();
      _hapticService.error();
      isAnswered = true;
      isCorrect = false;
      notifyListeners();
      onSubmitAnswer(false);
    }
  }

  void submitFinalAnswer(bool nailedIt, VocabularyQuest? quest, {String? wrongWord}) {
    if (isAnswered) return;

    isAnswered = true;
    isCorrect = nailedIt;
    notifyListeners();

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      
      final correctWord = quest?.correctAnswer ?? "";
      if (correctWord.isNotEmpty) {
        _ttsService.speak(correctWord);
      }

      onSubmitAnswer(true);
    } else {
      _hapticService.error();
      _soundService.playWrong();
      onSubmitAnswer(false);
    }
  }

  void onHint(VocabularyQuest? quest, bool isCompact) {
    final options = quest?.options ?? [];
    final correctWord = quest?.correctAnswer?.toLowerCase() ?? "";
    
    if (correctWord.isNotEmpty) {
      _ttsService.speak(correctWord);
    }

    if (isFirstStagePassed) {
      // If already on the spelling stage, the audio hint is enough.
      return;
    }

    if (lastConstraints == null) return;

    // Find the correct option using the DRY helper
    for (int i = 0; i < options.length; i++) {
      final option = options[i];
      
      if (_isAffixMatch(option, correctWord)) {
        dragOffset = getTerminalPosition(
          i,
          options.length,
          lastConstraints!,
          isCompact,
        ) * 0.4;
        notifyListeners();
        
        Future.delayed(const Duration(seconds: 1), () {
          if (!isAnswered) {
            dragOffset = Offset.zero;
            notifyListeners();
          }
        });
        break;
      }
    }
  }

  Offset getTerminalPosition(
    int index,
    int total,
    BoxConstraints constraints,
    bool isCompact,
  ) {
    final double safeMaxWidth = constraints.maxWidth;
    final double safeMaxHeight = constraints.maxHeight;

    // Dynamic Responsive Positioning (Diamond/Corner Grid)
    double hDist = (safeMaxWidth - 120) / 2;
    double vDist = (safeMaxHeight - (isCompact ? 130 : 180)) / 2;

    // Use a smaller radius if the screen is tiny
    hDist = hDist.clamp(isCompact ? 60.0 : 80.0, 140.0);
    vDist = vDist.clamp(isCompact ? 70.0 : 100.0, 160.0);

    switch (index) {
      case 0:
        return Offset(-hDist, -vDist); // Top Left
      case 1:
        return Offset(hDist, -vDist); // Top Right
      case 2:
        return Offset(-hDist, vDist); // Bottom Left
      case 3:
        return Offset(hDist, vDist); // Bottom Right
      default:
        double angle = (index * (2 * math.pi / total)) - (math.pi / 2);
        return Offset(math.cos(angle) * hDist, math.sin(angle) * vDist);
    }
  }
}
