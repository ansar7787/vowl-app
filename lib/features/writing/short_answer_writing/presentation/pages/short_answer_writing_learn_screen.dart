import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive Learn Phase screen for Short Answer Writing ("PEEL & The Concise Responder").
///
/// Teaches learners how to craft concise, single-sentence answers to situational prompts
/// while seamlessly weaving in all mandated vocabulary keywords.
class ShortAnswerWritingLearnScreen extends StatefulWidget {
  final int level;

  const ShortAnswerWritingLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<ShortAnswerWritingLearnScreen> createState() =>
      _ShortAnswerWritingLearnScreenState();
}

class _ShortAnswerWritingLearnScreenState
    extends State<ShortAnswerWritingLearnScreen> {
  int _cardIndex = 0;
  late List<Map<String, dynamic>> _quests;

  @override
  void initState() {
    super.initState();
    _quests = _fallbackQuests;
    _loadCurriculum();
  }

  Future<void> _loadCurriculum() async {
    final batchIndex = ((widget.level - 1) ~/ 10) + 1;
    final startLevel = (batchIndex - 1) * 10 + 1;
    final endLevel = batchIndex * 10;
    final assetPath =
        'assets/curriculum/writing/shortAnswerWriting_learn_${startLevel}_$endLevel.json';

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
          }
        });
      }
    } catch (_) {
      // Retain fallback quests on asset failure (e.g. test environment)
    }
  }

  List<Map<String, dynamic>> get _fallbackQuests => [
        {
          'id': 'WRT_SHORTANSWERWRITING_LEARN_FALLBACK_1',
          'instruction': 'STUDY THE PROMPT & KEYWORD INTEGRATION',
          'prompt':
              'A new classmate smiles and asks who you are. Introduce yourself in one sentence.',
          'options': ['hello', 'from', 'name'],
          'sampleAnswer': 'Hello, my name is Rita and I am from Brazil.',
          'hint':
              'Begin with a greeting, then use the fixed pattern "my name is" before your name.',
          'explanation':
              '"My name is..." and "I am from..." are standard introduction structures, linked cleanly by "and".',
        },
        {
          'id': 'WRT_SHORTANSWERWRITING_LEARN_FALLBACK_2',
          'instruction': 'STUDY THE PROMPT & KEYWORD INTEGRATION',
          'prompt':
              'You are at the lost-and-found desk. Describe your bag so the clerk can find it.',
          'options': ['color', 'small', 'bag'],
          'sampleAnswer': 'My bag is small, and the color is dark green.',
          'hint':
              'Name the object first. After "is", put the describing word, then give a second detail.',
          'explanation':
              'Combining size and color details into one sentence creates an informative, natural answer.',
        },
      ];

  void _onNext() {
    if (_cardIndex < _quests.length - 1) {
      setState(() {
        _cardIndex++;
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'shortAnswerWriting',
        level: widget.level,
        phase: 'learn',
      );
      context.pushReplacement(
        '/practice?category=writing&gameType=shortAnswerWriting&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentQuest = _quests[_cardIndex];
    final prompt = currentQuest['prompt'] as String? ?? '';
    final options = (currentQuest['options'] as List<dynamic>? ?? []).cast<String>();
    final sampleAnswer = currentQuest['sampleAnswer'] as String? ?? '';
    final explanation = currentQuest['explanation'] as String? ?? '';
    final hint = currentQuest['hint'] as String? ?? '';
    final isLastCard = _cardIndex == _quests.length - 1;

    return LearnPhaseScaffold(
      title: 'PEEL & Concise Responder',
      gameType: 'shortAnswerWriting',
      level: widget.level,
      actionLabel: isLastCard ? 'Start Structured Practice' : 'Next Situation Card',
      onComplete: _onNext,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pacing & Progress Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColors.indigo500.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 14.sp,
                        color: AppColors.indigo500,
                      ),
                      SizedBox(width: 5.w),
                      Flexible(
                        child: Text(
                          'SITUATION ${_cardIndex + 1} OF ${_quests.length}',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo500,
                            letterSpacing: 0.6,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.slate800 : AppColors.slate200,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Level ${widget.level}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.slate400 : AppColors.slate600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

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
                        Icons.record_voice_over_rounded,
                        size: 16.sp,
                        color: AppColors.indigo500,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'CONVERSATION SITUATION',
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
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Required Keywords Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : AppColors.slate50,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.stars_rounded,
                        size: 16.sp,
                        color: AppColors.amber500,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'MANDATORY KEYWORD TOKENS',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.slate300 : AppColors.slate700,
                            letterSpacing: 0.8,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: options.map((word) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: AppColors.indigo500.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          word.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.indigo500,
                            letterSpacing: 0.6,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Exemplary Concise Response Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16.sp,
                        color: AppColors.emerald500,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'MODEL CONCISE RESPONSE',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.emerald500,
                            letterSpacing: 0.8,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    '"$sampleAnswer"',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.slate100 : AppColors.slate900,
                      height: 1.45,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (explanation.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.slate300 : AppColors.slate700,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (hint.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.slate800 : AppColors.slate100,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 14.sp,
                            color: AppColors.amber500,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              hint,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.slate300 : AppColors.slate700,
                                height: 1.35,
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
          ],
        ),
      ),
    );
  }
}
