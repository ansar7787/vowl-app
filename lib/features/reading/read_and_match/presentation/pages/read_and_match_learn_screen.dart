import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Learn phase screen for Read and Match mini-game.
/// Teaches students the "Summary Synapse" strategy: identifying topic sentences,
/// extracting anchor keywords, and mapping umbrella concepts to specific definitions.
class ReadAndMatchLearnScreen extends StatefulWidget {
  final int level;

  const ReadAndMatchLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<ReadAndMatchLearnScreen> createState() =>
      _ReadAndMatchLearnScreenState();
}

class _ReadAndMatchLearnScreenState extends State<ReadAndMatchLearnScreen> {
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
        'assets/curriculum/reading/readAndMatch_learn_${startLevel}_$endLevel.json';

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
          'id': 'RDG_READANDMATCH_LEARN_FALLBACK_1',
          'level': widget.level,
          'title': 'Summary Synapse',
          'strategyBadge': 'SUMMARY SYNAPSE',
          'techniqueTitle': 'Topic Sentence & Keyword Anchoring',
          'coreRule':
              'Identify the core noun and action in each definition to connect it with its governing concept.',
          'paragraphTopic': 'Everyday feelings',
          'instruction': 'Match each word to the meaning that fits.',
          'detailedPairs': [
            {
              'key': '[L1-Q1-0] Tired',
              'cleanKey': 'Tired',
              'value': 'Needing rest because your energy is low.',
              'anchorKeywords': 'rest, energy, low',
              'rationale':
                  'Physical state requiring sleep or recovery, not an emotional reaction.',
            },
            {
              'key': '[L1-Q1-1] Happy',
              'cleanKey': 'Happy',
              'value': 'Feeling pleased about something good.',
              'anchorKeywords': 'pleased, something, good',
              'rationale':
                  'Positive emotion triggered by good news or favorable conditions.',
            },
            {
              'key': '[L1-Q1-2] Sad',
              'cleanKey': 'Sad',
              'value': 'Feeling unhappy, often after bad news.',
              'anchorKeywords': 'unhappy, after, news',
              'rationale':
                  'Direct emotional opposite of happy, provoked by disappointing events.',
            },
          ],
          'explanation':
              'Happy and sad represent opposite emotional responses to news. Tired describes bodily fatigue requiring rest.',
          'hint':
              'Notice which feeling is physical vs which feelings are emotional reactions.',
        },
        {
          'id': 'RDG_READANDMATCH_LEARN_FALLBACK_2',
          'level': widget.level,
          'title': 'Summary Synapse',
          'strategyBadge': 'KEYWORD ANCHORING',
          'techniqueTitle': 'Isolating Thematic Identifiers',
          'coreRule':
              'Beware of near-synonyms: look for specific boundaries like time of day, intensity, or emotional state.',
          'paragraphTopic': 'Meals during the day',
          'instruction': 'Match each word with its meaning.',
          'detailedPairs': [
            {
              'key': '[L1-Q2-0] Dinner',
              'cleanKey': 'Dinner',
              'value': 'The main meal, usually eaten in the evening.',
              'anchorKeywords': 'main, meal, evening',
              'rationale':
                  'Identified by the evening time boundary and being the primary meal.',
            },
            {
              'key': '[L1-Q2-1] Breakfast',
              'cleanKey': 'Breakfast',
              'value': 'The first meal of the day, eaten in the morning.',
              'anchorKeywords': 'first, meal, morning',
              'rationale':
                  'Identified by breaking the overnight fast at the start of the day.',
            },
            {
              'key': '[L1-Q2-2] Lunch',
              'cleanKey': 'Lunch',
              'value': 'The meal eaten in the middle of the day.',
              'anchorKeywords': 'middle, of, day',
              'rationale':
                  'Identified by its midday temporal placement between breakfast and dinner.',
            },
          ],
          'explanation':
              'These three terms follow chronological order from morning to midday to evening.',
          'hint':
              'Follow the timeline: morning first, midday middle, evening last.',
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
          '/practice?category=reading&gameType=readAndMatch&level=${widget.level}';
      context.pushReplacement(practicePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quest = _quests.isNotEmpty ? _quests[_cardIndex] : _fallbackQuests.first;
    final isLastCard = _cardIndex >= _quests.length - 1;

    final strategyBadge =
        quest['strategyBadge'] as String? ?? 'SUMMARY SYNAPSE';
    final techniqueTitle =
        quest['techniqueTitle'] as String? ?? 'Topic Sentence & Keyword Anchoring';
    final coreRule = quest['coreRule'] as String? ?? '';
    final paragraphTopic = quest['paragraphTopic'] as String? ?? '';
    final explanation = quest['explanation'] as String? ?? '';
    final detailedPairs = (quest['detailedPairs'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    final matchColors = [
      AppColors.indigo400,
      AppColors.teal400,
      AppColors.amber500,
      AppColors.emerald400,
      AppColors.rose500,
    ];

    return LearnPhaseScaffold(
      title: 'Summary Synapse',
      gameType: 'readAndMatch',
      level: widget.level,
      actionLabel: isLastCard ? 'Begin Matching Gym' : 'Next Synapse Strategy',
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
                        Icons.hub_rounded,
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

            // Thematic Category Banner
            if (paragraphTopic.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.indigo500.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      color: AppColors.indigo400,
                      size: 18.r,
                    ),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Text(
                        'THEME: ${paragraphTopic.toUpperCase()}',
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
              ),
              SizedBox(height: 14.h),
            ],

            // Synapse Mapping Card
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
                        Icons.swap_horiz_rounded,
                        color: AppColors.amber500,
                        size: 20.r,
                      ),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          'SYNAPSE CONNECTIONS',
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
                  SizedBox(height: 14.h),

                  ...List.generate(detailedPairs.length, (idx) {
                    final pair = detailedPairs[idx];
                    final cleanKey = pair['cleanKey'] as String? ?? '';
                    final value = pair['value'] as String? ?? '';
                    final anchorKeywords =
                        pair['anchorKeywords'] as String? ?? '';
                    final rationale = pair['rationale'] as String? ?? '';
                    final color = matchColors[idx % matchColors.length];

                    return Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: color.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Concept Tag & Anchor
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: color,
                                    width: 1.0,
                                  ),
                                ),
                                child: Text(
                                  cleanKey,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Flexible(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    'Anchor: $anchorKeywords',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),

                          // Definition
                          Text(
                            value,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                              color: AppColors.slate200,
                            ),
                          ),
                          SizedBox(height: 6.h),

                          // Rationale
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
                    );
                  }),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Synthesis Breakdown Card
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
                          'SYNTHESIS BREAKDOWN',
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
