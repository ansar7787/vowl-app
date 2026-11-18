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

/// Data model representing a conditionals practice exercise.
class ConditionalsPracticeQuest {
  final String id;
  final int level;
  final String instruction;
  final String question;
  final String sentence;
  final String conditionClause;
  final String resultClause;
  final List<String> options;
  final String correctAnswer;
  final int correctAnswerIndex;
  final String hint;
  final String explanation;
  final String grammarRule;
  final dynamic conditionalType;
  final String conditionalLabel;

  const ConditionalsPracticeQuest({
    required this.id,
    required this.level,
    required this.instruction,
    required this.question,
    required this.sentence,
    required this.conditionClause,
    required this.resultClause,
    required this.options,
    required this.correctAnswer,
    required this.correctAnswerIndex,
    required this.hint,
    required this.explanation,
    required this.grammarRule,
    required this.conditionalType,
    required this.conditionalLabel,
  });

  factory ConditionalsPracticeQuest.fromJson(Map<String, dynamic> json) {
    final q = json['question'] as String? ?? 'If you touch fire,';
    final answer = json['correctAnswer'] as String? ?? 'you burn yourself.';
    final condition = json['conditionClause'] as String? ?? q;
    final result = json['resultClause'] as String? ?? answer;
    final sentence = json['sentence'] as String? ?? '$condition $result';
    final rule = json['grammarRule'] as String? ?? 'Conditionals';
    final label = json['conditionalLabel'] as String? ?? 'Zero Conditional (Fact)';

    return ConditionalsPracticeQuest(
      id: json['id'] as String? ?? 'cl_practice_default',
      level: json['level'] as int? ?? 1,
      instruction: json['instruction'] as String? ?? 'WEAVE THE CONDITION AND RESULT',
      question: q,
      sentence: sentence,
      conditionClause: condition,
      resultClause: result,
      options: (json['options'] as List<dynamic>? ?? [answer])
          .map((e) => e.toString())
          .toList(),
      correctAnswer: answer,
      correctAnswerIndex: json['correctAnswerIndex'] as int? ?? 0,
      hint: json['hint'] as String? ??
          'Match the modal and tense in the result clause with the condition.',
      explanation: json['explanation'] as String? ??
          'Conditionals connect an "if" trigger to a tense-locked consequence.',
      grammarRule: rule,
      conditionalType: json['conditionalType'],
      conditionalLabel: label,
    );
  }
}

/// Interactive Practice Phase screen for Conditionals: "Condition-Result Weaver Gym".
///
/// Features condition prompt, dynamic consequence options, auditory & haptic feedback,
/// live woven sentence preview, hint discovery, and syntactic explanation.
class ConditionalsPracticeScreen extends StatefulWidget {
  final int level;

  const ConditionalsPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<ConditionalsPracticeScreen> createState() =>
      _ConditionalsPracticeScreenState();
}

class _ConditionalsPracticeScreenState
    extends State<ConditionalsPracticeScreen> {
  List<ConditionalsPracticeQuest> _quests = const [
    ConditionalsPracticeQuest(
      id: 'FALLBACK_CL_P1',
      level: 1,
      instruction: 'COMPLETE THE LINK',
      question: 'If you touch fire,',
      sentence: 'If you touch fire, you burn yourself.',
      conditionClause: 'If you touch fire,',
      resultClause: 'you burn yourself.',
      options: [
        'you would burn yourself.',
        'you will burn yourself.',
        'you burn yourself.',
        'you would have burned yourself.',
      ],
      correctAnswer: 'you burn yourself.',
      correctAnswerIndex: 2,
      hint:
          'This is true every time, for everyone — use the zero conditional for a basic fact.',
      explanation:
          'Zero conditional: present simple + present simple, for things that are always true. Touching fire always causes a burn.',
      grammarRule: 'Zero Conditional',
      conditionalType: 0,
      conditionalLabel: 'Zero Conditional (Universal Fact)',
    ),
  ];

  int _currentIndex = 0;
  int? _selectedIndex;
  bool _isAnswered = false;
  bool _isCorrect = false;
  bool _showHint = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurriculum();
  }

  Future<void> _loadCurriculum() async {
    try {
      final batchIndex = ((widget.level - 1) ~/ 10) + 1;
      final startLevel = (batchIndex - 1) * 10 + 1;
      final endLevel = batchIndex * 10;
      final path =
          'assets/curriculum/grammar/conditionals_practice_${startLevel}_$endLevel.json';

      final content = await rootBundle.loadString(path);
      final data = jsonDecode(content) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final levelQuests = rawQuests
          .where((q) => (q['level'] as int? ?? 1) == widget.level)
          .map((q) => ConditionalsPracticeQuest.fromJson(q))
          .toList();

      if (mounted) {
        setState(() {
          if (levelQuests.isNotEmpty) {
            _quests = levelQuests;
          } else if (rawQuests.isNotEmpty) {
            _quests = rawQuests
                .map((q) => ConditionalsPracticeQuest.fromJson(q))
                .take(3)
                .toList();
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

  void _selectOption(int index) {
    if (_isAnswered) return;

    final quest = _quests[_currentIndex];
    final isCorrect = (index == quest.correctAnswerIndex) ||
        (quest.options[index].trim().toLowerCase() ==
            quest.correctAnswer.trim().toLowerCase());

    setState(() {
      _selectedIndex = index;
      _isAnswered = true;
      _isCorrect = isCorrect;
    });

    if (isCorrect) {
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playCorrect();
      }
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().success();
      }
    } else {
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playWrong();
      }
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().error();
      }
    }
  }

  void _nextExercise() {
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
        _isAnswered = false;
        _isCorrect = false;
        _showHint = false;
      });
    } else {
      _completePractice();
    }
  }

  Future<void> _completePractice() async {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'conditionals',
      level: widget.level,
      phase: 'practice',
    );

    final targetTest =
        '/game?category=grammar&gameType=conditionals&level=${widget.level}';
    context.pushReplacement(targetTest);
  }

  void _playTts(String text) {
    if (di.sl.isRegistered<TtsService>()) {
      di.sl<TtsService>().speak(text);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PracticePhaseScaffold(
      title: 'Condition-Result Weaver Gym',
      gameType: 'conditionals',
      level: widget.level,
      currentExerciseIndex: _currentIndex,
      totalExercises: _quests.length,
      onComplete: _completePractice,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress bar & rule chip
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
                      quest.grammarRule,
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

            // Top Badge: Instruction & Timeline Label
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.violet500.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppColors.violet500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.fitness_center_rounded,
                      color: AppColors.violet500,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quest.instruction,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          quest.conditionalLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.teal500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showHint = !_showHint;
                      });
                    },
                    icon: Icon(
                      _showHint
                          ? Icons.lightbulb_rounded
                          : Icons.lightbulb_outline_rounded,
                      color: Colors.amber,
                      size: 22.sp,
                    ),
                    tooltip: 'Toggle Hint',
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Hint Drawer (if active)
            if (_showHint) ...[
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates_rounded,
                      color: Colors.amber,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        quest.hint,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.amber.shade200,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
            ],

            // Question Card: Condition Clause Prompt
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1E38), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: AppColors.violet500.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.violet500.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'CONDITION TRIGGER',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.teal500,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _playTts(quest.question),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.teal500,
                          size: 22.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    quest.question,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Live Woven Preview Badge (Shown after answered)
            if (_isAnswered) ...[
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 10.h,
                ),
                decoration: BoxDecoration(
                  color: _isCorrect
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: _isCorrect ? Colors.green : Colors.redAccent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: _isCorrect ? Colors.green : Colors.redAccent,
                      size: 20.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        _isCorrect
                            ? 'TIMELINE WOVEN: "${quest.correctAnswer}"'
                            : 'FRACTURED TIMELINE: Correct is "${quest.correctAnswer}"',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: _isCorrect ? Colors.greenAccent : Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ],

            // 4 Consequence Result Options
            Column(
              children: [
                for (int i = 0; i < quest.options.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: _buildOptionButton(
                      optionIndex: i,
                      quest: quest,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 10.h),

            // Explanation & Continuation Card (After answering)
            if (_isAnswered) ...[
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.psychology_rounded,
                          color: Colors.blueAccent,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'TIMELINE HARMONY RATIONALE',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      quest.explanation,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Advance Button
              ElevatedButton(
                onPressed: _nextExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.violet500,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentIndex < _quests.length - 1
                          ? 'NEXT EXERCISE'
                          : 'COMPLETE PRACTICE',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18.sp,
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

  Widget _buildOptionButton({
    required int optionIndex,
    required ConditionalsPracticeQuest quest,
  }) {
    final option = quest.options[optionIndex];
    final isSelected = _selectedIndex == optionIndex;
    final isCorrectOption = (optionIndex == quest.correctAnswerIndex) ||
        (option.trim().toLowerCase() == quest.correctAnswer.trim().toLowerCase());

    Color borderColor = AppColors.violet500.withValues(alpha: 0.3);
    Color backgroundColor = const Color(0xFF1E293B);
    Color textColor = Colors.white;

    if (_isAnswered) {
      if (isCorrectOption) {
        borderColor = Colors.green;
        backgroundColor = Colors.green.withValues(alpha: 0.2);
        textColor = Colors.greenAccent;
      } else if (isSelected) {
        borderColor = Colors.redAccent;
        backgroundColor = Colors.red.withValues(alpha: 0.2);
        textColor = Colors.redAccent;
      } else {
        textColor = Colors.white38;
      }
    } else if (isSelected) {
      borderColor = AppColors.violet500;
      backgroundColor = AppColors.violet500.withValues(alpha: 0.2);
    }

    return InkWell(
      onTap: () => _selectOption(optionIndex),
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: borderColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Text(
                String.fromCharCode(65 + optionIndex),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                option,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
