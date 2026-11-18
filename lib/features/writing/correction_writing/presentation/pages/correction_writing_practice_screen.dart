import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive Practice Phase screen for Correction Writing ("Grammar Repair & Proofreader Gym").
///
/// Prompts learners to evaluate a sentence with a bracketed grammatical flaw, select the single
/// replacement that restores full syntactic harmony, and review diagnostic feedback explaining why alternatives fail.
class CorrectionWritingPracticeScreen extends StatefulWidget {
  final int level;

  const CorrectionWritingPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<CorrectionWritingPracticeScreen> createState() =>
      _CorrectionWritingPracticeScreenState();
}

class _CorrectionWritingPracticeScreenState
    extends State<CorrectionWritingPracticeScreen> {
  int _questIndex = 0;
  late List<Map<String, dynamic>> _quests;

  int? _selectedOptionIndex;
  bool _isChecked = false;
  bool _isCorrect = false;

  bool get isCorrect => _isCorrect;

  @override
  void initState() {
    super.initState();
    _quests = _fallbackQuests;
    _resetForCurrentQuest();
    _loadCurriculum();
  }

  void _resetForCurrentQuest() {
    _selectedOptionIndex = null;
    _isChecked = false;
    _isCorrect = false;
  }

  Future<void> _loadCurriculum() async {
    final batchIndex = ((widget.level - 1) ~/ 10) + 1;
    final startLevel = (batchIndex - 1) * 10 + 1;
    final endLevel = batchIndex * 10;
    final assetPath =
        'assets/curriculum/writing/correctionWriting_practice_${startLevel}_$endLevel.json';

    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final levelQuests = rawQuests.where((q) {
        final id = q['id'] as String? ?? '';
        final match = RegExp(r'_L(\d+)_').firstMatch(id);
        if (match != null) {
          return int.parse(match.group(1)!) == widget.level;
        }
        return false;
      }).toList();

      if (mounted && levelQuests.isNotEmpty) {
        setState(() {
          _quests = levelQuests;
          _resetForCurrentQuest();
        });
      }
    } catch (_) {
      // Retain fallback quests on asset failure
    }
  }

  List<Map<String, dynamic>> get _fallbackQuests => [
        {
          'id': 'WRT_CORRECTIONWRITING_PRAC_FALLBACK_1',
          'instruction':
              'Select the grammatically accurate correction to repair the bracketed error.',
          'flawedPassage':
              'Each of the apartments on this floor [have] its own balcony.',
          'bracketedError': 'have',
          'options': [
            'has',
            'have had',
            'having',
            'are having',
          ],
          'correctIndex': 0,
          'correctAnswer': 'has',
          'correctedSentence':
              'Each of the apartments on this floor has its own balcony.',
          'hint':
              'Find the true subject of the verb — is it \'the apartments\' or the word \'Each\'?',
          'explanation':
              '\'Each\' is the grammatical subject, and \'each\' is always singular, even when it is followed by a plural phrase like \'of the apartments.\' So the verb must be singular: \'has.\'',
          'distractorFeedback': {
            'have had':
                'Incorrect grammatical form; fails to satisfy the grammatical number, tense, or structural requirement.',
            'having':
                'Incompatible participle choice that leaves the sentence without a finite main verb predicate.',
            'are having':
                'Creates a plural agreement mismatch with the singular subject \'Each\'.',
          },
        },
      ];

  void _onOptionTap(int index) {
    if (_isChecked) return;
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  void _onCheck() {
    if (_selectedOptionIndex == null) return;

    final quest = _quests[_questIndex];
    final correctIndex = quest['correctIndex'] as int? ?? 0;
    final isCorrectMatch = _selectedOptionIndex == correctIndex;

    setState(() {
      _isChecked = true;
      _isCorrect = isCorrectMatch;
    });
  }

  void _onNext() {
    if (_questIndex < _quests.length - 1) {
      setState(() {
        _questIndex++;
        _resetForCurrentQuest();
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'correctionWriting',
        level: widget.level,
        phase: 'practice',
      );
      context.pushReplacement(
        '/game?category=writing&gameType=correctionWriting&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quest = _quests[_questIndex];

    final instruction = quest['instruction'] as String? ?? '';
    final flawedPassage = quest['flawedPassage'] as String? ?? '';
    final bracketedError = quest['bracketedError'] as String? ?? '';
    final options = (quest['options'] as List<dynamic>? ?? []).cast<String>();
    final correctIndex = quest['correctIndex'] as int? ?? 0;
    final explanation = quest['explanation'] as String? ?? '';
    final correctedSentence = quest['correctedSentence'] as String? ?? '';
    final distractorFeedback =
        (quest['distractorFeedback'] as Map<String, dynamic>? ?? {});

    final isLast = _questIndex >= _quests.length - 1;

    return PracticePhaseScaffold(
      title: 'Grammar Repair & Proofreader Gym',
      gameType: 'correctionWriting',
      level: widget.level,
      currentExerciseIndex: _questIndex,
      totalExercises: _quests.length,
      actionLabel: !_isChecked
          ? 'Check Correction'
          : (isLast ? 'Start Mastery Phase' : 'Next Repair'),
      isActionEnabled: _selectedOptionIndex != null || _isChecked,
      onComplete: _isChecked ? _onNext : _onCheck,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress & Strategy Badge
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.indigo500.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'PRACTICE EXERCISE ${_questIndex + 1} OF ${_quests.length}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.indigo500,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.emerald500.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'Surgical Flaw Repair',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.emerald500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Flawed Passage Spotlight Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.find_in_page_rounded,
                        color: AppColors.rose500,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'PASSAGE WITH BRACKETED FLAW',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.rose500,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    flawedPassage,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.slate100 : AppColors.slate800,
                      height: 1.45,
                    ),
                  ),
                  if (bracketedError.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: AppColors.rose500.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: AppColors.rose500.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        'Target Flaw: [$bracketedError]',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.rose500,
                        ),
                      ),
                    ),
                  ],
                  if (instruction.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 15.sp,
                          color: AppColors.amber500,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            instruction,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              color: isDark
                                  ? AppColors.slate400
                                  : AppColors.slate600,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Section Label
            Text(
              'SELECT THE CORRECT REPLACEMENT WORD:',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.slate400 : AppColors.slate600,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 10.h),

            // Options List
            ...List.generate(options.length, (index) {
              final optionText = options[index];
              final isSelected = _selectedOptionIndex == index;
              final isCorrectOption = index == correctIndex;

              Color borderColor =
                  isDark ? AppColors.slate800 : AppColors.slate200;
              Color cardBg = isDark ? AppColors.slate900 : Colors.white;
              Color indicatorColor =
                  isDark ? AppColors.slate700 : AppColors.slate300;
              IconData indicatorIcon = Icons.circle_outlined;

              if (_isChecked) {
                if (isCorrectOption) {
                  borderColor = AppColors.emerald500;
                  cardBg = AppColors.emerald500.withValues(alpha: 0.08);
                  indicatorColor = AppColors.emerald500;
                  indicatorIcon = Icons.check_circle_rounded;
                } else if (isSelected) {
                  borderColor = AppColors.rose500;
                  cardBg = AppColors.rose500.withValues(alpha: 0.08);
                  indicatorColor = AppColors.rose500;
                  indicatorIcon = Icons.cancel_rounded;
                }
              } else if (isSelected) {
                borderColor = AppColors.indigo500;
                cardBg = AppColors.indigo500.withValues(alpha: 0.06);
                indicatorColor = AppColors.indigo500;
                indicatorIcon = Icons.radio_button_checked_rounded;
              }

              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onOptionTap(index),
                    borderRadius: BorderRadius.circular(14.r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: borderColor,
                          width: isSelected || (_isChecked && isCorrectOption)
                              ? 1.8
                              : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            indicatorIcon,
                            size: 20.sp,
                            color: indicatorColor,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              optionText,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.sp,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isDark
                                    ? AppColors.slate100
                                    : AppColors.slate800,
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

            // Feedback Card (shown after checking)
            if (_isChecked) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: _isCorrect
                      ? AppColors.emerald500.withValues(alpha: 0.1)
                      : AppColors.amber500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: _isCorrect
                        ? AppColors.emerald500.withValues(alpha: 0.4)
                        : AppColors.amber500.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isCorrect
                              ? Icons.verified_rounded
                              : Icons.info_outline_rounded,
                          size: 20.sp,
                          color: _isCorrect
                              ? AppColors.emerald500
                              : AppColors.amber500,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _isCorrect
                                ? 'PERFECT GRAMMATICAL REPAIR!'
                                : 'REPAIR FEEDBACK & REVISION',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              color: _isCorrect
                                  ? AppColors.emerald500
                                  : AppColors.amber500,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        color: isDark
                            ? AppColors.slate200
                            : AppColors.slate700,
                        height: 1.35,
                      ),
                    ),
                    if (_isCorrect && correctedSentence.isNotEmpty) ...[
                      SizedBox(height: 10.h),
                      Text(
                        'REPAIRED SENTENCE:',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emerald500,
                          letterSpacing: 0.6,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        correctedSentence,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.slate100
                              : AppColors.slate800,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (!_isCorrect &&
                        _selectedOptionIndex != null &&
                        distractorFeedback
                            .containsKey(options[_selectedOptionIndex!])) ...[
                      SizedBox(height: 10.h),
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: AppColors.rose500.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: AppColors.rose500.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 16.sp,
                              color: AppColors.rose500,
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                distractorFeedback[
                                        options[_selectedOptionIndex!]]
                                    .toString(),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.sp,
                                  color: AppColors.rose500,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
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
