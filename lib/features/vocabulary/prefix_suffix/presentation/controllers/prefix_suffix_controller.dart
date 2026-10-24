import 'dart:async';
import 'package:flutter/material.dart';

import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

import 'package:vowl/core/domain/entities/game_quest.dart';

/// Controller managing interactive state, affix snapping, and spelling validation for prefix/suffix synthesis.
class PrefixSuffixController extends ChangeNotifier {
  final HapticService _hapticService;
  final SoundService _soundService;
  final TtsService _ttsService;

  /// Callback dispatched to report answer correctness to the parent screen.
  final void Function(bool isCorrect, {GameQuest? quest, String? userAnswer})
  onSubmitAnswer;

  bool _isDisposed = false;
  Timer? _stageTimer;
  Timer? _hintTimer;

  /// Whether the user has answered the trial.
  bool isAnswered = false;

  /// Whether the submitted response was correct, or `null` if pending.
  bool? isCorrect;

  /// Whether celebratory confetti is currently active.
  bool showConfetti = false;

  /// Whether stage 1 (affix attachment) has been completed.
  bool isFirstStagePassed = false;

  /// Currently selected affix candidate string.
  String? selectedAffix;

  /// Currently illuminated affix string from hint activation.
  String? hintedAffix;

  /// Quest index of the last evaluated question.
  int lastProcessedIndex = -1;

  /// The active vocabulary quest item.
  VocabularyQuest? lastQuest;

  /// Creates a [PrefixSuffixController] with required audio, haptic, and submission services.
  PrefixSuffixController({
    required HapticService hapticService,
    required SoundService soundService,
    required TtsService ttsService,
    required this.onSubmitAnswer,
  }) : _hapticService = hapticService,
       _soundService = soundService,
       _ttsService = ttsService;

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stageTimer?.cancel();
    _hintTimer?.cancel();
    super.dispose();
  }

  /// Resets controller state for a new quest or retry attempt.
  void reset(VocabularyQuest? quest, int index) {
    if (_isDisposed) return;
    _stageTimer?.cancel();
    _hintTimer?.cancel();
    lastQuest = quest;
    lastProcessedIndex = index;
    isAnswered = false;
    isCorrect = null;
    isFirstStagePassed = false;
    selectedAffix = null;
    hintedAffix = null;
    notifyListeners();
  }

  /// Explicitly marks the question answered status.
  void setAnswered(bool correct) {
    if (_isDisposed) return;
    isAnswered = true;
    isCorrect = correct;
    notifyListeners();
  }

  /// Activates the game complete confetti sequence.
  void completeGame() {
    if (showConfetti || _isDisposed) return;
    showConfetti = true;
    notifyListeners();
  }

  /// Resolves the full target English word for a given prefix/suffix quest.
  String getTargetWord(VocabularyQuest? quest) {
    if (quest == null) return "";

    final correct = quest.correctAnswer?.trim() ?? "";
    final root = quest.rootWord?.trim() ?? "";

    final bool isAffix = correct.startsWith('-') || correct.endsWith('-');
    final cleanCorrect = correct.replaceAll('-', '').trim();

    // 1. If correctAnswer is already a full word (doesn't start/end with hyphen, length > 2)
    if (!isAffix && correct.isNotEmpty) {
      if (root.isEmpty || cleanCorrect.toLowerCase() != root.toLowerCase()) {
        return cleanCorrect;
      }
    }

    // If quest has a valid full word specified in quest.word
    if (quest.word != null &&
        quest.word!.isNotEmpty &&
        !quest.word!.contains('-') &&
        quest.word!.toLowerCase() != root.toLowerCase()) {
      final w = quest.word!.trim().toUpperCase();
      final upperRoot = root.toUpperCase();
      final upperAffix = cleanCorrect.toUpperCase();
      if (upperRoot.isEmpty ||
          w.contains(upperRoot) ||
          upperRoot.contains(w) ||
          w.startsWith(upperAffix) ||
          w.endsWith(upperAffix)) {
        return quest.word!.trim();
      }
    }

    // 2. Try to extract target word from explanation
    final expl = quest.explanation ?? "";
    if (expl.isNotEmpty) {
      // Pattern 1: "= WORD"
      final equalsMatch = RegExp(r'=\s*([A-Za-z]{3,})').firstMatch(expl);
      if (equalsMatch != null) {
        return equalsMatch.group(1)!.trim();
      }

      // Pattern 2: "forms WORD" / "creates WORD" / "produces WORD" / "to form WORD"
      final formsMatch = RegExp(
        r'(?:forms|creates|produces|to\s+form)\s+([A-Za-z]{3,})',
        caseSensitive: false,
      ).firstMatch(expl);
      if (formsMatch != null) {
        return formsMatch.group(1)!.trim();
      }

      // Pattern 3: "WORD is built" / "WORD combines" / "WORD layers" / "WORD means" / "WORD reverses"
      final startMatch = RegExp(
        r'^([A-Za-z]{3,})\s+(?:is built|combines|layers|means|reverses)',
        caseSensitive: false,
      ).firstMatch(expl);
      if (startMatch != null) {
        return startMatch.group(1)!.trim();
      }

      // Pattern 4: Search all uppercase words of length >= 3
      final allCaps = RegExp(r'\b[A-Z]{3,}\b')
          .allMatches(expl)
          .map((m) => m.group(0)!)
          .toList();
      final upperAffix = cleanCorrect.toUpperCase();
      final upperRoot = root.toUpperCase();
      const ignoreWords = {
        'THE', 'AND', 'NOT', 'FOR', 'THIS', 'THAT', 'WITH', 'FROM',
        'WORD', 'ROOT', 'PREFIX', 'SUFFIX', 'ADDED', 'MEANS', 'ACTION'
      };

      for (final w in allCaps) {
        if (!ignoreWords.contains(w) && w != upperAffix && w != upperRoot) {
          if (w.startsWith(upperAffix) ||
              w.endsWith(upperAffix) ||
              w.contains(upperRoot) ||
              upperRoot.contains(w)) {
            return w;
          }
        }
      }
    }

    // 3. Fallback: Combine affix and rootWord directly
    if (root.isNotEmpty) {
      if (correct.endsWith('-') || (!correct.startsWith('-') && isAffix)) {
        return '$cleanCorrect$root';
      } else {
        return '$root$cleanCorrect';
      }
    }

    return cleanCorrect.isNotEmpty ? cleanCorrect : correct;
  }

  /// Handles selection or drop of candidate [option] into affix slots.
  void onAffixSelected(
    String option,
    VocabularyQuest quest,
    bool? droppedAsPrefix,
  ) {
    if (isAnswered || isFirstStagePassed || selectedAffix != null) return;

    // Check if they dropped a prefix in a suffix slot or vice versa
    bool isOptionPrefix = option.endsWith('-');
    bool isOptionSuffix = option.startsWith('-');

    // Fallback: If the JSON curriculum missed the hyphens, infer from the target word
    if (!isOptionPrefix && !isOptionSuffix) {
      final cleanOption = option.trim().toLowerCase();
      final targetWord = getTargetWord(quest).toLowerCase();
      if (targetWord.startsWith(cleanOption) && targetWord != cleanOption) {
        isOptionPrefix = true;
      } else if (targetWord.endsWith(cleanOption) &&
          targetWord != cleanOption) {
        isOptionSuffix = true;
      }
    }

    if (droppedAsPrefix != null) {
      if ((isOptionPrefix && !droppedAsPrefix) ||
          (isOptionSuffix && droppedAsPrefix)) {
        // Wrong slot!
        _soundService.playWrong();
        _hapticService.error();
        // We don't fail the whole game, just reject the drop.
        return;
      }
    }

    selectedAffix = option;
    notifyListeners();

    _submitAffix(option, quest);
  }

  String? _findCorrectOption(VocabularyQuest quest) {
    final correctWord = quest.correctAnswer?.toLowerCase() ?? "";
    final rootWord = quest.rootWord?.toLowerCase() ?? "";
    final options = quest.options ?? [];

    // Direct match check (e.g. if options contains "RE-" and correctAnswer is "RE-")
    for (final option in options) {
      if (option.trim().toLowerCase() == correctWord.trim().toLowerCase()) {
        return option;
      }
    }

    final targetWord = getTargetWord(quest).toLowerCase();

    // First pass: exact remainder match
    for (final option in options) {
      final clean = option.replaceAll('-', '').trim().toLowerCase();
      bool isPrefix = option.endsWith('-');
      bool isSuffix = option.startsWith('-');

      if (!isPrefix && !isSuffix) {
        if (targetWord.startsWith(clean) && targetWord != clean) {
          isPrefix = true;
        } else if (targetWord.endsWith(clean) && targetWord != clean) {
          isSuffix = true;
        }
      }

      if (isPrefix && targetWord.startsWith(clean)) {
        final remainder = targetWord.substring(clean.length);
        if (remainder == rootWord) return option;
      } else if (isSuffix && targetWord.endsWith(clean)) {
        final remainder = targetWord.substring(
          0,
          targetWord.length - clean.length,
        );
        if (remainder == rootWord) return option;
      }
    }

    // Second pass: handle spelling changes by scoring common prefix length
    String? bestOption;
    int bestScore = -1;

    for (final option in options) {
      final clean = option.replaceAll('-', '').trim().toLowerCase();
      bool isPrefix = option.endsWith('-');
      bool isSuffix = option.startsWith('-');

      if (!isPrefix && !isSuffix) {
        if (targetWord.startsWith(clean) && targetWord != clean) {
          isPrefix = true;
        } else if (targetWord.endsWith(clean) && targetWord != clean) {
          isSuffix = true;
        }
      }

      String remainder = "";

      if (isPrefix && targetWord.startsWith(clean)) {
        remainder = targetWord.substring(clean.length);
      } else if (isSuffix && targetWord.endsWith(clean)) {
        remainder = targetWord.substring(0, targetWord.length - clean.length);
      } else {
        continue;
      }

      int score = 0;
      int minLength = remainder.length < rootWord.length
          ? remainder.length
          : rootWord.length;
      for (int i = 0; i < minLength; i++) {
        if (remainder[i] == rootWord[i]) {
          score++;
        } else {
          break;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestOption = option;
      }
    }

    return bestOption;
  }

  void _submitAffix(String option, VocabularyQuest quest) {
    final correctOption = _findCorrectOption(quest);
    final isCorrectAns = (correctOption != null && option == correctOption);

    if (isCorrectAns) {
      _soundService.playCorrect();
      _hapticService.success();

      // Wait a moment for the user to register the success, then transition!
      _stageTimer?.cancel();
      _stageTimer = Timer(const Duration(milliseconds: 250), () {
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
      onSubmitAnswer(false, quest: quest, userAnswer: option);
    }
  }

  /// Submits the final stage evaluation result.
  void submitFinalAnswer(
    bool nailedIt,
    VocabularyQuest? quest, {
    String? wrongWord,
  }) {
    if (isAnswered) return;

    isAnswered = true;
    isCorrect = nailedIt;
    notifyListeners();

    if (nailedIt) {
      _soundService.playCorrect();
      _hapticService.success();

      final correctWord = getTargetWord(quest);
      if (correctWord.isNotEmpty) {
        _ttsService.speak(correctWord);
      }

      onSubmitAnswer(true);
    } else {
      _hapticService.error();
      _soundService.playWrong();
      onSubmitAnswer(false, quest: quest, userAnswer: wrongWord);
    }
  }

  /// Triggers an audio and visual hint highlighting the correct affix option.
  void onHint(VocabularyQuest? quest) {
    if (quest == null) return;
    final targetWord = getTargetWord(quest).toLowerCase();

    if (targetWord.isNotEmpty) {
      _ttsService.speak(targetWord);
    }

    if (isFirstStagePassed) {
      // If already on the spelling stage, the audio hint is enough.
      return;
    }

    final correctOption = _findCorrectOption(quest);

    if (correctOption != null) {
      hintedAffix = correctOption;
      notifyListeners();

      _hapticService.light();

      _hintTimer?.cancel();
      _hintTimer = Timer(const Duration(milliseconds: 1500), () {
        if (_isDisposed) return;
        if (!isAnswered) {
          hintedAffix = null;
          notifyListeners();
        }
      });
    }
  }
}
