import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive Practice Phase screen for Complete Sentence ("Thought Completer Gym").
///
/// Prompts learners to evaluate sentence fragments and select the grammatically
/// complete and logically sound independent clause to finish the thought.
class CompleteSentencePracticeScreen extends StatefulWidget {
  final int level;

  const CompleteSentencePracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<CompleteSentencePracticeScreen> createState() =>
      _CompleteSentencePracticeScreenState();
}

class _CompleteSentencePracticeScreenState
    extends State<CompleteSentencePracticeScreen> {
  int _questIndex = 0;
  late List<Map<String, dynamic>> _quests;

  int? _selectedOptionIndex;
  bool _isChecked = false;
  bool _isCorrect = false;

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
        'assets/curriculum/writing/completeSentence_practice_${startLevel}_$endLevel.json';

    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final levelQuests = rawQuests.where((q) {
        final qLevel = q['level'] as int? ?? 1;
        return qLevel == widget.level;
      }).toList();

      if (mounted) {
        setState(() {
          if (levelQuests.isNotEmpty) {
            _quests = levelQuests;
            _resetForCurrentQuest();
          }
        });
      }
    } catch (_) {
      // Retain fallback quests on asset failure (e.g. test environment)
    }
  }

  List<Map<String, dynamic>> get _fallbackQuests => [
        {
          'id': 'WRT_COMPLETESENTENCE_PRAC_FALLBACK_1',
          'level': widget.level,
          'instruction': 'Select the grammatically complete predicate.',
          'stem': 'Although the morning traffic was exceptionally heavy,',
          'options': [
            'our delivery van reached the warehouse on schedule.',
            'reaching the warehouse on schedule.',
            'and our delivery van reached the warehouse.',
            'because the warehouse was already open.',
          ],
          'correctIndex': 0,
          'correctAnswer': 'our delivery van reached the warehouse on schedule.',
          'completeSentence':
              'Although the morning traffic was exceptionally heavy, our delivery van reached the warehouse on schedule.',
          'explanation':
              'A subordinate clause introduced by "Although" must be balanced by an independent clause containing its own subject and finite verb.',
          'distractorFeedback': {
            'reaching the warehouse on schedule.':
                'Lacks a finite verb and subject; it is a dangling participial phrase.',
            'and our delivery van reached the warehouse.':
                'Cannot use coordinating "and" directly after subordinating "Although".',
            'because the warehouse was already open.':
                'Two subordinate clauses without an independent clause create double dependency.',
          },
        },
      ];

  void _onOptionSelected(int index) {
    if (_isChecked) return;
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  void _onCheck() {
    if (_isChecked) {
      // Advance to next exercise or transition to Mastery
      if (_questIndex < _quests.length - 1) {
        setState(() {
          _questIndex++;
          _resetForCurrentQuest();
        });
      } else {
        PhaseProgressRecorder.recordPhaseCompleted(
          context,
          gameType: 'completeSentence',
          level: widget.level,
          phase: 'practice',
        );
        context.pushReplacement(
          '/game?category=writing&gameType=completeSentence&level=${widget.level}',
        );
      }
      return;
    }

    final quest = _quests.isNotEmpty ? _quests[_questIndex] : _fallbackQuests.first;
    final correctIndex = quest['correctIndex'] as int? ?? 0;

    setState(() {
      _isChecked = true;
      _isCorrect = (_selectedOptionIndex == correctIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quest = _quests.isNotEmpty ? _quests[_questIndex] : _fallbackQuests.first;

    final instruction = quest['instruction'] as String? ??
        'Select the grammatically complete predicate.';
    final stem = quest['stem'] as String? ?? '';
    final options = (quest['options'] as List<dynamic>? ?? []).cast<String>();
    final correctIndex = quest['correctIndex'] as int? ?? 0;
    final completeSentence = quest['completeSentence'] as String? ?? '';
    final explanation = quest['explanation'] as String? ?? '';
    final distractorFeedback =
        (quest['distractorFeedback'] as Map<String, dynamic>? ?? {})
            .cast<String, String>();

    return PracticePhaseScaffold(
      title: 'Thought Completer Gym',
      gameType: 'completeSentence',
      level: widget.level,
      currentExerciseIndex: _questIndex,
      totalExercises: _quests.length,
      onComplete: _onCheck,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header instruction
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : AppColors.indigo50,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark
                      ? AppColors.indigo500.withValues(alpha: 0.3)
                      : AppColors.indigo500.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'THOUGHT COMPLETER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'EXERCISE ${_questIndex + 1} OF ${_quests.length}',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.slate400
                                : AppColors.slate600,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    instruction,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.slate900,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Incomplete Sentence Stem Card
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        color: AppColors.indigo500,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'INCOMPLETE CLAUSE STEM',
                          style: TextStyle(
                            color: AppColors.indigo500,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    stem,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.slate900,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.slate800 : AppColors.slate100,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      'Select the finishing independent clause below: [ ... ]',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.slate400
                            : AppColors.slate600,
                        fontSize: 12.sp,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 18.h),

            // Options Header
            Text(
              'CANDIDATE PREDICATE COMPLETIONS',
              style: TextStyle(
                color: isDark ? AppColors.slate400 : AppColors.slate600,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 8.h),

            ...List.generate(options.length, (optIdx) {
              final optionText = options[optIdx];
              final isSelected = _selectedOptionIndex == optIdx;
              final isTarget = optIdx == correctIndex;

              Color borderColor;
              Color bgColor;

              if (_isChecked) {
                if (isTarget) {
                  borderColor = AppColors.emerald500;
                  bgColor = isDark
                      ? AppColors.emerald500.withValues(alpha: 0.15)
                      : AppColors.emerald50;
                } else if (isSelected && !_isCorrect) {
                  borderColor = AppColors.rose500;
                  bgColor = isDark
                      ? AppColors.rose500.withValues(alpha: 0.15)
                      : AppColors.rose500.withValues(alpha: 0.08);
                } else {
                  borderColor = isDark ? AppColors.slate800 : AppColors.slate200;
                  bgColor = isDark ? AppColors.slate900 : Colors.white;
                }
              } else if (isSelected) {
                borderColor = AppColors.indigo500;
                bgColor = isDark
                    ? AppColors.indigo500.withValues(alpha: 0.15)
                    : AppColors.indigo50;
              } else {
                borderColor = isDark ? AppColors.slate800 : AppColors.slate200;
                bgColor = isDark ? AppColors.slate900 : Colors.white;
              }

              final letter = String.fromCharCode(65 + optIdx); // A, B, C, D

              return GestureDetector(
                onTap: () => _onOptionSelected(optIdx),
                child: Container(
                  margin: EdgeInsets.only(bottom: 10.h),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: borderColor,
                      width: isSelected || (_isChecked && isTarget) ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28.w,
                        height: 28.h,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.indigo500
                              : (isDark ? AppColors.slate800 : AppColors.slate200),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          letter,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.slate300 : AppColors.slate700),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          optionText,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.slate900,
                            fontSize: 14.sp,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ),
                      if (_isChecked && isTarget)
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.emerald500,
                          size: 20.sp,
                        )
                      else if (_isChecked && isSelected && !_isCorrect)
                        Icon(
                          Icons.cancel_rounded,
                          color: AppColors.rose500,
                          size: 20.sp,
                        ),
                    ],
                  ),
                ),
              );
            }),

            SizedBox(height: 16.h),

            // Feedback Card when checked
            if (_isChecked)
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: _isCorrect
                      ? (isDark
                          ? AppColors.emerald500.withValues(alpha: 0.15)
                          : AppColors.emerald50)
                      : (isDark
                          ? AppColors.rose500.withValues(alpha: 0.15)
                          : AppColors.rose500.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: _isCorrect ? AppColors.emerald500 : AppColors.rose500,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isCorrect
                              ? Icons.check_circle_rounded
                              : Icons.error_outline_rounded,
                          color: _isCorrect
                              ? AppColors.emerald500
                              : AppColors.rose500,
                          size: 22.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _isCorrect
                                ? 'PERFECT CLAUSE COMPLETION!'
                                : 'INCOMPLETE OR ILLOGICAL STRUCTURE',
                            style: TextStyle(
                              color: _isCorrect
                                  ? AppColors.emerald500
                                  : AppColors.rose500,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '"$completeSentence"',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.slate900,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      _isCorrect
                          ? explanation
                          : (_selectedOptionIndex != null &&
                                  distractorFeedback.containsKey(
                                      options[_selectedOptionIndex!]))
                              ? distractorFeedback[options[_selectedOptionIndex!]]!
                              : explanation,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.slate300
                            : AppColors.slate700,
                        fontSize: 12.sp,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 20.h),

            // Action / Check button
            ElevatedButton(
              onPressed: (_selectedOptionIndex != null) ? _onCheck : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo500,
                disabledBackgroundColor:
                    isDark ? AppColors.slate800 : AppColors.slate300,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                _isChecked
                    ? (_questIndex < _quests.length - 1
                        ? 'Next Exercise'
                        : 'Proceed to Mastery')
                    : 'Check Clause Completion',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
