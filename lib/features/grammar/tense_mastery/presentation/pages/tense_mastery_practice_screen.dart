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

/// Data model representing a tense mastery practice exercise.
class TenseMasteryPracticeQuest {
  final String id;
  final int level;
  final String instruction;
  final String sentence;
  final String timelinePosition;
  final List<String> options;
  final String correctAnswer;
  final String hint;
  final String explanation;
  final String grammarRule;

  const TenseMasteryPracticeQuest({
    required this.id,
    required this.level,
    required this.instruction,
    required this.sentence,
    required this.timelinePosition,
    required this.options,
    required this.correctAnswer,
    required this.hint,
    required this.explanation,
    required this.grammarRule,
  });

  factory TenseMasteryPracticeQuest.fromJson(Map<String, dynamic> json) {
    final timelinePos = json['timelinePosition'] as String? ??
        (json['correctAnswer'] as String? ?? 'Present');
    final rule = json['grammarRule'] as String? ?? '$timelinePos Tense';

    return TenseMasteryPracticeQuest(
      id: json['id'] as String? ?? 'tm_practice_default',
      level: json['level'] as int? ?? 1,
      instruction: json['instruction'] as String? ??
          'Select the timeline position for the sentence.',
      sentence: json['sentence'] as String? ?? '',
      timelinePosition: timelinePos,
      options: (json['options'] as List<dynamic>? ?? ['Past', 'Present', 'Future'])
          .map((e) => e.toString())
          .toList(),
      correctAnswer: json['correctAnswer'] as String? ?? timelinePos,
      hint: json['hint'] as String? ?? 'Look for temporal clues in the sentence.',
      explanation: json['explanation'] as String? ??
          'The sentence corresponds to the $timelinePos tense.',
      grammarRule: rule,
    );
  }
}

/// Interactive Practice Phase screen for Tense Mastery: "Timeline Dropper Gym".
///
/// Features target sentence analysis, timeline node selection (Past | Present | Future),
/// instant auditory & haptic feedback, and deep temporal explanations.
class TenseMasteryPracticeScreen extends StatefulWidget {
  final int level;

  const TenseMasteryPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<TenseMasteryPracticeScreen> createState() =>
      _TenseMasteryPracticeScreenState();
}

class _TenseMasteryPracticeScreenState extends State<TenseMasteryPracticeScreen> {
  List<TenseMasteryPracticeQuest> _quests = const [
    TenseMasteryPracticeQuest(
      id: 'FALLBACK_TM_P1',
      level: 1,
      instruction: 'Select the timeline position for the sentence.',
      sentence: 'The barista wiped down the espresso machine before closing last night.',
      timelinePosition: 'Past',
      options: ['Past', 'Present', 'Future'],
      correctAnswer: 'Past',
      hint: 'This cleaning happened at a specific moment that has already come and gone.',
      explanation:
          'Wiped is the simple past form of wipe. Last night marks a single completed action, not a routine.',
      grammarRule: 'Simple Past Tense',
    ),
    TenseMasteryPracticeQuest(
      id: 'FALLBACK_TM_P2',
      level: 1,
      instruction: 'Select the timeline position for the sentence.',
      sentence: 'Every morning, the barista opens the shop and grinds fresh coffee beans.',
      timelinePosition: 'Present',
      options: ['Past', 'Present', 'Future'],
      correctAnswer: 'Present',
      hint: "This isn't a one-time event — it happens again and again.",
      explanation:
          'Opens and grinds are simple present forms describing a daily routine rather than a single moment.',
      grammarRule: 'Simple Present Tense',
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
          'assets/curriculum/grammar/tenseMastery_practice_${startLevel}_$endLevel.json';

      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests = data['quests'] as List<dynamic>? ?? [];

      final loaded = rawQuests
          .map((q) =>
              TenseMasteryPracticeQuest.fromJson(Map<String, dynamic>.from(q as Map)))
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

  void _onOptionSelected(String option) {
    if (_selectedOption != null) return; // Answer locked once chosen

    final quest = _quests[_currentIndex];
    final isCorrect =
        option.toLowerCase() == quest.correctAnswer.toLowerCase();

    setState(() {
      _selectedOption = option;
      _isCorrect = isCorrect;
    });

    try {
      if (isCorrect) {
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

  void _speakSentence(String text) {
    if (text.isEmpty) return;
    try {
      if (di.sl.isRegistered<TtsService>()) {
        di.sl<TtsService>().speak(text);
      }
    } catch (_) {}
  }

  void _onComplete() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'tenseMastery',
      level: widget.level,
      phase: 'practice',
    );

    final targetTest =
        '/game?category=grammar&gameType=tenseMastery&level=${widget.level}';
    context.pushReplacement(targetTest);
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
      _onComplete();
    }
  }

  Color _getNodeColor(String option) {
    switch (option.toLowerCase()) {
      case 'past':
        return AppColors.amber500;
      case 'future':
        return AppColors.violet500;
      case 'present':
      default:
        return AppColors.teal500;
    }
  }

  String _getNodeEmoji(String option) {
    switch (option.toLowerCase()) {
      case 'past':
        return '⏮️';
      case 'future':
        return '⏭️';
      case 'present':
      default:
        return '▶️';
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
    final hasAnswered = _selectedOption != null;

    return PracticePhaseScaffold(
      title: 'TENSE MASTERY GYM',
      gameType: 'tenseMastery',
      level: widget.level,
      currentExerciseIndex: _currentIndex,
      totalExercises: _quests.length,
      onComplete: _onComplete,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Rule badge & Exercise counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: AppColors.teal500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: AppColors.teal500.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('⏱️', style: TextStyle(fontSize: 14.sp)),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            quest.grammarRule.toUpperCase(),
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
                  ),
                ),
                Text(
                  'Exercise ${_currentIndex + 1} of ${_quests.length}',
                  style: TextStyle(
                    color: AppColors.slate500,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Instruction Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.slate800),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timeline_rounded,
                    color: AppColors.teal500,
                    size: 20.r,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      quest.instruction,
                      style: TextStyle(
                        color: AppColors.slate200,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showHint = !_showHint;
                      });
                    },
                    icon: Icon(
                      Icons.lightbulb_outline_rounded,
                      color: _showHint ? AppColors.amber400 : AppColors.slate500,
                      size: 20.r,
                    ),
                    tooltip: 'Hint',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Hint Drawer (if active)
            if (_showHint) ...[
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.amber500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.amber500.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Text('💡', style: TextStyle(fontSize: 14.sp)),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        quest.hint,
                        style: TextStyle(
                          color: AppColors.amber400,
                          fontSize: 12.sp,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
            ],

            // Target Sentence Card
            Container(
              padding: EdgeInsets.all(18.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: hasAnswered
                      ? (_isCorrect! ? AppColors.emerald500 : AppColors.rose500)
                      : AppColors.slate800,
                  width: hasAnswered ? 1.5 : 1.0,
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
                              Icons.timer_outlined,
                              color: AppColors.teal500,
                              size: 16.r,
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                'TARGET SENTENCE',
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
                      ),
                      IconButton(
                        onPressed: () => _speakSentence(quest.sentence),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.cyan400,
                          size: 20.r,
                        ),
                        tooltip: 'Listen to sentence',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    quest.sentence,
                    style: TextStyle(
                      color: AppColors.slate100,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Timeline Option Nodes
            Text(
              'WHERE DOES THIS OCCUR?',
              style: TextStyle(
                color: AppColors.slate400,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 12.h),

            Row(
              children: quest.options.map((option) {
                final isSelected = _selectedOption == option;
                final isTargetCorrect =
                    option.toLowerCase() == quest.correctAnswer.toLowerCase();
                final nodeColor = _getNodeColor(option);
                final emoji = _getNodeEmoji(option);

                Color borderColor = AppColors.slate800;
                Color bgColor = AppColors.slate900;
                Color textColor = AppColors.slate300;

                if (hasAnswered) {
                  if (isSelected) {
                    if (_isCorrect!) {
                      borderColor = AppColors.emerald500;
                      bgColor = AppColors.emerald500.withValues(alpha: 0.2);
                      textColor = AppColors.emerald400;
                    } else {
                      borderColor = AppColors.rose500;
                      bgColor = AppColors.rose500.withValues(alpha: 0.2);
                      textColor = AppColors.rose500;
                    }
                  } else if (isTargetCorrect) {
                    borderColor = AppColors.emerald500;
                    bgColor = AppColors.emerald500.withValues(alpha: 0.1);
                    textColor = AppColors.emerald400;
                  }
                } else if (isSelected) {
                  borderColor = nodeColor;
                  bgColor = nodeColor.withValues(alpha: 0.15);
                  textColor = nodeColor;
                }

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: InkWell(
                      onTap: hasAnswered ? null : () => _onOptionSelected(option),
                      borderRadius: BorderRadius.circular(14.r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: borderColor, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Text(emoji, style: TextStyle(fontSize: 22.sp)),
                            SizedBox(height: 6.h),
                            Text(
                              option.toUpperCase(),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 18.h),

            // Feedback Card (after answer)
            if (hasAnswered) ...[
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: _isCorrect!
                      ? AppColors.emerald500.withValues(alpha: 0.1)
                      : AppColors.rose500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: _isCorrect!
                        ? AppColors.emerald500.withValues(alpha: 0.3)
                        : AppColors.rose500.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isCorrect!
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: _isCorrect!
                              ? AppColors.emerald400
                              : AppColors.rose500,
                          size: 20.r,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _isCorrect!
                                ? 'TIMELINE LOCKED IN!'
                                : 'MISALIGNED CHRONO-NODE: ${quest.correctAnswer.toUpperCase()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _isCorrect!
                                  ? AppColors.emerald400
                                  : AppColors.rose500,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      quest.explanation,
                      style: TextStyle(
                        color: AppColors.slate300,
                        fontSize: 12.sp,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // Advance Button
              ElevatedButton(
                onPressed: _nextExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isCorrect! ? AppColors.emerald500 : AppColors.teal500,
                  foregroundColor: AppColors.slate950,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _currentIndex < _quests.length - 1
                            ? 'NEXT EXERCISE'
                            : 'START MASTERY',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(Icons.arrow_forward_rounded, size: 18.r),
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
