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

/// Data model representing a pronoun resolution practice exercise.
class PronounResolutionPracticeQuest {
  final String id;
  final int level;
  final String instruction;
  final String question;
  final String sentence;
  final String targetPronoun;
  final List<String> options;
  final String correctAnswer;
  final int correctAnswerIndex;
  final String hint;
  final String explanation;
  final String grammarRule;
  final String referentHighlight;

  const PronounResolutionPracticeQuest({
    required this.id,
    required this.level,
    required this.instruction,
    required this.question,
    required this.sentence,
    required this.targetPronoun,
    required this.options,
    required this.correctAnswer,
    required this.correctAnswerIndex,
    required this.hint,
    required this.explanation,
    required this.grammarRule,
    required this.referentHighlight,
  });

  factory PronounResolutionPracticeQuest.fromJson(Map<String, dynamic> json) {
    final pronoun = json['targetPronoun'] as String? ??
        (json['targetWord'] as String? ?? 'it');
    final q = json['question'] as String? ??
        'Who does the pronoun point back to?';
    final sentence = json['sentence'] as String? ?? q;
    final answer = json['correctAnswer'] as String? ?? 'the noun';

    return PronounResolutionPracticeQuest(
      id: json['id'] as String? ?? 'pr_practice_default',
      level: json['level'] as int? ?? 1,
      instruction: json['instruction'] as String? ??
          'Resolve the pronoun to its correct antecedent',
      question: q,
      sentence: sentence,
      targetPronoun: pronoun,
      options: (json['options'] as List<dynamic>? ?? [answer])
          .map((e) => e.toString())
          .toList(),
      correctAnswer: answer,
      correctAnswerIndex: json['correctAnswerIndex'] as int? ?? 0,
      hint: json['hint'] as String? ??
          'Trace back through the sentence: which noun does the pronoun replace?',
      explanation: json['explanation'] as String? ??
          'Pronouns must clearly match their antecedent in number, person, and gender.',
      grammarRule: json['grammarRule'] as String? ?? 'Pronoun Reference',
      referentHighlight: json['referentHighlight'] as String? ?? 'Target Noun',
    );
  }
}

/// Interactive Practice Phase screen for Pronoun Resolution: "Clarity Fixer Gym".
///
/// Features passage display, pronoun target isolation, dynamic antecedent options,
/// auditory & haptic feedback, hint discovery, and resolution explanation.
class PronounResolutionPracticeScreen extends StatefulWidget {
  final int level;

  const PronounResolutionPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<PronounResolutionPracticeScreen> createState() =>
      _PronounResolutionPracticeScreenState();
}

class _PronounResolutionPracticeScreenState
    extends State<PronounResolutionPracticeScreen> {
  List<PronounResolutionPracticeQuest> _quests = const [
    PronounResolutionPracticeQuest(
      id: 'FALLBACK_PR_P1',
      level: 1,
      instruction: 'Resolve the pronoun to its correct antecedent',
      question:
          "Mr. Osei waited while Priya filled in the form, and then she signed it at the bottom.\nWho is 'she' pointing back to?",
      sentence:
          'Mr. Osei waited while Priya filled in the form, and then she signed it at the bottom.',
      targetPronoun: 'she',
      options: ['Mr. Osei', 'the form', 'Priya'],
      correctAnswer: 'Priya',
      correctAnswerIndex: 2,
      hint: "Only one of the people named can be a 'she'.",
      explanation:
          "The pronoun 'she' is feminine and singular, so it points to Priya. Mr. Osei is male, and a form cannot sign anything.",
      grammarRule: 'Subject Pronouns',
      referentHighlight: 'Target Noun',
    ),
  ];

  int _currentIndex = 0;
  bool _isLoading = true;
  String? _selectedOption;
  bool? _isCorrect;
  bool _showHint = false;

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
          'assets/curriculum/grammar/pronounResolution_practice_${startLevel}_$endLevel.json';

      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests = data['quests'] as List<dynamic>? ?? [];

      final loaded = rawQuests
          .map((q) => PronounResolutionPracticeQuest.fromJson(
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

  void _speakSentence(String text) {
    if (text.isEmpty) return;
    try {
      if (di.sl.isRegistered<TtsService>()) {
        di.sl<TtsService>().speak(text);
      }
    } catch (_) {}
  }

  void _selectOption(String option) {
    if (_selectedOption != null) return;

    final quest = _quests[_currentIndex];
    final isRight = option.trim().toLowerCase() ==
        quest.correctAnswer.trim().toLowerCase();

    setState(() {
      _selectedOption = option;
      _isCorrect = isRight;
    });

    try {
      if (isRight) {
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

  void _completePractice() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'pronounResolution',
      level: widget.level,
      phase: 'practice',
    );

    final targetMastery =
        '/game?category=grammar&gameType=pronounResolution&level=${widget.level}';
    context.pushReplacement(targetMastery);
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
      _completePractice();
    }
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
    final answered = _selectedOption != null;

    return PracticePhaseScaffold(
      title: 'Clarity Fixer Gym',
      gameType: 'pronounResolution',
      level: widget.level,
      currentExerciseIndex: _currentIndex,
      totalExercises: _quests.length,
      onComplete: _completePractice,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress bar & rule chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.teal500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColors.teal500.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Exercise ${_currentIndex + 1} of ${_quests.length}',
                    style: TextStyle(
                      color: AppColors.teal500,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Flexible(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.violet500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.violet500.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      quest.grammarRule,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.violet500,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Context Sentence Card with Target Pronoun Highlight
            Container(
              padding: EdgeInsets.all(18.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.teal500.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.visibility_rounded,
                        color: AppColors.teal500,
                        size: 20.r,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'CONTEXT PASSAGE',
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
                  SizedBox(height: 12.h),
                  Text(
                    quest.sentence,
                    style: TextStyle(
                      color: AppColors.slate100,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Instruction prompt
            Text(
              "Who or what does '${quest.targetPronoun}' refer to?",
              style: TextStyle(
                color: AppColors.slate300,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 12.h),

            // Antecedent Option Cards
            ...quest.options.map((option) {
              final isSelected = _selectedOption == option;
              final isCorrectOption = option.trim().toLowerCase() ==
                  quest.correctAnswer.trim().toLowerCase();

              Color borderColor = AppColors.slate800;
              Color bgColor = AppColors.slate900;
              Color textColor = AppColors.slate100;

              if (answered) {
                if (isCorrectOption) {
                  borderColor = AppColors.emerald400;
                  bgColor = AppColors.emerald400.withValues(alpha: 0.15);
                  textColor = AppColors.emerald400;
                } else if (isSelected) {
                  borderColor = AppColors.rose500;
                  bgColor = AppColors.rose500.withValues(alpha: 0.15);
                  textColor = AppColors.rose500;
                }
              }

              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: answered ? null : () => _selectOption(option),
                    borderRadius: BorderRadius.circular(14.r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: borderColor,
                          width: isSelected || (answered && isCorrectOption)
                              ? 2
                              : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            answered
                                ? (isCorrectOption
                                    ? Icons.check_circle_rounded
                                    : (isSelected
                                        ? Icons.cancel_rounded
                                        : Icons.circle_outlined))
                                : Icons.circle_outlined,
                            color: answered
                                ? (isCorrectOption
                                    ? AppColors.emerald400
                                    : (isSelected
                                        ? AppColors.rose500
                                        : AppColors.slate500))
                                : AppColors.slate500,
                            size: 20.r,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14.5.sp,
                                fontWeight: isSelected ||
                                        (answered && isCorrectOption)
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            SizedBox(height: 8.h),

            // Hint reveal button
            if (!answered)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() => _showHint = !_showHint);
                  },
                  icon: Icon(
                    _showHint
                        ? Icons.lightbulb_rounded
                        : Icons.lightbulb_outline_rounded,
                    color: AppColors.amber400,
                    size: 18.r,
                  ),
                  label: Text(
                    _showHint ? 'Hide Hint' : 'Need a Hint?',
                    style: TextStyle(
                      color: AppColors.amber400,
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            // Hint Card
            if (_showHint && !answered)
              Container(
                margin: EdgeInsets.only(top: 8.h, bottom: 8.h),
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppColors.amber400.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.amber400.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡', style: TextStyle(fontSize: 16.sp)),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        quest.hint,
                        style: TextStyle(
                          color: AppColors.slate200,
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Explanation card when answered
            if (answered) ...[
              Container(
                margin: EdgeInsets.symmetric(vertical: 12.h),
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: (_isCorrect ?? false)
                      ? AppColors.emerald400.withValues(alpha: 0.08)
                      : AppColors.rose500.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: (_isCorrect ?? false)
                        ? AppColors.emerald400.withValues(alpha: 0.3)
                        : AppColors.rose500.withValues(alpha: 0.3),
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
                                (_isCorrect ?? false)
                                    ? Icons.check_circle_rounded
                                    : Icons.info_outline_rounded,
                                color: (_isCorrect ?? false)
                                    ? AppColors.emerald400
                                    : AppColors.rose500,
                                size: 18.r,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  (_isCorrect ?? false)
                                      ? 'CLARITY LOCKED!'
                                      : 'RESOLUTION INSIGHT',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: (_isCorrect ?? false)
                                        ? AppColors.emerald400
                                        : AppColors.rose500,
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
                          icon: Icon(
                            Icons.volume_up_rounded,
                            color: AppColors.slate300,
                            size: 20.r,
                          ),
                          onPressed: () => _speakSentence(quest.sentence),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Listen to passage',
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      quest.explanation,
                      style: TextStyle(
                        color: AppColors.slate200,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Action button
              ElevatedButton(
                onPressed: _nextExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal500,
                  foregroundColor: AppColors.slate950,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  _currentIndex < _quests.length - 1
                      ? 'NEXT EXERCISE'
                      : 'START MASTERY PHASE →',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
