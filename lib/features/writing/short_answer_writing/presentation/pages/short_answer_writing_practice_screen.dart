import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive Practice Phase screen for Short Answer Writing ("Structured Mini-Response Gym").
///
/// Prompts learners to evaluate situational replies and identify the response that
/// cleanly integrates all required keywords with natural conversational syntax.
class ShortAnswerWritingPracticeScreen extends StatefulWidget {
  final int level;

  const ShortAnswerWritingPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<ShortAnswerWritingPracticeScreen> createState() =>
      _ShortAnswerWritingPracticeScreenState();
}

class _ShortAnswerWritingPracticeScreenState
    extends State<ShortAnswerWritingPracticeScreen> {
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
        'assets/curriculum/writing/shortAnswerWriting_practice_${startLevel}_$endLevel.json';

    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final levelQuests = rawQuests.where((q) {
        final id = q['id'] as String? ?? '';
        final match = RegExp(r'_L(\d+)_').firstMatch(id);
        if (match != null) {
          return int.parse(match.group(1)!) == widget.level;
        }
        return false;
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
          'id': 'WRT_SHORTANSWERWRITING_PRAC_FALLBACK_1',
          'instruction': 'SELECT THE RESPONSE WITH ALL REQUIRED KEYWORDS',
          'prompt':
              'A new classmate smiles and asks who you are. Introduce yourself in one sentence.',
          'options': ['hello', 'from', 'name'],
          'candidates': [
            'Hello, my name is Rita and I am from Brazil.',
            'My name is Rita and I live in Brazil.',
            'Hello everyone here today.',
            'Because I am arriving from the school bus.',
          ],
          'correctCandidateIndex': 0,
          'sampleAnswer': 'Hello, my name is Rita and I am from Brazil.',
          'hint': 'Check that every target keyword (hello, from, name) appears in the sentence.',
          'explanation':
              'Only the first option incorporates all three keywords ("hello", "name", "from") in a grammatically coherent introduction.',
        },
        {
          'id': 'WRT_SHORTANSWERWRITING_PRAC_FALLBACK_2',
          'instruction': 'SELECT THE RESPONSE WITH ALL REQUIRED KEYWORDS',
          'prompt':
              'You are at the lost-and-found desk. Describe your bag so the clerk can find it.',
          'options': ['color', 'small', 'bag'],
          'candidates': [
            'My bag is small, and the color is dark green.',
            'The backpack is tiny and green.',
            'A very dark suitcase on the counter.',
            'Because I lost my keys at the desk.',
          ],
          'correctCandidateIndex': 0,
          'sampleAnswer': 'My bag is small, and the color is dark green.',
          'hint': 'Ensure "bag", "small", and "color" are all present.',
          'explanation':
              'The selected answer integrates "bag", "small", and "color" to provide actionable details to the clerk.',
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
      if (_questIndex < _quests.length - 1) {
        setState(() {
          _questIndex++;
          _resetForCurrentQuest();
        });
      } else {
        PhaseProgressRecorder.recordPhaseCompleted(
          context,
          gameType: 'shortAnswerWriting',
          level: widget.level,
          phase: 'practice',
        );
        context.pushReplacement(
          '/game?category=writing&gameType=shortAnswerWriting&level=${widget.level}',
        );
      }
      return;
    }

    if (_selectedOptionIndex == null) return;

    final quest = _quests[_questIndex];
    final correctIndex = quest['correctCandidateIndex'] as int? ?? 0;
    final isCorrect = _selectedOptionIndex == correctIndex;

    setState(() {
      _isChecked = true;
      _isCorrect = isCorrect;
    });
  }

  void _showHint() {
    final quest = _quests[_questIndex];
    final hint = quest['hint'] as String? ??
        'Ensure all required keywords appear in a complete sentence.';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: isDark ? AppColors.slate900 : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    color: AppColors.amber500,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Response Hint',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.slate100 : AppColors.slate900,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                hint,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.slate300 : AppColors.slate700,
                  height: 1.45,
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indigo500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text(
                    'Got It',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<String> _resolveCandidates(Map<String, dynamic> quest) {
    final rawCandidates = quest['candidates'] as List<dynamic>?;
    if (rawCandidates != null && rawCandidates.isNotEmpty) {
      return rawCandidates.map((e) => e.toString()).toList();
    }
    final sampleAnswer = quest['sampleAnswer'] as String? ?? 'A valid concise response.';
    return [
      sampleAnswer,
      'A response omitting the required vocabulary tokens.',
      'Because the sentence structure was left unresolved.',
      'An arbitrary fragment without predicate alignment.',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quest = _quests[_questIndex];
    final prompt = quest['prompt'] as String? ?? '';
    final options = (quest['options'] as List<dynamic>? ?? []).cast<String>();
    final candidates = _resolveCandidates(quest);
    final correctIndex = quest['correctCandidateIndex'] as int? ?? 0;
    final explanation = quest['explanation'] as String? ?? '';

    String buttonLabel = 'Check Answer';
    if (_isChecked) {
      buttonLabel = _questIndex == _quests.length - 1
          ? 'Enter Mastery Game'
          : 'Next Exercise';
    }

    return PracticePhaseScaffold(
      title: 'Structured Mini-Response Gym',
      gameType: 'shortAnswerWriting',
      level: widget.level,
      currentExerciseIndex: _questIndex,
      totalExercises: _quests.length,
      actionLabel: buttonLabel,
      isActionEnabled: _selectedOptionIndex != null || _isChecked,
      onComplete: _onCheck,
      onHint: _showHint,
      isHintAvailable: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Prompt Card
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
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 16.sp,
                        color: AppColors.indigo500,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'SITUATION PROMPT',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo500,
                            letterSpacing: 0.8,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    prompt,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.slate100 : AppColors.slate900,
                      height: 1.4,
                    ),
                  ),
                  if (options.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6.w,
                      runSpacing: 6.h,
                      children: [
                        Text(
                          'Must include: ',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.slate400 : AppColors.slate600,
                          ),
                        ),
                        ...options.map(
                          (w) => Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: AppColors.indigo500.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              w.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.indigo500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Prompt Question
            Text(
              'SELECT THE COMPLETE AND NATURAL REPLY:',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.slate400 : AppColors.slate600,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 10.h),

            // Options List
            ...List.generate(candidates.length, (idx) {
              final candidateText = candidates[idx];
              final isSelected = _selectedOptionIndex == idx;

              Color borderColor = isDark ? AppColors.slate800 : AppColors.slate200;
              Color bgColor = isDark ? AppColors.slate900 : Colors.white;

              if (_isChecked) {
                if (idx == correctIndex) {
                  borderColor = AppColors.emerald500;
                  bgColor = AppColors.emerald500.withValues(alpha: 0.12);
                } else if (isSelected && !_isCorrect) {
                  borderColor = AppColors.rose500;
                  bgColor = AppColors.rose500.withValues(alpha: 0.12);
                }
              } else if (isSelected) {
                borderColor = AppColors.indigo500;
                bgColor = AppColors.indigo500.withValues(alpha: 0.08);
              }

              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: GestureDetector(
                  onTap: () => _onOptionSelected(idx),
                  child: Container(
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: borderColor,
                        width: isSelected || (_isChecked && idx == correctIndex)
                            ? 2.0
                            : 1.0,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22.r,
                          height: 22.r,
                          margin: EdgeInsets.only(top: 2.h, right: 10.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? (_isChecked
                                    ? (idx == correctIndex
                                        ? AppColors.emerald500
                                        : AppColors.rose500)
                                    : AppColors.indigo500)
                                : (_isChecked && idx == correctIndex
                                    ? AppColors.emerald500
                                    : Colors.transparent),
                            border: Border.all(
                              color: isSelected || (_isChecked && idx == correctIndex)
                                  ? Colors.transparent
                                  : (isDark
                                      ? AppColors.slate700
                                      : AppColors.slate300),
                              width: 1.5,
                            ),
                          ),
                          child: (isSelected || (_isChecked && idx == correctIndex))
                              ? Icon(
                                  _isChecked
                                      ? (idx == correctIndex
                                          ? Icons.check
                                          : Icons.close)
                                      : Icons.circle,
                                  size: 13.sp,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        Expanded(
                          child: Text(
                            candidateText,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isDark ? AppColors.slate100 : AppColors.slate900,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Feedback Card
            if (_isChecked) ...[
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: _isCorrect
                      ? AppColors.emerald500.withValues(alpha: 0.12)
                      : AppColors.rose500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: _isCorrect
                        ? AppColors.emerald500.withValues(alpha: 0.4)
                        : AppColors.rose500.withValues(alpha: 0.4),
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
                              : Icons.info_rounded,
                          color: _isCorrect
                              ? AppColors.emerald500
                              : AppColors.rose500,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _isCorrect ? 'Well Answered!' : 'Incomplete Keywords',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: _isCorrect
                                  ? AppColors.emerald500
                                  : AppColors.rose500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.slate200 : AppColors.slate800,
                        height: 1.4,
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
