import 'package:flutter/material.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

class TopicVocabController extends ChangeNotifier {
  final HapticService _hapticService;
  final SoundService _soundService;
  final void Function(bool) onSubmitAnswer;

  int currentWordIndex = 0;
  bool isAnswered = false;
  bool? isCorrect;
  bool showConfetti = false;
  bool isFirstStagePassed = false;
  bool isHintActive = false;

  List<String> shuffledOptions = [];
  final List<Map<String, String>> userChoices = [];
  final Map<int, List<String>> wordsInBins = {0: [], 1: []};

  String? flickedWord;
  int? flickTarget;

  VocabularyQuest? currentQuest;
  String? currentHint;

  TopicVocabController({
    required HapticService hapticService,
    required SoundService soundService,
    required this.onSubmitAnswer,
  }) : _hapticService = hapticService,
       _soundService = soundService;

  void reset(VocabularyQuest? quest) {
    currentQuest = quest;
    isAnswered = false;
    isCorrect = null;
    isFirstStagePassed = false;
    currentWordIndex = 0;
    isHintActive = false;
    userChoices.clear();
    wordsInBins.forEach((_, list) => list.clear());
    shuffledOptions = List<String>.from(quest?.options ?? [])..shuffle();
    _computeHint();
    notifyListeners();
  }

  void _computeHint() {
    if (currentQuest == null || currentQuest?.relatedWords == null) {
      currentHint = null;
      return;
    }
    final currentWord = currentWordIndex < shuffledOptions.length
        ? shuffledOptions[currentWordIndex]
        : "";
    if (currentWord.isEmpty) {
      currentHint = null;
      return;
    }
    final cleanCurrentWord = currentWord.trim().toLowerCase();
    for (var related in currentQuest!.relatedWords!) {
      final separatorIndex = related.indexOf(RegExp(r'[:\-]'));
      if (separatorIndex != -1) {
        final prefix = related
            .substring(0, separatorIndex)
            .trim()
            .toLowerCase();
        if (prefix == cleanCurrentWord) {
          final definitionText = related.substring(separatorIndex + 1).trim();
          currentHint = "Definition: $definitionText";
          return;
        }
      }
    }
    currentHint = null;
  }

  void activateHint() {
    isHintActive = true;
    notifyListeners();
  }

  void completeGame() {
    showConfetti = true;
    notifyListeners();
  }

  void handleFlick(
    double velocity,
    String word,
    List<String> buckets,
    String correctAnswer,
  ) {
    if (isAnswered || flickedWord != null) return;

    int targetBin = velocity < 0 ? 0 : 1;
    String bucketName = buckets[targetBin % buckets.length];
    bool isCorrectChoice = _validateChoice(word, bucketName, correctAnswer);

    flickedWord = word;
    flickTarget = targetBin;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 250), () {
      flickedWord = null;
      flickTarget = null;

      if (!isCorrectChoice) {
        _submitFinalAnswer(false);
        return;
      }

      userChoices.add({'word': word, 'bucket': bucketName});
      wordsInBins[targetBin]?.add(word);
      isHintActive = false;
      _soundService.playCorrect();

      final maxWords = (buckets.length * 2 + 1).clamp(3, 5);
      if (currentWordIndex < maxWords - 1) {
        currentWordIndex++;
        _computeHint();
      } else {
        _hapticService.success();
        isFirstStagePassed = true;
        _submitFinalAnswer(true);
      }
      notifyListeners();
    });
  }

  void _submitFinalAnswer(bool nailedIt) {
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

  bool _validateChoice(String word, String bucket, String correctAnswer) {
    final cleanWord = word.trim().toLowerCase();
    final cleanLabel = bucket.trim().toLowerCase();

    final pairs = correctAnswer.split(',');
    for (var pair in pairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        final targetBucket = parts[0].trim().toLowerCase();
        final targetWord = parts[1].trim().toLowerCase();
        if (targetWord == cleanWord) {
          return targetBucket == cleanLabel;
        }
      }
    }
    return false;
  }
}
