import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Guided active practice screen for Phrasal Verbs: "Particle Vault Gym".
///
/// Implements particle slotting, scenario recognition, and typing gap-fill exercises
/// with instant pedagogical feedback before advancing to the high-stakes Mastery phase.
class PhrasalVerbsPracticeScreen extends StatefulWidget {
  final int level;

  const PhrasalVerbsPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<PhrasalVerbsPracticeScreen> createState() =>
      _PhrasalVerbsPracticeScreenState();
}

class _PhrasalVerbsPracticeScreenState
    extends State<PhrasalVerbsPracticeScreen> {
  List<PracticeExercise> _exercises = const [
    PracticeExercise(
      exerciseType: 'particleVaultSlot',
      interactionType: 'choice',
      question:
          "Slot the correct particle for the verb 'WAKE':\n\n\"My alarm rang at six, but I didn't wake ___ until the second alarm at seven.\"",
      options: [
        'OUT',
        'UP',
        'ON',
        'OVER',
      ],
      correctAnswerIndex: 1,
      feedbackPerOption: [
        "Not quite. 'WAKE OUT' creates an incorrect meaning here. Try again!",
        "Correct! 'WAKE UP' perfectly completes the context.",
        "Not quite. 'WAKE ON' creates an incorrect meaning here. Try again!",
        "Not quite. 'WAKE OVER' creates an incorrect meaning here. Try again!",
      ],
      hint: 'This is about becoming conscious after sleep, not getting out of bed yet.',
    ),
    PracticeExercise(
      exerciseType: 'meaningScenario',
      interactionType: 'choice',
      question:
          "Which particle transforms 'GET' into: \"Rise from a lying or sitting position, most often out of bed\"?",
      options: [
        'OVER',
        'AWAY',
        'ON',
        'UP',
      ],
      correctAnswerIndex: 3,
      feedbackPerOption: [
        "Not quite. 'GET OVER' means to recover from something.",
        "Not quite. 'GET AWAY' means to escape or take a vacation.",
        "Not quite. 'GET ON' means to board a bus or train.",
        "Correct! 'GET UP' means to physically rise out of bed.",
      ],
      hint: 'Think about physically rising and standing up.',
    ),
    PracticeExercise(
      exerciseType: 'fillGap',
      interactionType: 'typing',
      sentence:
          "It's freezing outside, so put ___ your coat before you leave the house.",
      correctAnswer: 'on',
      hint: 'Type the missing particle (2 letters).',
      feedbackIfWrong: "The missing particle for 'PUT ON' is 'on'.",
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
          'assets/curriculum/vocabulary/phrasalVerbs_practice_${startLevel}_$endLevel.json';
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
            ? "Excellent! '$expected' is the exact particle needed."
            : (currentEx.feedbackIfWrong ?? "The correct particle is '$expected'.");
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
        '/game?category=vocabulary&gameType=phrasalVerbs&level=${widget.level}';
    context.pushReplacement(target);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);
    final primaryColor = theme.primaryColor;

    final currentEx = _exercises[_currentExerciseIndex];
    final isChoice = currentEx.interactionType == 'choice';

    return PracticePhaseScaffold(
      title: 'Particle Vault Gym',
      gameType: 'phrasalVerbs',
      level: widget.level,
      currentExerciseIndex: _currentExerciseIndex,
      totalExercises: _exercises.length,
      onComplete: _finishPracticePhase,
      child: Column(
        children: [
          // Prompt & Question Body
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Exercise Type Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          isChoice
                              ? 'PARTICLE SELECTION'
                              : 'GAP-FILL RECALL',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      if (currentEx.hint != null && currentEx.hint!.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showHint = !_showHint;
                            });
                          },
                          icon: Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 16.sp,
                            color: AppColors.amber500,
                          ),
                          label: Text(
                            _showHint ? 'Hide Hint' : 'Hint',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.amber500,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Optional Hint Container
                  if (_showHint &&
                      currentEx.hint != null &&
                      currentEx.hint!.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.amber500.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.amber500.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        currentEx.hint!,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.9)
                              : AppColors.slate900,
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: 14.h),

                  // Question Card
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.slate900 : Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isDark ? AppColors.slate800 : AppColors.slate200,
                      ),
                    ),
                    child: Text(
                      isChoice
                          ? (currentEx.question ?? '')
                          : (currentEx.sentence ?? ''),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Interactive Form
                  if (isChoice) ...[
                    // Multiple Choice Options
                    ...List.generate(currentEx.options.length, (idx) {
                      final optionText = currentEx.options[idx];
                      final isSelected = _selectedOptionIndex == idx;
                      final isCorrectChoice =
                          idx == currentEx.correctAnswerIndex;

                      Color borderColor =
                          isDark ? AppColors.slate800 : AppColors.slate200;
                      Color bgColor =
                          isDark ? AppColors.slate900 : Colors.white;

                      if (_hasChecked) {
                        if (isCorrectChoice) {
                          borderColor = AppColors.emerald500;
                          bgColor = AppColors.emerald500.withValues(alpha: 0.15);
                        } else if (isSelected && !isCorrectChoice) {
                          borderColor = AppColors.rose500;
                          bgColor = AppColors.rose500.withValues(alpha: 0.15);
                        }
                      } else if (isSelected) {
                        borderColor = primaryColor;
                        bgColor = primaryColor.withValues(alpha: 0.1);
                      }

                      return Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: InkWell(
                          onTap: () => _onOptionSelected(idx),
                          borderRadius: BorderRadius.circular(14.r),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 14.h),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: borderColor,
                                width: isSelected || (_hasChecked && isCorrectChoice)
                                    ? 2
                                    : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28.w,
                                  height: 28.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? primaryColor
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? primaryColor
                                          : (isDark
                                              ? Colors.white30
                                              : Colors.black26),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: isSelected
                                      ? Icon(Icons.check,
                                          size: 16.sp, color: Colors.white)
                                      : Text(
                                          String.fromCharCode(65 + idx),
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black54,
                                          ),
                                        ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Text(
                                    optionText,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 15.sp,
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
                    // Typing Input Field
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.slate900 : Colors.white,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: _hasChecked
                              ? (_isAnswerCorrect
                                  ? AppColors.emerald500
                                  : AppColors.rose500)
                              : primaryColor.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        enabled: !_hasChecked,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _checkAnswer(),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.slate900,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type particle here...',
                          hintStyle: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.sp,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          border: InputBorder.none,
                          suffixIcon: Icon(
                            Icons.keyboard_alt_rounded,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Feedback Box after Checking
                  if (_hasChecked && _feedbackText != null) ...[
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: _isAnswerCorrect
                            ? AppColors.emerald500.withValues(alpha: 0.12)
                            : AppColors.rose500.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: _isAnswerCorrect
                              ? AppColors.emerald500
                              : AppColors.rose500,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _isAnswerCorrect
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: _isAnswerCorrect
                                ? AppColors.emerald500
                                : AppColors.rose500,
                            size: 20.sp,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              _feedbackText!,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
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
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate900 : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: !_hasChecked
                      ? ((isChoice && _selectedOptionIndex != null) ||
                              (!isChoice &&
                                  _textController.text.trim().isNotEmpty)
                          ? _checkAnswer
                          : null)
                      : _nextExercise,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasChecked
                        ? (_isAnswerCorrect
                            ? AppColors.emerald500
                            : primaryColor)
                        : primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark
                        ? Colors.white12
                        : Colors.black.withValues(alpha: 0.12),
                    disabledForegroundColor: isDark
                        ? Colors.white38
                        : Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    !_hasChecked
                        ? 'Check Particle'
                        : (_currentExerciseIndex < _exercises.length - 1
                            ? 'Next Exercise'
                            : 'Enter Vault Mastery Arena 🏆'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
