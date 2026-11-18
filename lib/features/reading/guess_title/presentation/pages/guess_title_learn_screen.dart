import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Learn phase screen for Guess Title mini-game.
/// Teaches students the "Main Idea vs Detail Filter" framework, training them
/// to distinguish the core thesis from narrow details, over-generalized titles,
/// and misleading distractors.
class GuessTitleLearnScreen extends StatefulWidget {
  final int level;

  const GuessTitleLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<GuessTitleLearnScreen> createState() => _GuessTitleLearnScreenState();
}

class _GuessTitleLearnScreenState extends State<GuessTitleLearnScreen> {
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
        'assets/curriculum/reading/guessTitle_learn_${startLevel}_$endLevel.json';

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
      // Retain fallback quests on asset load failure (e.g. test environment)
    }
  }

  List<Map<String, dynamic>> get _fallbackQuests => [
        {
          'id': 'RDG_GUESSTITLE_LEARN_FALLBACK_1',
          'level': widget.level,
          'title': 'Main Idea vs Detail Filter',
          'strategyBadge': 'THESIS VS DETAIL FILTER',
          'techniqueTitle': 'Main Idea vs Narrow Detail Filter',
          'coreRule':
              'A true title captures the central thesis of the entire passage, not just a single supporting sentence or isolated fact.',
          'passage':
              'Before Maria goes to the market, she writes a shopping list. She checks the kitchen to see what is already there. At the store, she buys only what is on the list, so she spends less and forgets nothing.',
          'targetTitle': 'Shopping With a List',
          'whyCorrect':
              'It names the list that links checking the kitchen with buying only what is needed.',
          'distractorAnalysis': [
            {
              'title': 'Cleaning the Kitchen',
              'isCorrect': false,
              'category': 'TOO NARROW (DETAIL)',
              'reason':
                  'This describes only one supporting action, ignoring the shopping and saving money.',
            },
            {
              'title': 'Shopping With a List',
              'isCorrect': true,
              'category': 'BEST TITLE (THESIS)',
              'reason':
                  'Captures the entire plan connecting preparation, shopping, and saving.',
            },
            {
              'title': 'A Guide to Choosing Fresh Fruit',
              'isCorrect': false,
              'category': 'TOO BROAD (OVER-GENERALIZED)',
              'reason':
                  'Fruit is not the central topic; the focus is on disciplined list-making.',
            },
            {
              'title': 'Cooking Dinner for Friends',
              'isCorrect': false,
              'category': 'IRRELEVANT DISTRACTOR',
              'reason':
                  'The passage never mentions cooking dinner or inviting guests.',
            },
          ],
          'explanation':
              'Each sentence belongs to one plan: write a list, check supplies, and spend wisely.',
          'hint': 'Ask what connects the first sentence to the last.',
        },
        {
          'id': 'RDG_GUESSTITLE_LEARN_FALLBACK_2',
          'level': widget.level,
          'title': 'Main Idea vs Detail Filter',
          'strategyBadge': 'MAIN IDEA DISTILLER',
          'techniqueTitle': 'Distinguishing Thesis from Examples',
          'coreRule':
              'Beware of "Too Narrow" options that accurately describe one detail but fail to summarize the overall message.',
          'passage':
              'Ken takes the number 12 bus to work. It leaves at 7:40, so he reaches the stop ten minutes early. On the ride he reads a book. When he gets to the office, he feels calm and ready.',
          'targetTitle': 'Ken\'s Daily Bus Ride',
          'whyCorrect':
              'The time, the stop, and the book all belong to the bus ride, so this title covers everything in the passage.',
          'distractorAnalysis': [
            {
              'title': 'Ken\'s First Day at a New Job',
              'isCorrect': false,
              'category': 'IRRELEVANT DISTRACTOR',
              'reason': 'A new job is not mentioned.',
            },
            {
              'title': 'Ken\'s Daily Bus Ride',
              'isCorrect': true,
              'category': 'BEST TITLE (THESIS)',
              'reason': 'Captures the departure, commute, and reading.',
            },
            {
              'title': 'Ken\'s Walk Through the Park',
              'isCorrect': false,
              'category': 'IRRELEVANT DISTRACTOR',
              'reason': 'Ken rides the bus, not walking in a park.',
            },
            {
              'title': 'Ken Buys a Monthly Train Pass',
              'isCorrect': false,
              'category': 'IRRELEVANT DISTRACTOR',
              'reason': 'He rides a bus, not a train.',
            },
          ],
          'explanation':
              'The departure time, the waiting, and the reading all happen around one bus trip.',
          'hint': 'Look for the one activity Ken repeats.',
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
          '/practice?category=reading&gameType=guessTitle&level=${widget.level}';
      context.pushReplacement(practicePath);
    }
  }

  Color _getCategoryColor(String category, bool isCorrect) {
    if (isCorrect) return AppColors.emerald500;
    if (category.contains('NARROW')) return AppColors.amber500;
    if (category.contains('BROAD')) return AppColors.indigo400;
    return AppColors.rose500;
  }

  IconData _getCategoryIcon(String category, bool isCorrect) {
    if (isCorrect) return Icons.check_circle_rounded;
    if (category.contains('NARROW')) return Icons.filter_center_focus_rounded;
    if (category.contains('BROAD')) return Icons.zoom_out_map_rounded;
    return Icons.block_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final quest = _quests.isNotEmpty ? _quests[_cardIndex] : _fallbackQuests.first;
    final isLastCard = _cardIndex >= _quests.length - 1;

    final strategyBadge =
        quest['strategyBadge'] as String? ?? 'THESIS VS DETAIL FILTER';
    final techniqueTitle =
        quest['techniqueTitle'] as String? ?? 'Main Idea vs Detail Filter';
    final coreRule = quest['coreRule'] as String? ?? '';
    final passage = quest['passage'] as String? ?? '';
    final explanation = quest['explanation'] as String? ?? '';
    final distractorAnalysis =
        (quest['distractorAnalysis'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

    return LearnPhaseScaffold(
      title: 'Main Idea vs Detail Filter',
      gameType: 'guessTitle',
      level: widget.level,
      actionLabel: isLastCard ? 'Begin Headline Gym' : 'Next Scope Strategy',
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
                Text(
                  'Card ${_cardIndex + 1} of ${_quests.length}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate400,
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
                        Icons.auto_stories_rounded,
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
                        Icons.article_rounded,
                        color: AppColors.indigo400,
                        size: 18.r,
                      ),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          'PASSAGE TO ANALYZE',
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

            // Title Scope Evaluation Breakdown
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
                        Icons.tune_rounded,
                        color: AppColors.amber500,
                        size: 18.r,
                      ),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          'TITLE SCOPE BREAKDOWN',
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

                  // Option Cards with Scope Diagnosis
                  ...distractorAnalysis.map((item) {
                    final title = item['title'] as String? ?? '';
                    final isCorrect = item['isCorrect'] as bool? ?? false;
                    final category = item['category'] as String? ?? '';
                    final reason = item['reason'] as String? ?? '';
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                                      title,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 13.5.sp,
                                        fontWeight: isCorrect
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isCorrect
                                            ? Colors.white
                                            : AppColors.slate200,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Padding(
                            padding: EdgeInsets.only(left: 26.w),
                            child: Text(
                              reason,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                height: 1.4,
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

            // Pedagogical Thesis Summary Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
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
                        Icons.lightbulb_outline_rounded,
                        color: AppColors.emerald500,
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
                            color: AppColors.emerald500,
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
