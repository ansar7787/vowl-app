import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';

/// Data model representing a sentence correction practice quest.
class SentenceCorrectionPracticeQuest {
  final String id;
  final int level;
  final String instruction;
  final String sentence;
  final String incorrectPart;
  final String correctedPart;
  final List<String> options;
  final String correctAnswer;
  final String hint;
  final String explanation;
  final String grammarRule;
  final String errorHighlight;

  const SentenceCorrectionPracticeQuest({
    required this.id,
    required this.level,
    required this.instruction,
    required this.sentence,
    required this.incorrectPart,
    required this.correctedPart,
    required this.options,
    required this.correctAnswer,
    required this.hint,
    required this.explanation,
    required this.grammarRule,
    required this.errorHighlight,
  });

  factory SentenceCorrectionPracticeQuest.fromJson(Map<String, dynamic> json) {
    return SentenceCorrectionPracticeQuest(
      id: json['id'] as String? ?? 'sc_practice_default',
      level: json['level'] as int? ?? 1,
      instruction: json['instruction'] as String? ??
          'Select the correction that fixes the error in the sentence.',
      sentence: json['sentence'] as String? ?? '',
      incorrectPart: json['incorrectPart'] as String? ?? '',
      correctedPart: json['correctedPart'] as String? ?? '',
      options: (json['options'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      correctAnswer: json['correctAnswer'] as String? ?? '',
      hint: json['hint'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      grammarRule: json['grammarRule'] as String? ?? 'Sentence Error Diagnosis',
      errorHighlight: json['errorHighlight'] as String? ?? 'Grammar Error',
    );
  }
}

/// Interactive Practice Phase screen for Sentence Correction: "Spot & Substitute Gym".
///
/// Features highlighted error identification, substitute option selection,
/// live sentence transformation, instant auditory confirmation, and grammatical feedback.
class SentenceCorrectionPracticeScreen extends StatefulWidget {
  final int level;

  const SentenceCorrectionPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<SentenceCorrectionPracticeScreen> createState() =>
      _SentenceCorrectionPracticeScreenState();
}

class _SentenceCorrectionPracticeScreenState
    extends State<SentenceCorrectionPracticeScreen> {
  List<SentenceCorrectionPracticeQuest> _quests = const [
    SentenceCorrectionPracticeQuest(
      id: 'FALLBACK_SC_P1',
      level: 1,
      instruction: 'Select the correction that fixes the error in the sentence.',
      sentence: 'The children is playing in the yard.',
      incorrectPart: 'is',
      correctedPart: 'are',
      options: ['is', 'am', 'was', 'are'],
      correctAnswer: 'are',
      hint: "Look at the subject 'children' — is it one child or more than one?",
      explanation:
          "The subject 'children' is plural, so it needs the plural form 'are' instead of the singular 'is'.",
      grammarRule: 'Subject-Verb Agreement: Be Verb with Plural Subjects',
      errorHighlight: 'Incorrect verb',
    ),
    SentenceCorrectionPracticeQuest(
      id: 'FALLBACK_SC_P2',
      level: 1,
      instruction: 'Select the correction that fixes the error in the sentence.',
      sentence: "The news are on at six o'clock every evening.",
      incorrectPart: 'are',
      correctedPart: 'is',
      options: ['is', 'are', 'was', 'were'],
      correctAnswer: 'is',
      hint:
          "Some nouns that end in -s, like 'news', are actually singular. What verb goes with a singular subject?",
      explanation:
          "'News' looks plural because of the final -s, but it is grammatically singular and takes 'is', not 'are'.",
      grammarRule: 'Subject-Verb Agreement: Singular Uncountable Nouns',
      errorHighlight: 'Incorrect verb',
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
          'assets/curriculum/grammar/sentenceCorrection_practice_${startLevel}_$endLevel.json';

      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests = data['quests'] as List<dynamic>? ?? [];

      final loaded = rawQuests
          .map((q) => SentenceCorrectionPracticeQuest.fromJson(
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

  void _speakText(String text) {
    try {
      if (di.sl.isRegistered<TtsService>()) {
        di.sl<TtsService>().speak(text);
      }
    } catch (_) {}
  }

  void _onOptionSelected(String option) {
    if (_isCorrect == true) return;

    final quest = _quests[_currentIndex];
    final isMatch =
        option.trim().toLowerCase() == quest.correctAnswer.trim().toLowerCase();

    setState(() {
      _selectedOption = option;
      _isCorrect = isMatch;
    });

    if (isMatch) {
      _speakText(
        quest.sentence.replaceAll(quest.incorrectPart, quest.correctedPart),
      );
    }
  }

  void _onNext() {
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

  void _onComplete() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'sentenceCorrection',
      level: widget.level,
      phase: 'practice',
    );
    final targetMastery =
        '/game?category=grammar&gameType=sentenceCorrection&level=${widget.level}';
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

    // Live display of sentence with either faulty highlight or corrected substitution
    final displaySentence = _isCorrect == true
        ? quest.sentence.replaceAll(quest.incorrectPart, quest.correctedPart)
        : quest.sentence;

    return PracticePhaseScaffold(
      title: 'Spot & Substitute Gym',
      gameType: 'sentenceCorrection',
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
            // Header: Rule badge & Exercise counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: AppColors.violet500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: AppColors.violet500.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      quest.grammarRule.toUpperCase(),
                      style: TextStyle(
                        color: AppColors.violet500,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
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

            // Instruction Banner
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
                    Icons.build_circle_rounded,
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
            SizedBox(height: 16.h),

            // Sentence Diagnostic Showcase
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: _isCorrect == true
                      ? AppColors.emerald500
                      : (_isCorrect == false
                          ? AppColors.rose500
                          : AppColors.slate800),
                  width: _isCorrect != null ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isCorrect == true
                            ? 'CORRECTED SENTENCE'
                            : 'TARGET FOR DIAGNOSIS',
                        style: TextStyle(
                          color: _isCorrect == true
                              ? AppColors.emerald400
                              : AppColors.slate400,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.violet500,
                          size: 20.r,
                        ),
                        onPressed: () => _speakText(displaySentence),
                        tooltip: 'Hear sentence',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    displaySentence,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  if (_isCorrect != true && quest.incorrectPart.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.rose500,
                          size: 16.r,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          "Faulty segment: '${quest.incorrectPart}'",
                          style: TextStyle(
                            color: AppColors.rose500,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Options List
            Text(
              'SELECT SUBSTITUTE CORRECTION',
              style: TextStyle(
                color: AppColors.slate400,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 10.h),

            ...quest.options.map((option) {
              final isSelected = _selectedOption == option;
              final isTarget = option.trim().toLowerCase() ==
                  quest.correctAnswer.trim().toLowerCase();

              Color optBg = AppColors.slate900;
              Color optBorder = AppColors.slate800;
              Color optText = Colors.white;

              if (isSelected) {
                if (_isCorrect == true) {
                  optBg = AppColors.emerald500.withValues(alpha: 0.2);
                  optBorder = AppColors.emerald500;
                  optText = AppColors.emerald400;
                } else if (_isCorrect == false) {
                  optBg = AppColors.rose500.withValues(alpha: 0.2);
                  optBorder = AppColors.rose500;
                  optText = AppColors.rose500;
                }
              } else if (_isCorrect == true && isTarget) {
                optBg = AppColors.emerald500.withValues(alpha: 0.2);
                optBorder = AppColors.emerald500;
                optText = AppColors.emerald400;
              }

              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Material(
                  color: optBg,
                  borderRadius: BorderRadius.circular(14.r),
                  child: InkWell(
                    onTap: () => _onOptionSelected(option),
                    borderRadius: BorderRadius.circular(14.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: optBorder, width: 1.2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            option,
                            style: TextStyle(
                              color: optText,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (isSelected && _isCorrect == true)
                            Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.emerald500,
                              size: 20.r,
                            )
                          else if (isSelected && _isCorrect == false)
                            Icon(
                              Icons.cancel_rounded,
                              color: AppColors.rose500,
                              size: 20.r,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            // Immediate Feedback Card
            if (_isCorrect == true) ...[
              SizedBox(height: 8.h),
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
              ),
            ] else if (_isCorrect == false) ...[
              SizedBox(height: 8.h),
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
                        'Not the right correction. Try another option!',
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
            ],

            // Hint Card
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
