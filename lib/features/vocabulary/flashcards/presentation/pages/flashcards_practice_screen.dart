import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_practice_choice_card.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_practice_typing_card.dart';

/// Guided active recall & context practice screen for Flashcards.
///
/// Features cyber-cloze shard assembly exercises and choice battle crystals
/// with instant corrective feedback before entering the timed Mastery phase.
class FlashcardsPracticeScreen extends StatefulWidget {
  final int level;

  const FlashcardsPracticeScreen({super.key, required this.level});

  @override
  State<FlashcardsPracticeScreen> createState() =>
      _FlashcardsPracticeScreenState();
}

class _FlashcardsPracticeScreenState extends State<FlashcardsPracticeScreen> {
  List<PracticeExercise> _exercises = const [
    PracticeExercise(
      exerciseType: 'fillGap',
      interactionType: 'typing',
      sentence: '_____, welcome to the team!',
      correctAnswer: 'Hello',
      hint: 'A friendly greeting.',
      feedbackIfWrong: 'Say Hello to greet a teammate.',
    ),
  ];
  bool _isLoading = false;
  int _currentExerciseIndex = 0;

  // Exercise interaction state
  final TextEditingController _textController = TextEditingController();
  int? _selectedOptionIndex;
  bool _hasChecked = false;
  bool _isAnswerCorrect = false;
  String? _feedbackText;
  bool _showHint = false;
  int _shakeCount = 0;

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
          'assets/curriculum/vocabulary/flashcards_practice_${startLevel}_$endLevel.json';
      final jsonStr = await rootBundle.loadString(path);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final batch = PhasedQuestBatch.fromJson(data);

      final levelQuests = batch.quests
          .where((q) => q.level == widget.level)
          .toList();
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
              exerciseType: 'fillGap',
              interactionType: 'typing',
              sentence: '_____, welcome to the team!',
              correctAnswer: 'Hello',
              hint: 'A friendly greeting.',
              feedbackIfWrong: 'Say Hello to greet a teammate.',
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
      final userText = _textController.text.trim();
      if (userText.isEmpty) return;

      final isCorrect =
          userText.toLowerCase() ==
          (exercise.correctAnswer ?? '').toLowerCase();
      setState(() {
        _hasChecked = true;
        _isAnswerCorrect = isCorrect;
        if (!isCorrect) _shakeCount++;
        _feedbackText = isCorrect
            ? 'Spot on! Correct answer.'
            : (exercise.feedbackIfWrong ??
                  'Correct answer: "${exercise.correctAnswer}"');
      });
      if (di.sl.isRegistered<HapticService>()) {
        if (isCorrect) {
          di.sl<HapticService>().success();
        } else {
          di.sl<HapticService>().error();
        }
      }
    } else {
      if (_selectedOptionIndex == null) return;
      final isCorrect = _selectedOptionIndex == exercise.correctAnswerIndex;
      String? perOptionFeedback;
      if (_selectedOptionIndex! < exercise.feedbackPerOption.length) {
        perOptionFeedback = exercise.feedbackPerOption[_selectedOptionIndex!];
      }

      setState(() {
        _hasChecked = true;
        _isAnswerCorrect = isCorrect;
        if (!isCorrect) _shakeCount++;
        _feedbackText =
            perOptionFeedback ??
            (isCorrect ? 'Correct choice!' : 'That choice is not optimal.');
      });
      if (di.sl.isRegistered<HapticService>()) {
        if (isCorrect) {
          di.sl<HapticService>().success();
        } else {
          di.sl<HapticService>().error();
        }
      }
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
        _hasChecked = false;
        _isAnswerCorrect = false;
        _selectedOptionIndex = null;
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
      gameType: 'flashcards',
      level: widget.level,
      phase: 'practice',
    );
    final target =
        '/game?category=vocabulary&gameType=flashcards&level=${widget.level}';
    try {
      context.pushReplacement(target);
    } catch (_) {
      // Handled gracefully in tests where GoRouter is omitted
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.slate950 : AppColors.slate50,
        body: const SafeArea(
          child: GameShimmerLoading(primaryColor: Colors.amber),
        ),
      );
    }

    final exercise = _exercises.isNotEmpty
        ? _exercises[_currentExerciseIndex]
        : null;
    if (exercise == null) {
      return PracticePhaseScaffold(
        title: 'Practice Gym',
        gameType: 'flashcards',
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

    return PracticePhaseScaffold(
      title: 'Exercise ${_currentExerciseIndex + 1} of ${_exercises.length}',
      gameType: 'flashcards',
      level: widget.level,
      currentExerciseIndex: _currentExerciseIndex,
      totalExercises: _exercises.length,
      actionLabel: actionLabel,
      isHintAvailable: exercise.hint != null && !_showHint,
      onHint: () => setState(() => _showHint = true),
      onComplete: _advanceOrFinish,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Exercise Header Tag
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                exercise.interactionType == 'typing'
                    ? '⚡ ACTIVE RECALL • SHARD ASSEMBLY'
                    : '🎯 CONTEXT JUDGMENT',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.amber.shade300 : Colors.amber.shade800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Exercise Body (Typing Shard Assembly or Crystal Choice)
            if (exercise.interactionType == 'typing')
              FlashcardPracticeTypingCard(
                exercise: exercise,
                textController: _textController,
                hasChecked: _hasChecked,
                isAnswerCorrect: _isAnswerCorrect,
                shakeCount: _shakeCount,
                isDark: isDark,
                onCheck: _checkCurrentAnswer,
              )
            else
              FlashcardPracticeChoiceCard(
                exercise: exercise,
                selectedOptionIndex: _selectedOptionIndex,
                hasChecked: _hasChecked,
                isAnswerCorrect: _isAnswerCorrect,
                isDark: isDark,
                onSelectOption: (idx) {
                  setState(() => _selectedOptionIndex = idx);
                },
              ),

            // Hint Drawer
            if (_showHint && exercise.hint != null) ...[
              SizedBox(height: 14.h),
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Text('💡', style: TextStyle(fontSize: 16.sp)),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        exercise.hint!,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          color: isDark
                              ? Colors.lightBlue.shade200
                              : Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Feedback Card
            if (_hasChecked && _feedbackText != null) ...[
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: _isAnswerCorrect
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: _isAnswerCorrect
                        ? Colors.green.withValues(alpha: 0.4)
                        : Colors.orange.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isAnswerCorrect ? '🎉' : '💡',
                      style: TextStyle(fontSize: 22.sp),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isAnswerCorrect ? 'CORRECT' : 'COACHING TIP',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              color: _isAnswerCorrect
                                  ? Colors.green
                                  : Colors.orange.shade800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _feedbackText!,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.slate200
                                  : AppColors.slate900,
                              height: 1.4,
                            ),
                          ),
                        ],
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
}
