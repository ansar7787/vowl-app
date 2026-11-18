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

/// Data model representing a clause connector practice exercise.
class ClauseConnectorPracticeQuest {
  final String id;
  final int level;
  final String instruction;
  final String sentence;
  final String sentenceWithBlank;
  final String completedSentence;
  final List<String> options;
  final String correctAnswer;
  final int correctAnswerIndex;
  final String hint;
  final String explanation;
  final String grammarRule;
  final String connectorCategory;

  const ClauseConnectorPracticeQuest({
    required this.id,
    required this.level,
    required this.instruction,
    required this.sentence,
    required this.sentenceWithBlank,
    required this.completedSentence,
    required this.options,
    required this.correctAnswer,
    required this.correctAnswerIndex,
    required this.hint,
    required this.explanation,
    required this.grammarRule,
    required this.connectorCategory,
  });

  factory ClauseConnectorPracticeQuest.fromJson(Map<String, dynamic> json) {
    final sentenceWithBlank = json['sentenceWithBlank'] as String? ??
        (json['sentence'] as String? ?? (json['question'] as String? ?? ''));
    final correctAns = json['correctAnswer'] as String? ?? 'and';
    final completed = json['completedSentence'] as String? ??
        sentenceWithBlank.replaceFirst('____', correctAns).replaceFirst('___', correctAns);

    return ClauseConnectorPracticeQuest(
      id: json['id'] as String? ?? 'cc_practice_default',
      level: json['level'] as int? ?? 1,
      instruction: json['instruction'] as String? ??
          'Select the connector that best completes the sentence.',
      sentence: sentenceWithBlank,
      sentenceWithBlank: sentenceWithBlank,
      completedSentence: completed,
      options: (json['options'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      correctAnswer: correctAns,
      correctAnswerIndex: json['correctAnswerIndex'] as int? ?? 0,
      hint: json['hint'] as String? ??
          'Identify whether the two thoughts express addition, contrast, reason, or condition.',
      explanation: json['explanation'] as String? ??
          'The chosen connector creates grammatical and logical coherence.',
      grammarRule: json['grammarRule'] as String? ?? 'Clause Connection',
      connectorCategory: json['connectorCategory'] as String? ?? 'Logical Bridge',
    );
  }
}

/// Interactive Practice Phase screen for Clause Connector: "Bridge Gym".
///
/// Features sentence analysis, connector selection, live clause bridge assembly,
/// auditory & haptic feedback, and grammatical explanation.
class ClauseConnectorPracticeScreen extends StatefulWidget {
  final int level;

  const ClauseConnectorPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<ClauseConnectorPracticeScreen> createState() =>
      _ClauseConnectorPracticeScreenState();
}

class _ClauseConnectorPracticeScreenState
    extends State<ClauseConnectorPracticeScreen> {
  List<ClauseConnectorPracticeQuest> _quests = const [
    ClauseConnectorPracticeQuest(
      id: 'FALLBACK_CC_P1',
      level: 1,
      instruction: 'Select the connector that best completes the sentence.',
      sentence: 'Maria packed her backpack ____ she put on her hiking boots.',
      sentenceWithBlank:
          'Maria packed her backpack ____ she put on her hiking boots.',
      completedSentence:
          'Maria packed her backpack and she put on her hiking boots.',
      options: ['so', 'and', 'but', 'or'],
      correctAnswer: 'and',
      correctAnswerIndex: 1,
      hint: 'Think about whether the second action simply follows the first as another step, without any surprise or cause-and-effect.',
      explanation:
          "'And' links two ordinary steps in getting ready. Putting on her boots isn't a result of packing the backpack, so 'so' doesn't fit here, and there's no contrast for 'but' or choice for 'or' - both actions just happen together.",
      grammarRule: 'Addition - and',
      connectorCategory: 'Addition',
    ),
  ];

  int _currentIndex = 0;
  bool _isLoading = true;
  String? _selectedOption;
  bool? _isCorrect;
  bool _showHint = false;

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
          'assets/curriculum/grammar/clauseConnector_practice_${startLevel}_$endLevel.json';

      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests = data['quests'] as List<dynamic>? ?? [];

      final loaded = rawQuests
          .map((q) => ClauseConnectorPracticeQuest.fromJson(
              Map<String, dynamic>.from(q as Map)))
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

  void _speakSentence(String text) {
    if (text.isEmpty) return;
    try {
      if (di.sl.isRegistered<TtsService>()) {
        di.sl<TtsService>().speak(text);
      }
    } catch (_) {}
  }

  void _selectOption(String option) {
    if (_selectedOption != null) return;

    final quest = _quests[_currentIndex];
    final isRight = option.trim().toLowerCase() ==
        quest.correctAnswer.trim().toLowerCase();

    setState(() {
      _selectedOption = option;
      _isCorrect = isRight;
    });

    try {
      if (isRight) {
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

  void _nextExercise() {
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _isCorrect = null;
        _showHint = false;
      });
    } else {
      _completePractice();
    }
  }

  void _completePractice() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'clauseConnector',
      level: widget.level,
      phase: 'practice',
    );

    final targetTest =
        '/game?category=grammar&gameType=clauseConnector&level=${widget.level}';
    context.pushReplacement(targetTest);
  }

  String _getDisplaySentence(ClauseConnectorPracticeQuest quest) {
    if (_selectedOption != null) {
      return quest.sentenceWithBlank
          .replaceFirst('____', _selectedOption!)
          .replaceFirst('___', _selectedOption!);
    }
    return quest.sentenceWithBlank;
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
    final displaySentence = _getDisplaySentence(quest);

    return PracticePhaseScaffold(
      title: 'Bridge Gym',
      gameType: 'clauseConnector',
      level: widget.level,
      currentExerciseIndex: _currentIndex,
      totalExercises: _quests.length,
      onComplete: _completePractice,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.teal500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColors.teal500.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Exercise ${_currentIndex + 1} of ${_quests.length}',
                    style: TextStyle(
                      color: AppColors.teal500,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Flexible(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.violet500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.violet500.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      quest.connectorCategory,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.violet500,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Instruction Card with Hint
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
                    Icons.call_split_rounded,
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
                      color:
                          _showHint ? AppColors.amber400 : AppColors.slate500,
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

            // Target Sentence with Blank Card
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
                              Icons.format_quote_rounded,
                              color: AppColors.teal500,
                              size: 16.r,
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                hasAnswered
                                    ? 'COMPLETED SENTENCE'
                                    : 'CONNECT THE CLAUSES',
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
                        onPressed: () => _speakSentence(displaySentence),
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
                    displaySentence,
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

            // Connector Selection Header
            Text(
              'SELECT THE OPTIMAL CONNECTOR:',
              style: TextStyle(
                color: AppColors.slate400,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 12.h),

            // Connector Options Grid / Flow
            Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: quest.options.map((option) {
                final isSelected = _selectedOption == option;
                final isTargetCorrect = option.trim().toLowerCase() ==
                    quest.correctAnswer.trim().toLowerCase();

                Color borderColor = AppColors.slate800;
                Color bgColor = AppColors.slate900;
                Color textColor = AppColors.slate200;

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
                    borderColor = AppColors.emerald500.withValues(alpha: 0.6);
                    bgColor = AppColors.emerald500.withValues(alpha: 0.1);
                    textColor = AppColors.emerald400;
                  }
                }

                return InkWell(
                  onTap: hasAnswered ? null : () => _selectOption(option),
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: borderColor, width: 1.3),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            // Explanation Card and Advance Button
            if (hasAnswered) ...[
              SizedBox(height: 20.h),
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
                                ? 'SYNTACTIC BRIDGE LOCKED!'
                                : 'LOGICAL CLASH: BEST CONNECTOR IS ${quest.correctAnswer.toUpperCase()}',
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
