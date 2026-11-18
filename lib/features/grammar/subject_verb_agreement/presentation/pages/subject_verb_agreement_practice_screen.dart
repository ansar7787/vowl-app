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

/// Data model representing a subject-verb agreement practice exercise.
class SubjectVerbAgreementPracticeQuest {
  final String id;
  final int level;
  final String instruction;
  final String question;
  final String sentenceWithBlank;
  final List<String> options;
  final String correctAnswer;
  final int correctAnswerIndex;
  final String hint;
  final String explanation;
  final String grammarRule;
  final String subjectType;

  const SubjectVerbAgreementPracticeQuest({
    required this.id,
    required this.level,
    required this.instruction,
    required this.question,
    required this.sentenceWithBlank,
    required this.options,
    required this.correctAnswer,
    required this.correctAnswerIndex,
    required this.hint,
    required this.explanation,
    required this.grammarRule,
    required this.subjectType,
  });

  factory SubjectVerbAgreementPracticeQuest.fromJson(Map<String, dynamic> json) {
    final sentenceWithBlank = json['sentenceWithBlank'] as String? ??
        (json['question'] as String? ?? '');
    final subjectType = json['subjectType'] as String? ?? 'Singular';
    final rule = json['grammarRule'] as String? ?? '$subjectType Agreement';

    return SubjectVerbAgreementPracticeQuest(
      id: json['id'] as String? ?? 'sva_practice_default',
      level: json['level'] as int? ?? 1,
      instruction: json['instruction'] as String? ??
          'Select the verb that agrees with the subject.',
      question: sentenceWithBlank,
      sentenceWithBlank: sentenceWithBlank,
      options: (json['options'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      correctAnswer: json['correctAnswer'] as String? ?? '',
      correctAnswerIndex: json['correctAnswerIndex'] as int? ?? 0,
      hint: json['hint'] as String? ??
          'Determine if the subject is singular or plural.',
      explanation: json['explanation'] as String? ??
          'Ensure the verb form aligns grammatically with the subject.',
      grammarRule: rule,
      subjectType: subjectType,
    );
  }
}

/// Interactive Practice Phase screen for Subject-Verb Agreement: "The Scale Balancer Gym".
///
/// Features target sentence completion, terminal verb selection, dynamic live sentence
/// synthesis, immediate auditory & haptic feedback, and grammatical explanation.
class SubjectVerbAgreementPracticeScreen extends StatefulWidget {
  final int level;

  const SubjectVerbAgreementPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<SubjectVerbAgreementPracticeScreen> createState() =>
      _SubjectVerbAgreementPracticeScreenState();
}

class _SubjectVerbAgreementPracticeScreenState
    extends State<SubjectVerbAgreementPracticeScreen> {
  List<SubjectVerbAgreementPracticeQuest> _quests = const [
    SubjectVerbAgreementPracticeQuest(
      id: 'FALLBACK_SVA_P1',
      level: 1,
      instruction: 'Select the verb that agrees with the subject.',
      question: 'The bakery ___ fresh croissants at dawn.',
      sentenceWithBlank: 'The bakery ___ fresh croissants at dawn.',
      options: ['bake', 'bakes'],
      correctAnswer: 'bakes',
      correctAnswerIndex: 1,
      hint:
          'Find the one thing performing the action here, then decide if it needs the -s ending.',
      explanation:
          "'The bakery' names one single business, so it counts as a third-person singular subject. In the simple present, singular subjects take a verb ending in -s or -es, which is why 'bakes' is correct here.",
      grammarRule: 'Third-person singular subject in the simple present',
      subjectType: 'Singular',
    ),
    SubjectVerbAgreementPracticeQuest(
      id: 'FALLBACK_SVA_P2',
      level: 1,
      instruction: 'Select the verb that agrees with the subject.',
      question: 'My neighbor ___ his lawn every Saturday.',
      sentenceWithBlank: 'My neighbor ___ his lawn every Saturday.',
      options: ['mows', 'mow'],
      correctAnswer: 'mows',
      correctAnswerIndex: 0,
      hint:
          'Ask yourself how many neighbors are doing the action before choosing the verb form.',
      explanation:
          "'My neighbor' refers to one person, so the sentence needs the singular verb form. 'Mows' carries the -s ending that marks agreement with a singular, third-person subject.",
      grammarRule: 'Third-person singular subject in the simple present',
      subjectType: 'Singular',
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
          'assets/curriculum/grammar/subjectVerbAgreement_practice_${startLevel}_$endLevel.json';

      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests = data['quests'] as List<dynamic>? ?? [];

      final loaded = rawQuests
          .map((q) => SubjectVerbAgreementPracticeQuest.fromJson(
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

  void _onOptionSelected(String option) {
    if (_selectedOption != null) return; // Answer locked once chosen

    final quest = _quests[_currentIndex];
    final isCorrect =
        option.toLowerCase() == quest.correctAnswer.toLowerCase();

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
      gameType: 'subjectVerbAgreement',
      level: widget.level,
      phase: 'practice',
    );

    final targetTest =
        '/game?category=grammar&gameType=subjectVerbAgreement&level=${widget.level}';
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

  String _getDisplaySentence(SubjectVerbAgreementPracticeQuest quest) {
    if (_selectedOption != null) {
      return quest.sentenceWithBlank.replaceFirst('___', _selectedOption!);
    }
    return quest.sentenceWithBlank;
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
      title: 'SCALE BALANCER GYM',
      gameType: 'subjectVerbAgreement',
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
                        Text('⚖️', style: TextStyle(fontSize: 14.sp)),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            quest.grammarRule.toUpperCase(),
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
                    Icons.balance_rounded,
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
                              Icons.menu_book_rounded,
                              color: AppColors.teal500,
                              size: 16.r,
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                hasAnswered
                                    ? 'COMPLETED SENTENCE'
                                    : 'SENTENCE WITH BLANK',
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

            // Verb Selection Terminals
            Text(
              'WHICH VERB BALANCES THE SUBJECT?',
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
                    option.toLowerCase() == quest.correctAnswer.toLowerCase();

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
                            Icon(
                              Icons.tune_rounded,
                              color: textColor,
                              size: 20.r,
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              option.toUpperCase(),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14.sp,
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
                                ? 'PERFECT BALANCE!'
                                : 'SCALE TIPPED: CORRECT VERB IS ${quest.correctAnswer.toUpperCase()}',
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
