import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Guided active practice screen for Topic Vocab: "Topic Sorting Gym".
///
/// Implements categorical classification, odd-one-out topic membership selection,
/// and typing gap-fill exercises with immediate pedagogical feedback before advancing to Mastery.
class TopicVocabPracticeScreen extends StatefulWidget {
  final int level;

  const TopicVocabPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<TopicVocabPracticeScreen> createState() =>
      _TopicVocabPracticeScreenState();
}

class _TopicVocabPracticeScreenState extends State<TopicVocabPracticeScreen> {
  List<PracticeExercise> _exercises = const [
    PracticeExercise(
      exerciseType: 'categoryClassification',
      interactionType: 'choice',
      question: 'Which topic category does the word "Boiling" belong to?',
      options: [
        'Hot',
        'Cold',
      ],
      correctAnswerIndex: 0,
      correctAnswer: 'Hot',
      feedbackPerOption: [
        'Correct! "Boiling" describes high heat where liquid bubbles rapidly.',
        'Not quite. "Boiling" involves intense thermal heat, not cold.',
      ],
      hint: 'Think about what happens to water at 100°C.',
    ),
    PracticeExercise(
      exerciseType: 'wordSelection',
      interactionType: 'choice',
      question:
          'Which of the following terms belongs to the "Cold" category?',
      options: [
        'Freezing',
        'Scorching',
        'Boiling',
        'Steaming',
      ],
      correctAnswerIndex: 0,
      correctAnswer: 'Freezing',
      feedbackPerOption: [
        'Spot on! "Freezing" describes temperatures low enough for water to turn to ice.',
        'Incorrect. "Scorching" describes intense heat.',
        'Incorrect. "Boiling" describes intense heat.',
        'Incorrect. "Steaming" describes hot vapor.',
      ],
      hint: 'Look for the temperature at or below 0°C.',
    ),
    PracticeExercise(
      exerciseType: 'fillGap',
      interactionType: 'typing',
      sentence:
          'The item was classified under the category of Hot: "______".',
      question: 'Type a word describing water heated to bubbles (BOILING):',
      correctAnswer: 'BOILING',
      hint: 'Starts with "B".',
      feedbackIfWrong: 'The expected term is "BOILING".',
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
          'assets/curriculum/vocabulary/topicVocab_practice_${startLevel}_$endLevel.json';
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
      // Keeps fallback items
    }
  }

  void _onOptionSelected(int index) {
    if (_hasChecked) return;
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  void _checkAnswer() {
    if (_hasChecked) return;
    final currentEx = _exercises[_currentExerciseIndex];

    if (currentEx.interactionType == 'choice') {
      final selected = _selectedOptionIndex;
      if (selected == null) return;
      final isCorrect = selected == currentEx.correctAnswerIndex;
      final feedback = (selected < currentEx.feedbackPerOption.length)
          ? currentEx.feedbackPerOption[selected]
          : (isCorrect ? 'Correct!' : 'Try again!');

      setState(() {
        _hasChecked = true;
        _isAnswerCorrect = isCorrect;
        _feedbackText = feedback;
      });
    } else {
      // Typing
      final input = _textController.text.trim().toLowerCase();
      final expected = (currentEx.correctAnswer ?? '').trim().toLowerCase();
      final isCorrect = input == expected;

      setState(() {
        _hasChecked = true;
        _isAnswerCorrect = isCorrect;
        _feedbackText = isCorrect
            ? 'Spot on! You accurately categorized the thematic term.'
            : (currentEx.feedbackIfWrong ??
                'Not quite. Expected: ${currentEx.correctAnswer}');
      });
    }
  }

  void _nextExercise() {
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
    final target =
        '/game?category=vocabulary&gameType=topicVocab&level=${widget.level}';
    context.pushReplacement(target);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);
    final primaryColor = theme.primaryColor;

    if (_exercises.isEmpty) {
      return PracticePhaseScaffold(
        title: 'Topic Sorting Gym: Level ${widget.level}',
        gameType: 'topicVocab',
        level: widget.level,
        currentExerciseIndex: 0,
        totalExercises: 1,
        onComplete: _finishPracticePhase,
        child: const Center(child: Text('No practice exercises available.')),
      );
    }

    final currentEx = _exercises[_currentExerciseIndex];

    return PracticePhaseScaffold(
      title: 'Topic Sorting Gym',
      gameType: 'topicVocab',
      level: widget.level,
      currentExerciseIndex: _currentExerciseIndex,
      totalExercises: _exercises.length,
      onComplete: _finishPracticePhase,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'EXERCISE ${_currentExerciseIndex + 1} OF ${_exercises.length}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: primaryColor,
                  ),
                ),
                if (currentEx.hint != null && currentEx.hint!.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showHint = !_showHint;
                      });
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 14.r,
                            color: primaryColor,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            _showHint ? 'Hide Hint' : 'Hint',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),

            // Hint Banner
            if (_showHint &&
                currentEx.hint != null &&
                currentEx.hint!.isNotEmpty) ...[
              Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.amber500.withValues(
                    alpha: isDark ? 0.15 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.amber500.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_rounded,
                      color: AppColors.amber400,
                      size: 18.r,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        currentEx.hint!,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.amber200
                              : AppColors.amber900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Exercise Prompt Container
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
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (currentEx.question != null) ...[
                    Text(
                      currentEx.question!,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                    ),
                  ],
                  if (currentEx.sentence != null &&
                      currentEx.sentence!.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.slate950
                            : AppColors.slate50,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isDark
                              ? AppColors.slate800
                              : AppColors.slate200,
                        ),
                      ),
                      child: Text(
                        currentEx.sentence!,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: isDark
                              ? AppColors.slate200
                              : AppColors.slate800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Exercise Inputs
            if (currentEx.interactionType == 'choice') ...[
              for (int idx = 0; idx < currentEx.options.length; idx++) ...[
                Builder(
                  builder: (context) {
                    final opt = currentEx.options[idx];
                    final isSelected = _selectedOptionIndex == idx;
                    final isCorrectOption = idx == currentEx.correctAnswerIndex;

                    Color borderColor = isDark
                        ? AppColors.slate800
                        : AppColors.slate200;
                    Color bgColor =
                        isDark ? AppColors.slate900 : Colors.white;

                    if (_hasChecked) {
                      if (isSelected) {
                        borderColor = _isAnswerCorrect
                            ? AppColors.emerald500
                            : AppColors.rose500;
                        bgColor = _isAnswerCorrect
                            ? AppColors.emerald500.withValues(alpha: 0.15)
                            : AppColors.rose500.withValues(alpha: 0.15);
                      } else if (isCorrectOption) {
                        borderColor = AppColors.emerald500;
                        bgColor =
                            AppColors.emerald500.withValues(alpha: 0.1);
                      }
                    } else if (isSelected) {
                      borderColor = primaryColor;
                      bgColor = primaryColor.withValues(alpha: 0.08);
                    }

                    return Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: InkWell(
                        onTap: () => _onOptionSelected(idx),
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: borderColor, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28.r,
                                height: 28.r,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? primaryColor
                                      : (isDark
                                          ? AppColors.slate800
                                          : AppColors.slate100),
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + idx),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                              ? AppColors.slate300
                                              : AppColors.slate600),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  opt,
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
                              if (_hasChecked && isSelected) ...[
                                Icon(
                                  _isAnswerCorrect
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  color: _isAnswerCorrect
                                      ? AppColors.emerald500
                                      : AppColors.rose500,
                                  size: 20.r,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ] else ...[
              // Typing Exercise
              Container(
                padding: EdgeInsets.all(16.r),
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
                      'Type the categorical term below:',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.slate300 : AppColors.slate700,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    TextField(
                      controller: _textController,
                      enabled: !_hasChecked,
                      onChanged: (_) => setState(() {}),
                      textCapitalization: TextCapitalization.characters,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. BOILING',
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.slate500
                              : AppColors.slate400,
                          fontSize: 14.sp,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.slate950
                            : AppColors.slate50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.slate800
                                : AppColors.slate300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: primaryColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 16.h),

            // Feedback Card
            if (_hasChecked && _feedbackText != null) ...[
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: _isAnswerCorrect
                      ? AppColors.emerald500.withValues(
                          alpha: isDark ? 0.15 : 0.08,
                        )
                      : AppColors.rose500.withValues(
                          alpha: isDark ? 0.15 : 0.08,
                        ),
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
                    Icon(
                      _isAnswerCorrect
                          ? Icons.check_circle_outline_rounded
                          : Icons.error_outline_rounded,
                      color: _isAnswerCorrect
                          ? AppColors.emerald500
                          : AppColors.rose500,
                      size: 20.r,
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
                              ? (isDark
                                  ? AppColors.emerald400
                                  : AppColors.emerald950)
                              : (isDark
                                  ? AppColors.rose500
                                  : AppColors.red900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
            ],

            // Action Button
            if (!_hasChecked)
              ElevatedButton(
                onPressed: (currentEx.interactionType == 'choice'
                        ? _selectedOptionIndex != null
                        : _textController.text.trim().isNotEmpty)
                    ? _checkAnswer
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark
                      ? AppColors.slate800
                      : AppColors.slate300,
                  disabledForegroundColor: isDark
                      ? AppColors.slate600
                      : AppColors.slate500,
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
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentExerciseIndex < _exercises.length - 1
                          ? 'Next Exercise'
                          : 'Enter Mastery Arena 🏆',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
