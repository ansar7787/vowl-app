import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Guided active practice screen for Antonym Search: "Contrast Gym".
///
/// Implements interactive contextual contrast selection and active recall typing
/// with immediate explanatory feedback before entering the timed Test phase.
class AntonymSearchPracticeScreen extends StatefulWidget {
  final int level;

  const AntonymSearchPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<AntonymSearchPracticeScreen> createState() =>
      _AntonymSearchPracticeScreenState();
}

class _AntonymSearchPracticeScreenState
    extends State<AntonymSearchPracticeScreen> {
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
          'assets/curriculum/vocabulary/antonymSearch_practice_${startLevel}_$endLevel.json';
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
              question:
                  "Which sentence pair correctly uses 'here' and 'there'?",
              options: [
                "I am standing right here, but my brother is waiting over there by the car.",
                "I am standing right there, but my brother is waiting over there by the car.",
                "The dog ran away to here while staying here.",
              ],
              correctAnswerIndex: 0,
              feedbackPerOption: [
                "Perfect! 'Here' anchors directly to the speaker's spot, while 'there' points away to the car.",
                "Incorrect: 'Here' and 'there' express opposite locations relative to the speaker.",
                "Incorrect: 'Here' denotes the speaker's immediate location, not an outward distance.",
              ],
            ),
            const PracticeExercise(
              exerciseType: 'fillGap',
              interactionType: 'typing',
              sentence:
                  "The delivery package was left over _____ on the distant front porch.",
              correctAnswer: 'there',
              hint:
                  "Opposite of 'here' indicating a distant location away from the speaker.",
              feedbackIfWrong:
                  "The opposite of 'here' for a distant spot is 'there'.",
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
            ? 'Excellent! You mastered the polar opposite.'
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
    // Navigate to Test Phase (existing screen via /game route)
    final target =
        '/game?category=vocabulary&gameType=antonymSearch&level=${widget.level}';
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
        title: 'Contrast Gym',
        gameType: 'antonymSearch',
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
      title: 'Contrast Gym',
      gameType: 'antonymSearch',
      level: widget.level,
      currentExerciseIndex: _currentExerciseIndex,
      totalExercises: _exercises.length,
      actionLabel: actionLabel,
      isActionEnabled: _hasChecked || canSubmit,
      onComplete: _advanceOrFinish,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Exercise Header ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: exercise.interactionType == 'typing'
                        ? AppColors.teal400.withValues(alpha: 0.15)
                        : AppColors.blue500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        exercise.interactionType == 'typing'
                            ? Icons.keyboard_rounded
                            : Icons.touch_app_rounded,
                        size: 14.r,
                        color: exercise.interactionType == 'typing'
                            ? AppColors.teal400
                            : AppColors.blue500,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        exercise.interactionType == 'typing'
                            ? 'ACTIVE RECALL TYPING'
                            : 'CONTRAST SELECTION',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          color: exercise.interactionType == 'typing'
                            ? AppColors.teal400
                            : AppColors.blue500,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (exercise.hint != null && !_hasChecked)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showHint = !_showHint;
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 16.r,
                          color: AppColors.amber400,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          _showHint ? 'Hide Hint' : 'Hint',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.amber400,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),

            // ── Hint Card (if expanded) ────────────────────────────
            if (_showHint && exercise.hint != null) ...[
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.amber500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColors.amber500.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '💡 ${exercise.hint!}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.amber400,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
            ],

            // ── Interaction Body ───────────────────────────────────
            if (exercise.interactionType == 'typing')
              _buildTypingBody(exercise, isDark)
            else
              _buildChoiceBody(exercise, isDark),

            // ── Explanatory Feedback Card ──────────────────────────
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
                        ? AppColors.emerald500.withValues(alpha: 0.3)
                        : AppColors.rose500.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isAnswerCorrect ? '🎉' : '💡',
                      style: TextStyle(fontSize: 18.sp),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isAnswerCorrect
                                ? 'EXCELLENT!'
                                : 'PEDAGOGICAL INSIGHT',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              color: _isAnswerCorrect
                                  ? AppColors.emerald500
                                  : AppColors.rose500,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _feedbackText!,
                            style: TextStyle(
                              fontSize: 13.sp,
                              height: 1.35,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.slate800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceBody(PracticeExercise exercise, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (exercise.question != null) ...[
          Text(
            exercise.question!,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          SizedBox(height: 14.h),
        ],
        ...List.generate(exercise.options.length, (index) {
          final option = exercise.options[index];
          final isSelected = _selectedOptionIndex == index;
          final isCorrect = index == exercise.correctAnswerIndex;

          Color borderColor;
          Color bgColor;

          if (_hasChecked) {
            if (isCorrect) {
              borderColor = AppColors.emerald500;
              bgColor = AppColors.emerald500.withValues(alpha: 0.15);
            } else if (isSelected) {
              borderColor = AppColors.rose500;
              bgColor = AppColors.rose500.withValues(alpha: 0.15);
            } else {
              borderColor = isDark ? AppColors.slate800 : AppColors.slate200;
              bgColor = isDark ? AppColors.slate900 : Colors.white;
            }
          } else {
            borderColor = isSelected
                ? AppColors.blue500
                : (isDark ? AppColors.slate800 : AppColors.slate200);
            bgColor = isSelected
                ? AppColors.blue500.withValues(alpha: 0.1)
                : (isDark ? AppColors.slate900 : Colors.white);
          }

          return GestureDetector(
            onTap: _hasChecked
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedOptionIndex = index;
                    });
                  },
            child: Container(
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22.r,
                    height: 22.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.blue500
                            : (isDark
                                ? AppColors.slate700
                                : AppColors.slate300),
                        width: 2,
                      ),
                      color: isSelected ? AppColors.blue500 : Colors.transparent,
                    ),
                    child: isSelected
                        ? Icon(Icons.check, size: 14.r, color: Colors.white)
                        : null,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        height: 1.35,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTypingBody(PracticeExercise exercise, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (exercise.sentence != null) ...[
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate900 : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isDark ? AppColors.slate800 : AppColors.slate200,
              ),
            ),
            child: Text(
              exercise.sentence!,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),
          ),
          SizedBox(height: 16.h),
        ],
        Text(
          'TYPE THE POLAR OPPOSITE',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.teal400,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: _textController,
          enabled: !_hasChecked,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (_textController.text.trim().isNotEmpty && !_hasChecked) {
              _checkCurrentAnswer();
            }
          },
          onChanged: (_) {
            setState(() {});
          },
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.slate900,
          ),
          decoration: InputDecoration(
            hintText: 'Enter opposite word...',
            hintStyle: TextStyle(
              fontSize: 14.sp,
              color: isDark ? AppColors.slate500 : AppColors.slate400,
            ),
            filled: true,
            fillColor: isDark ? AppColors.slate900 : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: isDark ? AppColors.slate800 : AppColors.slate200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(
                color: AppColors.teal400,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
