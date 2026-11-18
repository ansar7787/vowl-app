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
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';

/// Data model representing an article insertion practice exercise.
class ArticleInsertionPracticeQuest {
  final String id;
  final int level;
  final String instruction;
  final String sentence;
  final String sentenceWithBlank;
  final List<String> options;
  final String correctAnswer;
  final int correctAnswerIndex;
  final String hint;
  final String explanation;
  final String grammarRule;
  final String articleRule;

  const ArticleInsertionPracticeQuest({
    required this.id,
    required this.level,
    required this.instruction,
    required this.sentence,
    required this.sentenceWithBlank,
    required this.options,
    required this.correctAnswer,
    required this.correctAnswerIndex,
    required this.hint,
    required this.explanation,
    required this.grammarRule,
    required this.articleRule,
  });

  factory ArticleInsertionPracticeQuest.fromJson(Map<String, dynamic> json) {
    final sentenceWithBlank = json['sentenceWithBlank'] as String? ??
        (json['sentence'] as String? ?? (json['question'] as String? ?? ''));
    final correctArt = json['correctAnswer'] as String? ?? 'a';
    final rule = json['grammarRule'] as String? ??
        (json['articleRule'] as String? ?? 'Article Placement');
    final artRule = json['articleRule'] as String? ?? 'Article: $correctArt';

    return ArticleInsertionPracticeQuest(
      id: json['id'] as String? ?? 'ai_practice_default',
      level: json['level'] as int? ?? 1,
      instruction: json['instruction'] as String? ??
          'Insert the correct article to complete the sentence.',
      sentence: sentenceWithBlank,
      sentenceWithBlank: sentenceWithBlank,
      options: (json['options'] as List<dynamic>? ?? ['a', 'an', 'the', '(no article)'])
          .map((e) => e.toString())
          .toList(),
      correctAnswer: correctArt,
      correctAnswerIndex: json['correctAnswerIndex'] as int? ?? 0,
      hint: json['hint'] as String? ??
          'Focus on the sound following the blank and specificity.',
      explanation: json['explanation'] as String? ??
          "The sentence requires '$correctArt'.",
      grammarRule: rule,
      articleRule: artRule,
    );
  }
}

/// Interactive Practice Phase screen for Article Insertion: "Article Orb Sorter Gym".
///
/// Features target sentence analysis, article orb selection (A | AN | THE | Ø),
/// live sentence completion, immediate auditory & haptic feedback, and grammatical explanation.
class ArticleInsertionPracticeScreen extends StatefulWidget {
  final int level;

  const ArticleInsertionPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<ArticleInsertionPracticeScreen> createState() =>
      _ArticleInsertionPracticeScreenState();
}

class _ArticleInsertionPracticeScreenState
    extends State<ArticleInsertionPracticeScreen> {
  List<ArticleInsertionPracticeQuest> _quests = const [
    ArticleInsertionPracticeQuest(
      id: 'FALLBACK_AI_P1',
      level: 1,
      instruction: 'Insert the correct article to complete the sentence.',
      sentence: "I need to grab ___ jacket before we head out — it's chilly.",
      sentenceWithBlank:
          "I need to grab ___ jacket before we head out — it's chilly.",
      options: ['an', 'the', 'a', '(no article)'],
      correctAnswer: 'a',
      correctAnswerIndex: 2,
      hint: "Say the first sound of 'jacket' out loud — is it a consonant?",
      explanation:
          "'Jacket' begins with a consonant sound, so it takes 'a'. We say 'a jacket', introducing it for the first time.",
      grammarRule: 'Indefinite article before a consonant sound',
      articleRule: 'Indefinite Article (a)',
    ),
    ArticleInsertionPracticeQuest(
      id: 'FALLBACK_AI_P2',
      level: 1,
      instruction: 'Insert the correct article to complete the sentence.',
      sentence: 'Can you hand me ___ envelope from that drawer?',
      sentenceWithBlank: 'Can you hand me ___ envelope from that drawer?',
      options: ['an', 'a', 'the', '(no article)'],
      correctAnswer: 'an',
      correctAnswerIndex: 0,
      hint: 'Notice the vowel sound right at the start of envelope.',
      explanation:
          "'Envelope' starts with a vowel sound, so 'an' is required. We say 'an envelope', never 'a envelope'.",
      grammarRule: 'Indefinite article before a vowel sound',
      articleRule: 'Indefinite Article (an)',
    ),
  ];

  int _currentIndex = 0;
  String? _selectedOption;
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
          'assets/curriculum/grammar/articleInsertion_practice_${startLevel}_$endLevel.json';

      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests = data['quests'] as List<dynamic>? ?? [];

      final loaded = rawQuests
          .map((q) => ArticleInsertionPracticeQuest.fromJson(
              Map<String, dynamic>.from(q as Map)))
          .where((q) => q.level == widget.level)
          .toList();

      if (mounted) {
        setState(() {
          if (loaded.isNotEmpty) {
            _quests = loaded;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _checkIsCorrect(String option, String correctAnswer) {
    final opt = option.trim().toLowerCase();
    final ans = correctAnswer.trim().toLowerCase();
    if (opt == ans) return true;
    if ((opt == '(no article)' || opt == 'ø') && (ans == '(no article)' || ans == 'ø')) {
      return true;
    }
    return false;
  }

  void _onOptionSelected(String option) {
    if (_selectedOption != null) return; // Answer locked once chosen

    final quest = _quests[_currentIndex];
    final isCorrect = _checkIsCorrect(option, quest.correctAnswer);

    setState(() {
      _selectedOption = option;
      _isCorrect = isCorrect;
    });

    try {
      if (isCorrect) {
        if (di.sl.isRegistered<HapticService>()) {
          di.sl<HapticService>().success();
        }
        if (di.sl.isRegistered<SoundService>()) {
          di.sl<SoundService>().playCorrect();
        }
      } else {
        if (di.sl.isRegistered<HapticService>()) {
          di.sl<HapticService>().error();
        }
        if (di.sl.isRegistered<SoundService>()) {
          di.sl<SoundService>().playWrong();
        }
      }
    } catch (_) {}
  }

  void _speakSentence(String text) {
    if (text.isEmpty) return;
    try {
      if (di.sl.isRegistered<TtsService>()) {
        di.sl<TtsService>().speak(text);
      }
    } catch (_) {}
  }

  void _onComplete() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'articleInsertion',
      level: widget.level,
      phase: 'practice',
    );

    final targetTest =
        '/game?category=grammar&gameType=articleInsertion&level=${widget.level}';
    context.pushReplacement(targetTest);
  }

  void _nextExercise() {
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _isCorrect = null;
        _showHint = false;
      });
    } else {
      _onComplete();
    }
  }

  String _getDisplaySentence(ArticleInsertionPracticeQuest quest) {
    if (_selectedOption != null) {
      final clean = (_selectedOption == '(no article)' || _selectedOption == 'Ø')
          ? ''
          : _selectedOption!;
      return quest.sentenceWithBlank.replaceFirst('___', clean.isNotEmpty ? '$clean ' : '').replaceAll('  ', ' ');
    }
    return quest.sentenceWithBlank;
  }

  String _getOrbLabel(String option) {
    if (option.toLowerCase() == '(no article)') return 'Ø';
    return option.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.slate950,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.teal500),
        ),
      );
    }

    final quest = _quests[_currentIndex];
    final hasAnswered = _selectedOption != null;
    final displaySentence = _getDisplaySentence(quest);

    return PracticePhaseScaffold(
      title: 'SOUND & ARTICLE GYM',
      gameType: 'articleInsertion',
      level: widget.level,
      currentExerciseIndex: _currentIndex,
      totalExercises: _quests.length,
      onComplete: _onComplete,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Rule badge & Exercise counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: AppColors.teal500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: AppColors.teal500.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🎯', style: TextStyle(fontSize: 14.sp)),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            quest.articleRule.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.teal500,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  'Exercise ${_currentIndex + 1} of ${_quests.length}',
                  style: TextStyle(
                    color: AppColors.slate500,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Instruction Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.slate800),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.radar_rounded,
                    color: AppColors.teal500,
                    size: 20.r,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      quest.instruction,
                      style: TextStyle(
                        color: AppColors.slate200,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showHint = !_showHint;
                      });
                    },
                    icon: Icon(
                      Icons.lightbulb_outline_rounded,
                      color:
                          _showHint ? AppColors.amber400 : AppColors.slate500,
                      size: 20.r,
                    ),
                    tooltip: 'Hint',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Hint Drawer (if active)
            if (_showHint) ...[
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.amber500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.amber500.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Text('💡', style: TextStyle(fontSize: 14.sp)),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        quest.hint,
                        style: TextStyle(
                          color: AppColors.amber400,
                          fontSize: 12.sp,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
            ],

            // Target Sentence with Blank
            Container(
              padding: EdgeInsets.all(18.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: hasAnswered
                      ? (_isCorrect! ? AppColors.emerald500 : AppColors.rose500)
                      : AppColors.slate800,
                  width: hasAnswered ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.format_quote_rounded,
                              color: AppColors.teal500,
                              size: 16.r,
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                hasAnswered
                                    ? 'COMPLETED SENTENCE'
                                    : 'INSERT ARTICLE',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.teal500,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _speakSentence(displaySentence),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.cyan400,
                          size: 20.r,
                        ),
                        tooltip: 'Listen to sentence',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    displaySentence,
                    style: TextStyle(
                      color: AppColors.slate100,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Article Orbs
            Text(
              'CHOOSE THE NATURAL ARTICLE:',
              style: TextStyle(
                color: AppColors.slate400,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 12.h),

            Row(
              children: quest.options.map((option) {
                final isSelected = _selectedOption == option;
                final isTargetCorrect =
                    _checkIsCorrect(option, quest.correctAnswer);

                Color borderColor = AppColors.slate800;
                Color bgColor = AppColors.slate900;
                Color textColor = AppColors.slate300;

                if (hasAnswered) {
                  if (isSelected) {
                    if (_isCorrect!) {
                      borderColor = AppColors.emerald500;
                      bgColor = AppColors.emerald500.withValues(alpha: 0.2);
                      textColor = AppColors.emerald400;
                    } else {
                      borderColor = AppColors.rose500;
                      bgColor = AppColors.rose500.withValues(alpha: 0.2);
                      textColor = AppColors.rose500;
                    }
                  } else if (isTargetCorrect) {
                    borderColor = AppColors.emerald500;
                    bgColor = AppColors.emerald500.withValues(alpha: 0.1);
                    textColor = AppColors.emerald400;
                  }
                } else if (isSelected) {
                  borderColor = AppColors.teal500;
                  bgColor = AppColors.teal500.withValues(alpha: 0.15);
                  textColor = AppColors.teal500;
                }

                final label = _getOrbLabel(option);

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: InkWell(
                      onTap: hasAnswered
                          ? null
                          : () => _onOptionSelected(option),
                      borderRadius: BorderRadius.circular(14.r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: borderColor, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 18.h),

            // Feedback Card (after answer)
            if (hasAnswered) ...[
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: _isCorrect!
                      ? AppColors.emerald500.withValues(alpha: 0.1)
                      : AppColors.rose500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: _isCorrect!
                        ? AppColors.emerald500.withValues(alpha: 0.3)
                        : AppColors.rose500.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isCorrect!
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: _isCorrect!
                              ? AppColors.emerald400
                              : AppColors.rose500,
                          size: 20.r,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _isCorrect!
                                ? 'ACOUSTIC HARMONY LOCKED IN!'
                                : 'ACOUSTIC CLASH: CORRECT ARTICLE IS ${quest.correctAnswer.toUpperCase()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _isCorrect!
                                  ? AppColors.emerald400
                                  : AppColors.rose500,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      quest.explanation,
                      style: TextStyle(
                        color: AppColors.slate300,
                        fontSize: 12.sp,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // Advance Button
              ElevatedButton(
                onPressed: _nextExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isCorrect! ? AppColors.emerald500 : AppColors.teal500,
                  foregroundColor: AppColors.slate950,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _currentIndex < _quests.length - 1
                            ? 'NEXT EXERCISE'
                            : 'START MASTERY',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(Icons.arrow_forward_rounded, size: 18.r),
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
