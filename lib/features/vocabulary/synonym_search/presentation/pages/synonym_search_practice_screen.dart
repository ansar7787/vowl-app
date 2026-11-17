import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Guided active practice screen for Synonym Search: "Nuance Gym".
///
/// Implements interactive context selection and active recall typing
/// with per-option explanatory feedback before entering the timed Test phase.
class SynonymSearchPracticeScreen extends StatefulWidget {
  final int level;

  const SynonymSearchPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<SynonymSearchPracticeScreen> createState() =>
      _SynonymSearchPracticeScreenState();
}

class _SynonymSearchPracticeScreenState
    extends State<SynonymSearchPracticeScreen> {
  List<PracticeExercise> _exercises = [];
  bool _isLoading = true;
  int _currentExerciseIndex = 0;

  // Exercise interaction state
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
          'assets/curriculum/vocabulary/synonymSearch_practice_${startLevel}_$endLevel.json';
      final jsonStr = await rootBundle.loadString(path);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final batch = PhasedQuestBatch.fromJson(data);

      final levelQuests =
          batch.quests.where((q) => q.level == widget.level).toList();
      final allExercises = <PracticeExercise>[];
      for (final q in (levelQuests.isNotEmpty ? levelQuests : batch.quests)) {
        allExercises.addAll(q.exercises);
      }

      if (mounted) {
        setState(() {
          _exercises = allExercises;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _exercises = [
            const PracticeExercise(
              exerciseType: 'contextPick',
              interactionType: 'choice',
              question: "Which sentence naturally calls for 'big' instead of 'large'?",
              options: [
                "The government surveyed a _____ parcel of land.",
                "Winning that game was a _____ deal for our team!",
                "The warehouse holds a _____ volume of goods.",
              ],
              correctAnswerIndex: 1,
              feedbackPerOption: [
                "For land surveys, 'large' is preferred because it is measurable and factual.",
                "Spot on! 'Big deal' is an emotional idiom — never 'large deal'.",
                "For warehouse volume, 'large' is the standard factual term.",
              ],
            ),
            const PracticeExercise(
              exerciseType: 'fillGap',
              interactionType: 'typing',
              sentence: "The elephant is a very _____ animal.",
              correctAnswer: 'large',
              hint: "Synonym of 'big' used in factual descriptions.",
              feedbackIfWrong: "The factual synonym of 'big' is 'large'.",
            ),
          ];
          _isLoading = false;
        });
      }
    }
  }

  void _checkCurrentAnswer() {
    if (_exercises.isEmpty) return;
    final exercise = _exercises[_currentExerciseIndex];

    if (exercise.interactionType == 'typing') {
      final input = _textController.text.trim().toLowerCase();
      final target = (exercise.correctAnswer ?? '').trim().toLowerCase();
      final isCorrect = input == target;

      if (isCorrect) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.mediumImpact();
      }

      setState(() {
        _hasChecked = true;
        _isAnswerCorrect = isCorrect;
        _feedbackText = isCorrect
            ? 'Excellent! You mastered the native usage.'
            : (exercise.feedbackIfWrong ??
                'The correct word is "${exercise.correctAnswer}".');
      });
    } else {
      // Choice interaction
      if (_selectedOptionIndex == null) return;
      final isCorrect =
          _selectedOptionIndex == (exercise.correctAnswerIndex ?? 0);

      if (isCorrect) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.mediumImpact();
      }

      String feedback = isCorrect ? 'Correct!' : 'Not quite.';
      if (exercise.feedbackPerOption.isNotEmpty &&
          _selectedOptionIndex! < exercise.feedbackPerOption.length) {
        feedback = exercise.feedbackPerOption[_selectedOptionIndex!];
      }

      setState(() {
        _hasChecked = true;
        _isAnswerCorrect = isCorrect;
        _feedbackText = feedback;
      });
    }
  }

  void _advanceOrFinish() {
    if (!_hasChecked) {
      _checkCurrentAnswer();
      return;
    }

    if (_currentExerciseIndex < _exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _selectedOptionIndex = null;
        _hasChecked = false;
        _isAnswerCorrect = false;
        _feedbackText = null;
        _showHint = false;
        _textController.clear();
      });
    } else {
      _finishPracticePhase();
    }
  }

  void _finishPracticePhase() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'synonymSearch',
      level: widget.level,
      phase: 'practice',
    );
    // Navigate to Test Phase (existing screen via /game route)
    final target =
        '/game?category=vocabulary&gameType=synonymSearch&level=${widget.level}';
    context.pushReplacement(target);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.slate950 : AppColors.slate50,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final exercise =
        _exercises.isNotEmpty ? _exercises[_currentExerciseIndex] : null;

    if (exercise == null) {
      return PracticePhaseScaffold(
        title: 'Nuance Gym',
        gameType: 'synonymSearch',
        level: widget.level,
        currentExerciseIndex: 0,
        totalExercises: 1,
        onComplete: _finishPracticePhase,
        child: const Center(child: Text('No practice exercises available.')),
      );
    }

    final isLast = _currentExerciseIndex == _exercises.length - 1;
    final actionLabel = _hasChecked
        ? (isLast ? 'Enter Mastery Phase 🏆' : 'Next Exercise ➔')
        : 'Check Answer';

    final canSubmit = exercise.interactionType == 'typing'
        ? _textController.text.trim().isNotEmpty
        : _selectedOptionIndex != null;

    return PracticePhaseScaffold(
      title: 'Nuance Gym (${_currentExerciseIndex + 1}/${_exercises.length})',
      gameType: 'synonymSearch',
      level: widget.level,
      currentExerciseIndex: _currentExerciseIndex,
      totalExercises: _exercises.length,
      actionLabel: actionLabel,
      isActionEnabled: _hasChecked || canSubmit,
      onComplete: _advanceOrFinish,
      isHintAvailable: exercise.hint != null,
      onHint: exercise.hint != null
          ? () {
              setState(() {
                _showHint = !_showHint;
              });
            }
          : null,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hint Panel ─────────────────────────────────────────
            if (_showHint && exercise.hint != null) ...[
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.amber500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: AppColors.amber500.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Text('💡', style: TextStyle(fontSize: 18.sp)),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        exercise.hint!,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.amber400 : AppColors.amber600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ],

            // ── Exercise Header Capsule ────────────────────────────
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.violet500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                exercise.interactionType == 'typing'
                    ? '✍️ ACTIVE RECALL — TYPE THE SYNONYM'
                    : '🎯 NUANCE DIFFERENTIATION — WHICH FITS BEST?',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.violet500,
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // ── Interactive Body ───────────────────────────────────
            if (exercise.interactionType == 'typing')
              _buildTypingExercise(exercise, isDark)
            else
              _buildChoiceExercise(exercise, isDark),

            // ── Feedback Panel ─────────────────────────────────────
            if (_hasChecked && _feedbackText != null) ...[
              SizedBox(height: 18.h),
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: _isAnswerCorrect
                      ? AppColors.emerald500.withValues(alpha: 0.12)
                      : AppColors.rose500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: _isAnswerCorrect
                        ? AppColors.emerald500
                        : AppColors.rose500,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          fontSize: 13.5.sp,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.slate900,
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
    );
  }

  Widget _buildTypingExercise(PracticeExercise exercise, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDark ? AppColors.slate900 : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark ? AppColors.slate800 : AppColors.slate200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete the sentence with the accurate native synonym:',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.slate400 : AppColors.slate600,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                exercise.sentence ?? '',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  color: isDark ? Colors.white : AppColors.slate900,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        TextField(
          controller: _textController,
          enabled: !_hasChecked,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (!_hasChecked) _checkCurrentAnswer();
          },
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.slate900,
          ),
          decoration: InputDecoration(
            hintText: 'Type your answer here...',
            hintStyle: TextStyle(
              color: isDark ? AppColors.slate500 : AppColors.slate400,
            ),
            filled: true,
            fillColor: isDark ? AppColors.slate900 : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: isDark ? AppColors.slate800 : AppColors.slate300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: isDark ? AppColors.slate800 : AppColors.slate300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(
                color: AppColors.violet500,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceExercise(PracticeExercise exercise, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (exercise.question != null) ...[
          Text(
            exercise.question!,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              height: 1.4,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          SizedBox(height: 16.h),
        ],
        ...List.generate(exercise.options.length, (idx) {
          final isSelected = _selectedOptionIndex == idx;
          final isCorrectOption = idx == exercise.correctAnswerIndex;

          Color borderColor;
          Color bgColor;

          if (!_hasChecked) {
            borderColor = isSelected
                ? AppColors.violet500
                : (isDark ? AppColors.slate800 : AppColors.slate200);
            bgColor = isSelected
                ? AppColors.violet500.withValues(alpha: 0.12)
                : (isDark ? AppColors.slate900 : Colors.white);
          } else {
            if (isCorrectOption) {
              borderColor = AppColors.emerald500;
              bgColor = AppColors.emerald500.withValues(alpha: 0.15);
            } else if (isSelected && !isCorrectOption) {
              borderColor = AppColors.rose500;
              bgColor = AppColors.rose500.withValues(alpha: 0.15);
            } else {
              borderColor = isDark ? AppColors.slate800 : AppColors.slate200;
              bgColor = isDark ? AppColors.slate900 : Colors.white;
            }
          }

          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: InkWell(
              onTap: _hasChecked
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedOptionIndex = idx;
                      });
                    },
              borderRadius: BorderRadius.circular(12.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 14.h,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: borderColor,
                    width: isSelected || (_hasChecked && isCorrectOption)
                        ? 2
                        : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26.w,
                      height: 26.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.violet500
                            : (isDark
                                ? AppColors.slate800
                                : AppColors.slate200),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + idx),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? AppColors.slate400
                                    : AppColors.slate600),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        exercise.options[idx],
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: isDark ? Colors.white : AppColors.slate900,
                        ),
                      ),
                    ),
                    if (_hasChecked && isCorrectOption)
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.emerald500,
                        size: 20.r,
                      )
                    else if (_hasChecked && isSelected && !isCorrectOption)
                      Icon(
                        Icons.cancel_rounded,
                        color: AppColors.rose500,
                        size: 20.r,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
