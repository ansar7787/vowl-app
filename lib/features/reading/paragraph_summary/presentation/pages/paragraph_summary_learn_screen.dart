import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Learn phase screen for Paragraph Summary mini-game.
/// Teaches students the "80/20 Distiller" method: pruning non-essential examples,
/// descriptive filler, and isolated facts to isolate the central controlling takeaway.
class ParagraphSummaryLearnScreen extends StatefulWidget {
  final int level;

  const ParagraphSummaryLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<ParagraphSummaryLearnScreen> createState() =>
      _ParagraphSummaryLearnScreenState();
}

class _ParagraphSummaryLearnScreenState
    extends State<ParagraphSummaryLearnScreen> {
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
        'assets/curriculum/reading/paragraphSummary_learn_${startLevel}_$endLevel.json';

    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final levelQuests = rawQuests.where((q) {
        final qLevel = q['level'] as int? ?? 1;
        return qLevel == widget.level;
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
          'id': 'RDG_PARAGRAPHSUMMARY_LEARN_FALLBACK_1',
          'level': widget.level,
          'title': '80/20 Distiller',
          'strategyBadge': '80/20 DISTILLER',
          'techniqueTitle': '80/20 Distillation Framework',
          'coreRule':
              'A summary is not a collection of details; it captures the unified takeaway that every sentence builds toward.',
          'passage':
              'Amara gets up early on school days. She packs her bag, eats rice and eggs, and catches the bus at seven. By half past seven, she is sitting at her desk.',
          'keywords': ['School Morning', 'Getting Ready', 'Bus to School'],
          'keyPoints': [
            'Amara has a regular morning routine on school days.',
            'She packs her bag, eats breakfast and takes the bus.',
            'The routine gets her to her desk by half past seven.',
          ],
          'distilledSentences': [
            {
              'text': 'Amara gets up early on school days.',
              'role': 'CORE THESIS ANCHOR',
              'action': 'KEEP',
            },
            {
              'text':
                  'She packs her bag, eats rice and eggs, and catches the bus at seven.',
              'role': 'SUPPORTING DETAIL',
              'action': 'PRUNE',
            },
            {
              'text': 'By half past seven, she is sitting at her desk.',
              'role': 'CORE THESIS ANCHOR',
              'action': 'KEEP',
            },
          ],
          'targetSummary':
              'Amara gets ready and travels to school in the morning.',
          'optionAnalysis': [
            {
              'text': 'Amara is often late for the school bus in the mornings.',
              'isCorrect': false,
              'category': 'UNSUPPORTED CONTRADICTION',
              'rationale':
                  'Contradicts the text, which says she arrives at her desk by 7:30.',
            },
            {
              'text': 'Amara gets ready and travels to school in the morning.',
              'isCorrect': true,
              'category': 'BEST SUMMARY (DISTILLED THESIS)',
              'rationale':
                  'Accurately summarizes the entire journey from waking to arriving.',
            },
            {
              'text': 'Amara studies quietly at her desk after school ends.',
              'isCorrect': false,
              'category': 'OUTSIDE THE SCOPE',
              'rationale':
                  'The paragraph only describes the morning before classes start.',
            },
            {
              'text':
                  'Amara eats rice and eggs for breakfast before she leaves home.',
              'isCorrect': false,
              'category': 'TOO NARROW (ONE DETAIL)',
              'rationale':
                  'Accurate factual detail, but only covers one meal, ignoring the journey.',
            },
          ],
          'explanation':
              'The paragraph follows Amara from waking up to sitting at her desk. Breakfast is only one step inside that routine.',
          'hint':
              'Ask what the whole paragraph is about, not what happens in just one sentence.',
        },
        {
          'id': 'RDG_PARAGRAPHSUMMARY_LEARN_FALLBACK_2',
          'level': widget.level,
          'title': '80/20 Distiller',
          'strategyBadge': 'SENTENCE PRUNER',
          'techniqueTitle': 'Pruning Supporting Fluff & Examples',
          'coreRule':
              'Identify and prune examples, parenthetical remarks, and descriptive filler to expose the core thesis.',
          'passage':
              'Biscuit is a small brown dog. Every afternoon he waits by the door for the children to come home from school. When they arrive, he jumps up and wags his tail.',
          'keywords': ['Pet Dog', 'After-School Greeting', 'Excited Welcome'],
          'keyPoints': [
            'Biscuit is a family dog who waits for the children each afternoon.',
            'He waits by the door until they come home from school.',
            'When they arrive, he jumps up and wags his tail happily.',
          ],
          'distilledSentences': [
            {
              'text': 'Biscuit is a small brown dog.',
              'role': 'BACKGROUND DETAIL',
              'action': 'PRUNE',
            },
            {
              'text':
                  'Every afternoon he waits by the door for the children to come home from school.',
              'role': 'CORE THESIS ANCHOR',
              'action': 'KEEP',
            },
            {
              'text': 'When they arrive, he jumps up and wags his tail.',
              'role': 'CORE THESIS ANCHOR',
              'action': 'KEEP',
            },
          ],
          'targetSummary':
              'A dog is always excited to greet the children after school.',
          'optionAnalysis': [
            {
              'text':
                  'Biscuit waits by the door because he wants his dinner.',
              'isCorrect': false,
              'category': 'UNSUPPORTED CONTRADICTION',
              'rationale':
                  'Hunger is never mentioned; he waits for the children.',
            },
            {
              'text':
                  'The children take Biscuit for a long walk every afternoon.',
              'isCorrect': false,
              'category': 'OUTSIDE THE SCOPE',
              'rationale': 'Walking the dog is not discussed in the text.',
            },
            {
              'text':
                  'A dog is always excited to greet the children after school.',
              'isCorrect': true,
              'category': 'BEST SUMMARY (DISTILLED THESIS)',
              'rationale':
                  'Captures the daily waiting and enthusiastic greeting.',
            },
            {
              'text':
                  'Biscuit is a small brown dog who likes to sit by the door.',
              'isCorrect': false,
              'category': 'TOO NARROW (ONE DETAIL)',
              'rationale':
                  'Mentions physical appearance without the central welcoming action.',
            },
          ],
          'explanation':
              'Each sentence describes the dog\'s daily welcome. Size and fur color are descriptive details, not the central thesis.',
          'hint': 'Look for the idea that the sentences share.',
        },
      ];

  void _onNext() {
    if (_cardIndex < _quests.length - 1) {
      setState(() {
        _cardIndex++;
      });
    } else {
      // Transition to Practice phase
      final practicePath =
          '/practice?category=reading&gameType=paragraphSummary&level=${widget.level}';
      context.pushReplacement(practicePath);
    }
  }

  Color _getCategoryColor(String category, bool isCorrect) {
    if (isCorrect) return AppColors.emerald500;
    if (category.contains('NARROW')) return AppColors.amber500;
    if (category.contains('CONTRADICTION')) return AppColors.rose500;
    return AppColors.indigo400;
  }

  IconData _getCategoryIcon(String category, bool isCorrect) {
    if (isCorrect) return Icons.check_circle_rounded;
    if (category.contains('NARROW')) return Icons.filter_center_focus_rounded;
    if (category.contains('CONTRADICTION')) return Icons.cancel_rounded;
    return Icons.zoom_out_map_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final quest = _quests.isNotEmpty ? _quests[_cardIndex] : _fallbackQuests.first;
    final isLastCard = _cardIndex >= _quests.length - 1;

    final strategyBadge =
        quest['strategyBadge'] as String? ?? '80/20 DISTILLER';
    final techniqueTitle =
        quest['techniqueTitle'] as String? ?? '80/20 Distillation Framework';
    final coreRule = quest['coreRule'] as String? ?? '';
    final passage = quest['passage'] as String? ?? '';
    final keywords =
        (quest['keywords'] as List<dynamic>? ?? []).cast<String>();
    final keyPoints =
        (quest['keyPoints'] as List<dynamic>? ?? []).cast<String>();
    final distilledSentences =
        (quest['distilledSentences'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
    final optionAnalysis = (quest['optionAnalysis'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final explanation = quest['explanation'] as String? ?? '';

    return LearnPhaseScaffold(
      title: '80/20 Distiller',
      gameType: 'paragraphSummary',
      level: widget.level,
      actionLabel: isLastCard ? 'Begin Summary Gym' : 'Next Distiller Strategy',
      onComplete: _onNext,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Indicator Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.teal500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.teal500.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      strategyBadge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.teal500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    'Card ${_cardIndex + 1} of ${_quests.length}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate400,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Technique Header & Core Rule Box
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.teal500.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.filter_alt_rounded,
                        color: AppColors.teal500,
                        size: 20.r,
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          techniqueTitle.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    coreRule,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.5.sp,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                      color: AppColors.slate300,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Keywords Wrap
            if (keywords.isNotEmpty) ...[
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: keywords.map((kw) {
                  return Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.indigo500.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      '#$kw',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.indigo400,
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 14.h),
            ],

            // Passage Preview Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.indigo400,
                        size: 18.r,
                      ),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          'PARAGRAPH PASSAGE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.indigo400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    passage,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.5.sp,
                      height: 1.55,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Sentence Pruning Breakdown (80/20 Distiller)
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.slate700,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.content_cut_rounded,
                        color: AppColors.amber500,
                        size: 18.r,
                      ),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          'SENTENCE PRUNING BREAKDOWN',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.amber500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  ...distilledSentences.map((s) {
                    final text = s['text'] as String? ?? '';
                    final role = s['role'] as String? ?? '';
                    final action = s['action'] as String? ?? '';
                    final isKeep = action == 'KEEP';

                    return Container(
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: isKeep
                            ? AppColors.emerald500.withValues(alpha: 0.1)
                            : AppColors.slate800,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isKeep
                              ? AppColors.emerald500.withValues(alpha: 0.4)
                              : AppColors.slate700,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isKeep
                                ? Icons.check_circle_outline_rounded
                                : Icons.remove_circle_outline_rounded,
                            color: isKeep
                                ? AppColors.emerald400
                                : AppColors.slate400,
                            size: 16.r,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  text,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.5.sp,
                                    height: 1.4,
                                    fontWeight: isKeep
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isKeep
                                        ? Colors.white
                                        : AppColors.slate400,
                                    decoration: isKeep
                                        ? TextDecoration.none
                                        : TextDecoration.lineThrough,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  '$role • ${isKeep ? "KEEP FOR SUMMARY" : "PRUNE AS DETAIL"}',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 9.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isKeep
                                        ? AppColors.emerald400
                                        : AppColors.slate500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Summary Options Scope Diagnosis
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.slate700,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.rate_review_rounded,
                        color: AppColors.teal400,
                        size: 18.r,
                      ),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          'SUMMARY CANDIDATES DIAGNOSIS',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.teal400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  ...optionAnalysis.map((opt) {
                    final text = opt['text'] as String? ?? '';
                    final isCorrect = opt['isCorrect'] as bool? ?? false;
                    final category = opt['category'] as String? ?? '';
                    final rationale = opt['rationale'] as String? ?? '';
                    final color = _getCategoryColor(category, isCorrect);
                    final icon = _getCategoryIcon(category, isCorrect);

                    return Container(
                      margin: EdgeInsets.only(bottom: 10.h),
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: color.withValues(alpha: isCorrect ? 0.6 : 0.3),
                          width: isCorrect ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, color: color, size: 18.r),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w800,
                                      color: color,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  text,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13.sp,
                                    fontWeight: isCorrect
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isCorrect
                                        ? Colors.white
                                        : AppColors.slate200,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  rationale,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 11.5.sp,
                                    height: 1.35,
                                    color: AppColors.slate400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Key Takeaways Box
            if (keyPoints.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.emerald500.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.checklist_rounded,
                          color: AppColors.emerald400,
                          size: 18.r,
                        ),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            'KEY POINTS EXTRACTED',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.emerald400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    ...keyPoints.map((kp) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 4.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ',
                                style: TextStyle(
                                    color: AppColors.emerald400,
                                    fontSize: 13.sp)),
                            Expanded(
                              child: Text(
                                kp,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.5.sp,
                                  color: AppColors.slate300,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
            ],

            // Synthesis Breakdown Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.slate700,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: AppColors.amber500,
                        size: 18.r,
                      ),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          'SYNTHESIS KEY',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.amber500,
                          ),
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
                      height: 1.45,
                      color: AppColors.slate300,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
