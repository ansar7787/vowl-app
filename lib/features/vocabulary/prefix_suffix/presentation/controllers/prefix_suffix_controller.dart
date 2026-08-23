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

  bool _isDisposed = false;

  bool isAnswered = false;
  bool? isCorrect;
  bool showConfetti = false;
  bool isFirstStagePassed = false;
  String? selectedAffix;
  String? hintedAffix;
  
  int lastProcessedIndex = -1;
  VocabularyQuest? lastQuest;

  PrefixSuffixController({
    required HapticService hapticService,
    required SoundService soundService,
    required TtsService ttsService,
    required this.onSubmitAnswer,
  })  : _hapticService = hapticService,
        _soundService = soundService,
        _ttsService = ttsService;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void reset(VocabularyQuest? quest, int index) {
    lastQuest = quest;
    lastProcessedIndex = index;
    isAnswered = false;
    isCorrect = null;
    isFirstStagePassed = false;
    selectedAffix = null;
    hintedAffix = null;
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


  void onAffixSelected(String option, VocabularyQuest quest, bool droppedAsPrefix) {
    if (isAnswered || isFirstStagePassed) return;
    
    // Check if they dropped a prefix in a suffix slot or vice versa
    bool isOptionPrefix = option.endsWith('-');
    bool isOptionSuffix = option.startsWith('-');
    
    // Fallback: If the JSON curriculum missed the hyphens, infer from the correct answer
    if (!isOptionPrefix && !isOptionSuffix) {
      final cleanOption = option.trim().toLowerCase();
      final correctWord = quest.correctAnswer?.toLowerCase() ?? "";
      if (correctWord.startsWith(cleanOption) && correctWord != cleanOption) {
        isOptionPrefix = true;
      } else if (correctWord.endsWith(cleanOption) && correctWord != cleanOption) {
        isOptionSuffix = true;
      }
    }
    
    if ((isOptionPrefix && !droppedAsPrefix) || (isOptionSuffix && droppedAsPrefix)) {
      // Wrong slot!
      _soundService.playWrong();
      _hapticService.error();
      // We don't fail the whole game, just reject the drop.
      return;
    }

    selectedAffix = option;
    notifyListeners();

    _submitAffix(option, quest);
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
      Future.delayed(const Duration(milliseconds: 250), () {
        if (_isDisposed) return;
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
      _soundService.playCorrect();
      _hapticService.success();
      
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

  void onHint(VocabularyQuest? quest) {
    final options = quest?.options ?? [];
    final correctWord = quest?.correctAnswer?.toLowerCase() ?? "";
    
    if (correctWord.isNotEmpty) {
      _ttsService.speak(correctWord);
    }

    if (isFirstStagePassed) {
      // If already on the spelling stage, the audio hint is enough.
      return;
    }

    // Find the correct option using the DRY helper
    for (int i = 0; i < options.length; i++) {
      final option = options[i];
      if (_isAffixMatch(option, correctWord)) {
        hintedAffix = option;
        notifyListeners();
        
        _hapticService.light();
        
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (_isDisposed) return;
          if (!isAnswered) {
            hintedAffix = null;
            notifyListeners();
          }
        });
        break;
      }
    }
  }


}
