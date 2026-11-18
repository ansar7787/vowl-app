import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Learn phase screen for Sentence Order Reading mini-game.
/// Guides students through paragraph cohesion, chronological markers, and pronoun reference anchors.
class SentenceOrderReadingLearnScreen extends StatefulWidget {
  final int level;

  const SentenceOrderReadingLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<SentenceOrderReadingLearnScreen> createState() =>
      _SentenceOrderReadingLearnScreenState();
}

class _SentenceOrderReadingLearnScreenState
    extends State<SentenceOrderReadingLearnScreen> {
  int _cardIndex = 0;
  List<Map<String, dynamic>> _quests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurriculum();
  }

  Future<void> _loadCurriculum() async {
    final batchIndex = ((widget.level - 1) ~/ 10) + 1;
    final startLevel = (batchIndex - 1) * 10 + 1;
    final endLevel = batchIndex * 10;
    final assetPath =
        'assets/curriculum/reading/sentenceOrderReading_learn_${startLevel}_$endLevel.json';

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
          _quests = levelQuests.isNotEmpty ? levelQuests : rawQuests;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _quests = _fallbackQuests;
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _fallbackQuests => [
        {
          'id': 'RDG_SENTENCEORDERREADING_LEARN_FALLBACK_1',
          'level': widget.level,
          'title': 'Cohesion & Transition Markers',
          'strategyBadge': 'CHRONOLOGICAL FLOW',
          'clueType': 'Chronological Sequence Clue',
          'coreRule':
              'Chronological markers like "first", "then", and "after that" signal the exact temporal progression of actions.',
          'orderedSentences': [
            'The alarm clock rings at seven in the morning.',
            'Kofi gets out of bed and stretches his arms.',
            'After that, he brushes his teeth and heads downstairs.',
          ],
          'transitionWords': ['After that'],
          'explanation':
              'The alarm provides the initial stimulus for the day. Getting up happens next, and "After that" points to the concluding hygiene action.',
          'hint': 'Find the initial cause before tracking subsequent events.',
        },
      ];

  void _onNext() {
    if (_cardIndex < _quests.length - 1) {
      setState(() {
        _cardIndex++;
      });
    } else {
      context.pushReplacement(
        '/practice?category=reading&gameType=sentenceOrderReading&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return LearnPhaseScaffold(
        title: 'Cohesion & Transition Markers',
        gameType: 'sentenceOrderReading',
        level: widget.level,
        onComplete: () {},
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final quest = _quests.isNotEmpty ? _quests[_cardIndex] : _fallbackQuests[0];
    final isLastCard = _cardIndex >= _quests.length - 1;
    final strategyBadge =
        quest['strategyBadge'] as String? ?? 'CHRONOLOGICAL FLOW';
    final clueType = quest['clueType'] as String? ?? 'Logical Progression';
    final coreRule = quest['coreRule'] as String? ?? '';
    final orderedSentences =
        (quest['orderedSentences'] as List<dynamic>? ?? []).cast<String>();
    final transitionWords =
        (quest['transitionWords'] as List<dynamic>? ?? []).cast<String>();
    final explanation = quest['explanation'] as String? ?? '';

    return LearnPhaseScaffold(
      title: 'Cohesion & Transition Markers',
      gameType: 'sentenceOrderReading',
      level: widget.level,
      actionLabel: isLastCard ? 'Begin Transition Gym' : 'Next Cohesion Strategy',
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
                      color: AppColors.indigo500.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.indigo500.withValues(alpha: 0.3),
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
                        color: AppColors.indigo500,
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

            // Clue Type Header & Rule Box
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
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
                        Icons.account_tree_rounded,
                        color: AppColors.indigo500,
                        size: 20.r,
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          clueType.toUpperCase(),
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

            // Ordered Cohesive Sequence Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'LOGICAL SEQUENCE FLOW',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.teal500,
                          ),
                        ),
                      ),
                      if (transitionWords.isNotEmpty)
                        Flexible(
                          child: Text(
                            'Transition: ${transitionWords.join(", ")}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.amber500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Sentence List with Step Tags
                  ...List.generate(orderedSentences.length, (idx) {
                    final sentence = orderedSentences[idx];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24.r,
                            height: 24.r,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: idx == 0
                                  ? AppColors.indigo500
                                  : (idx == orderedSentences.length - 1
                                      ? AppColors.teal500
                                      : AppColors.slate700),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${idx + 1}',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              sentence,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.5.sp,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
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

            // Explanation & Strategy Breakdown Card
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
                          'COHESION BREAKDOWN',
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
