import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

/// Model for a Parts of Speech practice exercise.
class PartsOfSpeechPracticeQuest {
  final String id;
  final int level;
  final String targetPartOfSpeech;
  final String instruction;
  final String sentence;
  final String targetWord;
  final List<String> words;
  final List<String> options;
  final String correctAnswer;
  final String hint;
  final String explanation;

  const PartsOfSpeechPracticeQuest({
    required this.id,
    required this.level,
    required this.targetPartOfSpeech,
    required this.instruction,
    required this.sentence,
    required this.targetWord,
    required this.words,
    required this.options,
    required this.correctAnswer,
    required this.hint,
    required this.explanation,
  });

  factory PartsOfSpeechPracticeQuest.fromJson(Map<String, dynamic> json) {
    return PartsOfSpeechPracticeQuest(
      id: json['id'] as String? ?? 'pos_practice_default',
      level: json['level'] as int? ?? 1,
      targetPartOfSpeech: json['targetPartOfSpeech'] as String? ?? 'Noun',
      instruction: json['instruction'] as String? ?? 'Identify the part of speech',
      sentence: json['sentence'] as String? ?? '',
      targetWord: json['targetWord'] as String? ?? '',
      words: (json['words'] as List<dynamic>? ?? []).cast<String>(),
      options: (json['options'] as List<dynamic>? ?? []).cast<String>(),
      correctAnswer: json['correctAnswer'] as String? ?? '',
      hint: json['hint'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );
  }
}

/// Interactive Practice Phase screen for Parts of Speech: "Target Tapping Gym".
///
/// Gives guided practice where learners tap the target word fulfilling
/// the requested grammatical role with instant scaffolding and feedback.
class PartsOfSpeechPracticeScreen extends StatefulWidget {
  final int level;

  const PartsOfSpeechPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<PartsOfSpeechPracticeScreen> createState() =>
      _PartsOfSpeechPracticeScreenState();
}

class _PartsOfSpeechPracticeScreenState
    extends State<PartsOfSpeechPracticeScreen> {
  List<PartsOfSpeechPracticeQuest> _quests = const [
    PartsOfSpeechPracticeQuest(
      id: 'FALLBACK_PRAC_1',
      level: 1,
      targetPartOfSpeech: 'Noun',
      instruction: 'Find the Noun in this sentence',
      sentence: 'Grandma Rose is baking cookies in the kitchen right now.',
      targetWord: 'kitchen',
      words: [
        'Grandma',
        'Rose',
        'is',
        'baking',
        'cookies',
        'in',
        'the',
        'kitchen',
        'right',
        'now'
      ],
      options: ['Noun', 'Verb', 'Adjective', 'Adverb'],
      correctAnswer: 'Noun',
      hint: 'Look for the room or physical location where the baking takes place.',
      explanation:
          "Correct! 'Kitchen' is a noun because it names a physical location.",
    ),
    PartsOfSpeechPracticeQuest(
      id: 'FALLBACK_PRAC_2',
      level: 1,
      targetPartOfSpeech: 'Verb',
      instruction: 'Find the Action Verb in this sentence',
      sentence: 'The referee whistled sharply to stop the game.',
      targetWord: 'whistled',
      words: [
        'The',
        'referee',
        'whistled',
        'sharply',
        'to',
        'stop',
        'the',
        'game'
      ],
      options: ['Noun', 'Adverb', 'Adjective', 'Verb'],
      correctAnswer: 'Verb',
      hint: 'What did the referee DO to stop the game?',
      explanation:
          "Correct! 'Whistled' is a verb describing the completed action.",
    ),
    PartsOfSpeechPracticeQuest(
      id: 'FALLBACK_PRAC_3',
      level: 1,
      targetPartOfSpeech: 'Adjective',
      instruction: 'Find the Temperature Adjective in this sentence',
      sentence: 'The lake felt icy cold after the autumn rain.',
      targetWord: 'cold',
      words: [
        'The',
        'lake',
        'felt',
        'icy',
        'cold',
        'after',
        'the',
        'autumn',
        'rain'
      ],
      options: ['Verb', 'Noun', 'Adverb', 'Adjective'],
      correctAnswer: 'Adjective',
      hint: 'What word describes the lake temperature following the verb felt?',
      explanation:
          "Correct! 'Cold' is an adjective modifying the lake.",
    ),
  ];

  int _currentIndex = 0;
  String? _selectedWord;
  bool? _isCorrect;
  bool _showHint = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  Future<void> _loadQuests() async {
    try {
      final startLevel = ((widget.level - 1) ~/ 10) * 10 + 1;
      final endLevel = startLevel + 9;
      final batchFile =
          'assets/curriculum/grammar/partsOfSpeech_practice_${startLevel}_$endLevel.json';

      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests = data['quests'] as List<dynamic>? ?? [];

      final loaded = rawQuests
          .map((q) => PartsOfSpeechPracticeQuest.fromJson(
              Map<String, dynamic>.from(q as Map)))
          .where((q) => q.level == widget.level)
          .toList();

      if (loaded.isNotEmpty && mounted) {
        setState(() {
          _quests = loaded;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {
      // Gracefully fall back to pre-seeded static quests
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onWordTapped(String word) {
    if (_isCorrect == true) return;

    final quest = _quests[_currentIndex];
    final cleanWord =
        word.replaceAll(RegExp(r'[.,!?;:"()]'), '').trim().toLowerCase();
    final cleanTarget = quest.targetWord.trim().toLowerCase();

    final isMatch = cleanWord == cleanTarget;

    try {
      if (di.sl.isRegistered<HapticService>()) {
        if (isMatch) {
          di.sl<HapticService>().selection();
        } else {
          di.sl<HapticService>().light();
        }
      }
    } catch (_) {}

    setState(() {
      _selectedWord = word;
      _isCorrect = isMatch;
    });
  }

  void _onNext() {
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedWord = null;
        _isCorrect = null;
        _showHint = false;
      });
    } else {
      _onComplete();
    }
  }

  void _onComplete() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'partsOfSpeech',
      level: widget.level,
      phase: 'practice',
    );
    final targetMastery =
        '/game?category=grammar&gameType=partsOfSpeech&level=${widget.level}';
    context.pushReplacement(targetMastery);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.violet500),
        ),
      );
    }

    final quest = _quests[_currentIndex];

    return PracticePhaseScaffold(
      title: 'Target Tapping Gym',
      gameType: 'partsOfSpeech',
      level: widget.level,
      currentExerciseIndex: _currentIndex,
      totalExercises: _quests.length,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'NEXT EXERCISE'
          : 'READY FOR MASTERY →',
      isActionEnabled: _isCorrect == true,
      onHint: () => setState(() => _showHint = true),
      isHintAvailable: !_showHint && _isCorrect != true,
      onComplete: () {
        if (_currentIndex < _quests.length - 1) {
          _onNext();
        } else {
          _onComplete();
        }
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Step progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppColors.violet500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.violet500.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  quest.targetPartOfSpeech.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.violet500,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Text(
                'Exercise ${_currentIndex + 1} of ${_quests.length}',
                style: TextStyle(
                  color: AppColors.slate400,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Instruction banner
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: AppColors.slate900,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.slate800),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  color: AppColors.violet500,
                  size: 22.r,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    quest.instruction,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // Interactive Tappable Word Arena
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: AppColors.slate900.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: _isCorrect == true
                    ? AppColors.emerald500.withValues(alpha: 0.5)
                    : (_isCorrect == false
                        ? AppColors.rose500.withValues(alpha: 0.5)
                        : AppColors.slate800),
                width: 1.5,
              ),
            ),
            child: Wrap(
              spacing: 8.w,
              runSpacing: 10.h,
              alignment: WrapAlignment.center,
              children: (quest.words.isNotEmpty
                      ? quest.words
                      : quest.sentence.split(' '))
                  .map((word) {
                final cleanWord = word
                    .replaceAll(RegExp(r'[.,!?;:"()]'), '')
                    .trim()
                    .toLowerCase();
                final cleanTarget = quest.targetWord.trim().toLowerCase();
                final isThisSelected = _selectedWord == word;
                final isThisTarget = cleanWord == cleanTarget;

                Color chipBg = AppColors.slate800;
                Color chipBorder = AppColors.slate700;
                Color chipText = Colors.white;

                if (isThisSelected) {
                  if (_isCorrect == true) {
                    chipBg = AppColors.emerald500.withValues(alpha: 0.25);
                    chipBorder = AppColors.emerald500;
                    chipText = AppColors.emerald400;
                  } else if (_isCorrect == false) {
                    chipBg = AppColors.rose500.withValues(alpha: 0.25);
                    chipBorder = AppColors.rose500;
                    chipText = AppColors.rose500;
                  }
                } else if (_isCorrect == true && isThisTarget) {
                  chipBg = AppColors.emerald500.withValues(alpha: 0.25);
                  chipBorder = AppColors.emerald500;
                  chipText = AppColors.emerald400;
                }

                return GestureDetector(
                  onTap: () => _onWordTapped(word),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: chipBorder, width: 1.2),
                    ),
                    child: Text(
                      word,
                      style: TextStyle(
                        color: chipText,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 16.h),

          // Feedback or Hint Section
          if (_isCorrect == true)
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.emerald500.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.emerald400,
                    size: 20.r,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      quest.explanation,
                      style: TextStyle(
                        color: AppColors.emerald400,
                        fontSize: 13.sp,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (_isCorrect == false)
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.rose500.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.rose500.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cancel_rounded,
                    color: AppColors.rose500,
                    size: 20.r,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Not quite. Try tapping another word!',
                      style: TextStyle(
                        color: AppColors.rose500,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_showHint) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.amber500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.amber500.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Text('💡', style: TextStyle(fontSize: 16.sp)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      quest.hint,
                      style: TextStyle(
                        color: AppColors.amber400,
                        fontSize: 12.sp,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 16.h),
        ],
      ),
    ),
  );
}
}
