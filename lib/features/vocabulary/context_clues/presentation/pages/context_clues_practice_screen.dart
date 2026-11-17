import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Guided active practice screen for Context Clues: "Forensic Clue Lab".
///
/// Implements clue archetype identification and active recall meaning deduction
/// with immediate pedagogical feedback before advancing to the Mastery phase.
class ContextCluesPracticeScreen extends StatefulWidget {
  final int level;

  const ContextCluesPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<ContextCluesPracticeScreen> createState() =>
      _ContextCluesPracticeScreenState();
}

class _ContextCluesPracticeScreenState
    extends State<ContextCluesPracticeScreen> {
  List<PracticeExercise> _exercises = const [
    PracticeExercise(
      exerciseType: 'contextPick',
      interactionType: 'choice',
      question:
          "Which type of context clue unlocks the meaning of 'AMAZING' in this sentence?\n\n\"The magician's final trick was AMAZING — meaning it was truly wonderful — and the whole audience jumped up to cheer.\"",
      options: [
        'Definition Clue',
        'Antonym Clue',
        'Inference Clue',
      ],
      correctAnswerIndex: 0,
      feedbackPerOption: [
        "Correct! The sentence uses a definition clue to clarify 'AMAZING'.",
        'Incorrect: The sentence defines the word directly rather than giving an opposite.',
        'Incorrect: The sentence gives an explicit definition rather than requiring indirect deduction.',
      ],
    ),
    PracticeExercise(
      exerciseType: 'fillGap',
      interactionType: 'typing',
      sentence:
          "Deduce the meaning: In the clue sentence, 'AMAZING' precisely means _____.",
      correctAnswer: 'wonderful',
      hint: "Recall the core deduced meaning (9 letters, starts with 'w').",
      feedbackIfWrong:
          "The deduced meaning of 'AMAZING' in this context is 'wonderful'.",
    ),
  ];
  int _currentExerciseIndex = 0;

  // Interaction state
  final TextEditingController _textController = TextEditingController();
  int? _selectedOptionIndex;
  bool _hasChecked = false;
  bool _isAnswerCorrect = false;
  String? _feedbackText;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _loadPracticeExercises();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadPracticeExercises() async {
    try {
      final batchIndex = ((widget.level - 1) ~/ 10) + 1;
      final startLevel = (batchIndex - 1) * 10 + 1;
      final endLevel = batchIndex * 10;
      final path =
          'assets/curriculum/vocabulary/contextClues_practice_${startLevel}_$endLevel.json';
      final jsonStr = await rootBundle.loadString(path);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final batch = PhasedQuestBatch.fromJson(data);

      final levelQuests =
          batch.quests.where((q) => q.level == widget.level).toList();
      final allExercises = <PracticeExercise>[];
      for (final q in (levelQuests.isNotEmpty ? levelQuests : batch.quests)) {
        allExercises.addAll(q.exercises);
      }

      if (mounted && allExercises.isNotEmpty) {
        setState(() {
          _exercises = allExercises;
        });
      }
    } catch (_) {
      // Keeps initial fallback exercises
    }
  }

  void _onOptionSelected(int index) {
    if (_hasChecked) return;
    setState(() {
      _selectedOptionIndex = index;
      _feedbackText = null;
    });
  }

  void _checkAnswer() {
    if (_hasChecked) return;
    final exercise = _exercises[_currentExerciseIndex];

    if (exercise.interactionType == 'choice') {
      if (_selectedOptionIndex == null) return;
      final isCorrect =
          _selectedOptionIndex == (exercise.correctAnswerIndex ?? 0);
      String feedback;
      if (exercise.feedbackPerOption.isNotEmpty &&
          _selectedOptionIndex! < exercise.feedbackPerOption.length) {
        feedback = exercise.feedbackPerOption[_selectedOptionIndex!];
      } else {
        feedback = isCorrect
            ? 'Perfect! That is the exact clue archetype.'
            : 'Not quite. Check how the sentence connects the details.';
      }
      setState(() {
        _hasChecked = true;
        _isAnswerCorrect = isCorrect;
        _feedbackText = feedback;
      });
    } else {
      final input = _textController.text.trim().toLowerCase();
      final expected = (exercise.correctAnswer ?? '').trim().toLowerCase();
      if (input.isEmpty) return;

      final isCorrect = input == expected;
      setState(() {
        _hasChecked = true;
        _isAnswerCorrect = isCorrect;
        _feedbackText = isCorrect
            ? 'Excellent deduction! You cracked the context clue.'
            : (exercise.feedbackIfWrong ??
                'Try again! The correct answer is "${exercise.correctAnswer}".');
      });
    }
  }

  void _nextExercise() {
    if (_currentExerciseIndex < _exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _selectedOptionIndex = null;
        _textController.clear();
        _hasChecked = false;
        _isAnswerCorrect = false;
        _feedbackText = null;
        _showHint = false;
      });
    } else {
      _finishPractice();
    }
  }

  void _finishPractice() {
    final target =
        '/game?category=vocabulary&gameType=contextClues&level=${widget.level}';
    context.pushReplacement(target);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final exercise = _exercises.isNotEmpty
        ? _exercises[_currentExerciseIndex]
        : null;

    if (exercise == null) {
      return PracticePhaseScaffold(
        title: 'Forensic Clue Lab',
        gameType: 'contextClues',
        level: widget.level,
        currentExerciseIndex: 0,
        totalExercises: 1,
        onComplete: _finishPractice,
        child: const Center(child: Text('No practice exercises available.')),
      );
    }

    final isLast = _currentExerciseIndex == _exercises.length - 1;

    return PracticePhaseScaffold(
      title: 'Forensic Clue Lab',
      gameType: 'contextClues',
      level: widget.level,
      currentExerciseIndex: _currentExerciseIndex,
      totalExercises: _exercises.length,
      onComplete: _finishPractice,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Exercise Subtitle ───────────────────────────────────
            Text(
              exercise.interactionType == 'choice'
                  ? 'CLUE ARCHETYPE IDENTIFICATION'
                  : 'ACTIVE RECALL MEANING DEDUCTION',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppColors.indigo500,
              ),
            ),
            SizedBox(height: 12.h),

            // ── Question Card ───────────────────────────────────────
            Container(
              padding: EdgeInsets.all(18.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                ),
              ),
              child: Text(
                exercise.question ?? exercise.sentence ?? '',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  color: isDark ? Colors.white : AppColors.slate900,
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // ── Interactive Area ───────────────────────────────────
            if (exercise.interactionType == 'choice') ...[
              ...List.generate(exercise.options.length, (idx) {
                final option = exercise.options[idx];
                final isSelected = _selectedOptionIndex == idx;
                Color border = isDark ? AppColors.slate800 : AppColors.slate200;
                Color bg = isDark ? AppColors.slate900 : Colors.white;

                if (isSelected && !_hasChecked) {
                  border = AppColors.indigo500;
                  bg = AppColors.indigo500.withValues(alpha: 0.08);
                } else if (_hasChecked) {
                  if (idx == exercise.correctAnswerIndex) {
                    border = AppColors.emerald500;
                    bg = AppColors.emerald500.withValues(alpha: 0.12);
                  } else if (isSelected && !_isAnswerCorrect) {
                    border = AppColors.rose500;
                    bg = AppColors.rose500.withValues(alpha: 0.12);
                  }
                }

                return Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12.r),
                    onTap: () => _onOptionSelected(idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: border, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24.r,
                            height: 24.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.indigo500
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.indigo500
                                    : (isDark
                                        ? AppColors.slate700
                                        : AppColors.slate300),
                              ),
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    size: 14.r,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.slate900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ] else ...[
              // Typing / active recall
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate900 : Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: _hasChecked
                        ? (_isAnswerCorrect
                            ? AppColors.emerald500
                            : AppColors.rose500)
                        : (isDark ? AppColors.slate800 : AppColors.slate200),
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _textController,
                  enabled: !_hasChecked,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type deduced meaning...',
                    hintStyle: TextStyle(
                      fontFamily: 'Outfit',
                      color: isDark ? AppColors.slate600 : AppColors.slate400,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (exercise.hint != null) ...[
                SizedBox(height: 8.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showHint = !_showHint;
                      });
                    },
                    icon: Icon(
                      Icons.lightbulb_outline,
                      size: 16.r,
                      color: AppColors.amber400,
                    ),
                    label: Text(
                      _showHint ? exercise.hint! : 'Need a clue hint?',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        color: AppColors.amber400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],

            // ── Feedback Banner ────────────────────────────────────
            if (_feedbackText != null) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: (_isAnswerCorrect
                          ? AppColors.emerald500
                          : AppColors.rose500)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: (_isAnswerCorrect
                            ? AppColors.emerald500
                            : AppColors.rose500)
                        .withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isAnswerCorrect
                          ? Icons.check_circle_rounded
                          : Icons.info_rounded,
                      color: _isAnswerCorrect
                          ? AppColors.emerald500
                          : AppColors.rose500,
                      size: 22.r,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        _feedbackText!,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: _isAnswerCorrect
                              ? AppColors.emerald500
                              : AppColors.rose500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 24.h),

            // ── Action Button ──────────────────────────────────────
            if (!_hasChecked)
              ElevatedButton(
                onPressed: _checkAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo500,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Check Answer',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              ElevatedButton(
                onPressed: _nextExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAnswerCorrect
                      ? AppColors.emerald500
                      : AppColors.indigo500,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  isLast ? 'Enter Mastery Phase 🏆' : 'Next Exercise ➔',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
