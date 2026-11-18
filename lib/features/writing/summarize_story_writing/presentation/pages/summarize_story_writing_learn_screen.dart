import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive Learn Phase screen for Summarize Story Writing ("Narrative Architecture & Summary Builder").
///
/// Demonstrates how to isolate the essential cause-and-effect narrative chain:
/// Catalyst → Turning Point → Final Resolution, separating central story drivers from background noise.
class SummarizeStoryWritingLearnScreen extends StatefulWidget {
  final int level;

  const SummarizeStoryWritingLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<SummarizeStoryWritingLearnScreen> createState() =>
      _SummarizeStoryWritingLearnScreenState();
}

class _SummarizeStoryWritingLearnScreenState
    extends State<SummarizeStoryWritingLearnScreen> {
  int _cardIndex = 0;
  late List<Map<String, dynamic>> _cards;

  @override
  void initState() {
    super.initState();
    _cards = _fallbackCards;
    _loadCurriculum();
  }

  Future<void> _loadCurriculum() async {
    final batchIndex = ((widget.level - 1) ~/ 10) + 1;
    final startLevel = (batchIndex - 1) * 10 + 1;
    final endLevel = batchIndex * 10;
    final assetPath =
        'assets/curriculum/writing/summarizeStoryWriting_learn_${startLevel}_$endLevel.json';

    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final levelCards = rawQuests.where((q) {
        final id = q['id'] as String? ?? '';
        final match = RegExp(r'_L(\d+)_').firstMatch(id);
        if (match != null) {
          return int.parse(match.group(1)!) == widget.level;
        }
        return false;
      }).toList();

      if (mounted && levelCards.isNotEmpty) {
        setState(() {
          _cards = levelCards;
        });
      }
    } catch (_) {
      // Retain fallback cards on asset failure
    }
  }

  List<Map<String, dynamic>> get _fallbackCards => [
        {
          'id': 'WRT_SUMMARIZESTORYWRITING_LEARN_FALLBACK_1',
          'instruction':
              'Arrange the three things Priya did, in the order she did them.',
          'story':
              'Priya reached the bus stop at 7:30. Her brother had already left on the earlier bus. When the next bus came, she climbed on. Ten minutes later she got off at her school gate.',
          'chronologicalEvents': [
            {
              'stage': '1. Initial Catalyst / Setup',
              'event': 'Priya reached the bus stop at 7:30.',
            },
            {
              'stage': '2. Core Action / Turning Point',
              'event': 'Priya climbed onto the next bus.',
            },
            {
              'stage': '3. Final Resolution / Outcome',
              'event': 'Priya got off at her school gate.',
            },
          ],
          'modelSummary':
              'Priya reached the bus stop at 7:30. Priya climbed onto the next bus. Priya got off at her school gate.',
          'distractorAnalysis': {
            'sentence': "Priya's brother left on the earlier bus.",
            'reason':
                'This detail describes background context about another person that does not advance Priya\'s own travel journey.',
          },
          'summaryFramework': {
            'somebody': 'Priya',
            'wanted': 'To travel to school on time.',
            'but': 'Her brother had already departed on an earlier bus.',
            'so': 'She waited and boarded the subsequent bus.',
            'then': 'She arrived safely at her school gate.',
          },
          'techniqueTip':
              'A narrative summary discards secondary character actions and atmosphere to preserve only the protagonist\'s direct cause-and-effect progression.',
          'explanation':
              'The brother\'s bus left before Priya even arrived, and it was his journey, not hers. Priya\'s own steps run from reaching the stop, to boarding the next bus, to getting off at school.',
        },
      ];

  void _onNext() {
    if (_cardIndex < _cards.length - 1) {
      setState(() {
        _cardIndex++;
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'summarizeStoryWriting',
        level: widget.level,
        phase: 'learn',
      );
      context.pushReplacement(
        '/practice?category=writing&gameType=summarizeStoryWriting&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = _cards[_cardIndex];

    final story = card['story'] as String? ?? '';
    final instruction = card['instruction'] as String? ?? '';
    final modelSummary = card['modelSummary'] as String? ?? '';
    final explanation = card['explanation'] as String? ?? '';
    final techniqueTip = card['techniqueTip'] as String? ?? '';

    final chronologicalEvents =
        (card['chronologicalEvents'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
    final distractorAnalysis =
        card['distractorAnalysis'] as Map<String, dynamic>?;

    final isLast = _cardIndex >= _cards.length - 1;

    return LearnPhaseScaffold(
      title: 'Narrative Architecture & Summary',
      gameType: 'summarizeStoryWriting',
      level: widget.level,
      actionLabel: isLast ? 'Start Guided Practice' : 'Next Story Card',
      onComplete: _onNext,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pacing & Progress Pill
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.indigo500.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'STORY SUMMARY CARD ${_cardIndex + 1} OF ${_cards.length}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.indigo500,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.emerald500.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'Setup → Turning Point → Resolution',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.emerald500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Narrative Story Passage Card
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
                        Icons.auto_stories_rounded,
                        color: AppColors.indigo500,
                        size: 22.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'ORIGINAL NARRATIVE PASSAGE',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo500,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    story,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.slate100 : AppColors.slate800,
                      height: 1.45,
                    ),
                  ),
                  if (instruction.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 15.sp,
                          color: AppColors.amber500,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            instruction,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              color: isDark
                                  ? AppColors.slate400
                                  : AppColors.slate600,
                              height: 1.3,
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

            // Chronological Key Events Architecture
            Text(
              'ESSENTIAL CHRONOLOGICAL CHAIN:',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.slate400 : AppColors.slate600,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 10.h),

            ...chronologicalEvents.map((step) {
              final stage = step['stage'] as String? ?? '';
              final event = step['event'] as String? ?? '';

              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate900 : Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.indigo500.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.indigo500,
                        letterSpacing: 0.6,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      event,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.slate200
                            : AppColors.slate700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Model Summary Card
            Container(
              margin: EdgeInsets.only(top: 6.h, bottom: 14.h),
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.emerald500.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.emerald500,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'SYNTHESIZED NARRATIVE SUMMARY',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.emerald500,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    modelSummary,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.slate100
                          : AppColors.slate800,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Distractor / Noise Filter Breakdown
            if (distractorAnalysis != null) ...[
              Container(
                margin: EdgeInsets.only(bottom: 14.h),
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppColors.amber500.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.amber500.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.filter_alt_outlined,
                          color: AppColors.amber500,
                          size: 18.sp,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            'BACKGROUND NOISE TO EXCLUDE',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.amber500,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      '"${distractorAnalysis['sentence']}"',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.slate200
                            : AppColors.slate700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      distractorAnalysis['reason'] as String? ?? '',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        color: isDark
                            ? AppColors.slate400
                            : AppColors.slate600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Technique Tip Card
            if (techniqueTip.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppColors.indigo500.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.indigo500.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.tips_and_updates_rounded,
                      color: AppColors.indigo500,
                      size: 20.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SUMMARIZER\'S HEURISTIC',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.indigo500,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            techniqueTip,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              color: isDark
                                  ? AppColors.slate300
                                  : AppColors.slate700,
                              height: 1.35,
                            ),
                          ),
                          if (explanation.isNotEmpty) ...[
                            SizedBox(height: 6.h),
                            Text(
                              explanation,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontStyle: FontStyle.italic,
                                color: isDark
                                    ? AppColors.slate400
                                    : AppColors.slate500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
