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
  final Map<String, String> _expectedAnswers = {};

  String? flickedWord;
  int? flickTarget;
  double? flickStartOffset;

  VocabularyQuest? currentQuest;
  bool _isDisposed = false;

  TopicVocabController({
    required HapticService hapticService,
    required SoundService soundService,
    required this.onSubmitAnswer,
  }) : _hapticService = hapticService,
       _soundService = soundService;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void reset(VocabularyQuest? quest) {
    currentQuest = quest;
    isAnswered = false;
    isCorrect = null;
    isFirstStagePassed = false;
    currentWordIndex = 0;
    isHintActive = false;
    userChoices.clear();
    wordsInBins.forEach((_, list) => list.clear());
    _expectedAnswers.clear();

    if (quest?.correctAnswer != null) {
      final pairs = quest!.correctAnswer!.split(',');
      for (var pair in pairs) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          final targetBucket = parts[0].trim().toLowerCase();
          final targetWord = parts[1].trim().toLowerCase();
          _expectedAnswers[targetWord] = targetBucket;
        }
      }
    }

    shuffledOptions = List<String>.from(quest?.options ?? [])..shuffle();
    notifyListeners();
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
    double dropOffset,
    String word,
    List<String> buckets,
  ) {
    if (isAnswered || flickedWord != null) return;

    int targetBin = velocity < 0 ? 0 : 1;
    String bucketName = buckets[targetBin % buckets.length];
    bool isCorrectChoice = _validateChoice(word, bucketName);

    flickedWord = word;
    flickTarget = targetBin;
    flickStartOffset = dropOffset;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 250), () {
      if (_isDisposed) return;

      flickedWord = null;
      flickTarget = null;
      flickStartOffset = null;

      if (!isCorrectChoice) {
        _submitFinalAnswer(false);
        return;
      }

      userChoices.add({'word': word, 'bucket': bucketName});
      wordsInBins[targetBin]?.add(word);
      isHintActive = false;
      _soundService.playCorrect();

      final idealMax = (buckets.length * 2 + 1).clamp(3, 5);
      final maxWords = shuffledOptions.isNotEmpty
          ? idealMax.clamp(1, shuffledOptions.length)
          : idealMax;

      if (currentWordIndex < maxWords - 1) {
        currentWordIndex++;
      } else {
        _hapticService.success();
        isFirstStagePassed = true;
        _submitFinalAnswer(true);
      }
      notifyListeners();
    });
  }

  void _submitFinalAnswer(bool nailedIt) {
    if (isAnswered || _isDisposed) return;
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

  bool isHintTarget(String word, String bucket) {
    if (!isHintActive) return false;
    final cleanWord = word.trim().toLowerCase();
    final cleanLabel = bucket.trim().toLowerCase();
    return _expectedAnswers[cleanWord] == cleanLabel;
  }

  bool _validateChoice(String word, String bucket) {
    final cleanWord = word.trim().toLowerCase();
    final cleanLabel = bucket.trim().toLowerCase();

    return _expectedAnswers[cleanWord] == cleanLabel;
  }
}
