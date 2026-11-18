import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive Learn Phase screen for Essay Drafting ("Essay Architecture & Outline Blueprint").
///
/// Demonstrates the foundational deductive progression:
/// Overarching Premise → Supporting Rationale → Concrete Case Evidence → Forward Synthesis.
class EssayDraftingLearnScreen extends StatefulWidget {
  final int level;

  const EssayDraftingLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<EssayDraftingLearnScreen> createState() =>
      _EssayDraftingLearnScreenState();
}

class _EssayDraftingLearnScreenState extends State<EssayDraftingLearnScreen> {
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
        'assets/curriculum/writing/essayDrafting_learn_${startLevel}_$endLevel.json';

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
          'id': 'WRT_ESSAYDRAFTING_LEARN_FALLBACK_1',
          'instruction':
              'Arrange the four sentences into one clear paragraph.',
          'essayTopic':
              'Describe why a short morning walk is worth adding to your day',
          'thesisStatement':
              'A short morning walk is an easy, low-cost way to start the day well.',
          'structuralPillars': [
            {
              'pillar': '1. Main Point',
              'sentence':
                  'A short walk each morning is one of the easiest ways to start the day well.',
              'guidance':
                  'Anchors the central claim or introducing premise so the reader knows what claim is being defended.',
            },
            {
              'pillar': '2. Reason',
              'sentence':
                  'It gives the body gentle exercise before the day fills up with sitting.',
              'guidance':
                  'Provides the core biological or contextual rationale explaining why the claim holds true.',
            },
            {
              'pillar': '3. Example',
              'sentence':
                  'Twenty minutes around the block, for instance, is often enough to feel awake by the time breakfast is ready.',
              'guidance':
                  'Provides a tangible, concrete illustration showing that underlying reason in direct action.',
            },
            {
              'pillar': '4. Closing Thought',
              'sentence':
                  'A habit that small costs almost nothing and keeps paying back until evening.',
              'guidance':
                  'Synthesizes the broader takeaway and long-term payoff, leaving a lasting and persuasive conclusion.',
            },
          ],
          'modelDraft':
              'A short walk each morning is one of the easiest ways to start the day well. It gives the body gentle exercise before the day fills up with sitting. Twenty minutes around the block, for instance, is often enough to feel awake by the time breakfast is ready. A habit that small costs almost nothing and keeps paying back until evening.',
          'techniqueTip':
              'A powerful essay paragraph follows a deductive progression: Claim → Rationale → Concrete Evidence → Strategic Synthesis. Placing the conclusion prematurely weakens the persuasive payoff.',
          'explanation':
              'The opening sentence makes the claim the rest of the paragraph has to support. The reason explains why the claim holds, and only then does the twenty-minute example land, because it shows that reason at work. The closing thought steps back to the payoff; placed earlier, it would end the paragraph before any support had arrived.',
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
        gameType: 'essayDrafting',
        level: widget.level,
        phase: 'learn',
      );
      context.pushReplacement(
        '/practice?category=writing&gameType=essayDrafting&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = _cards[_cardIndex];

    final essayTopic = card['essayTopic'] as String? ?? '';
    final thesisStatement = card['thesisStatement'] as String? ?? '';
    final instruction = card['instruction'] as String? ?? '';
    final modelDraft = card['modelDraft'] as String? ?? '';
    final explanation = card['explanation'] as String? ?? '';
    final techniqueTip = card['techniqueTip'] as String? ?? '';

    final structuralPillars =
        (card['structuralPillars'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

    final isLast = _cardIndex >= _cards.length - 1;

    return LearnPhaseScaffold(
      title: 'Essay Architecture & Outline',
      gameType: 'essayDrafting',
      level: widget.level,
      actionLabel: isLast ? 'Start Guided Practice' : 'Next Outline Card',
      onComplete: _onNext,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pacing & Strategy Pill
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
                    'ESSAY BLUEPRINT ${_cardIndex + 1} OF ${_cards.length}',
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
                    'Claim → Reason → Evidence → Synthesis',
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

            // Essay Topic & Thesis Card
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
                        Icons.article_rounded,
                        color: AppColors.indigo500,
                        size: 22.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'ESSAY TOPIC & THESIS',
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
                    essayTopic,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.slate100 : AppColors.slate800,
                      height: 1.35,
                    ),
                  ),
                  if (thesisStatement.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppColors.indigo500.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: AppColors.indigo500.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'THESIS STATEMENT:',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.indigo500,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            thesisStatement,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                              color: isDark
                                  ? AppColors.slate200
                                  : AppColors.slate800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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

            // Four-Part Structural Pillars Breakdown
            Text(
              'PARAGRAPH DRAFTING PILLARS:',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.slate400 : AppColors.slate600,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 10.h),

            ...structuralPillars.map((pillarMap) {
              final pillar = pillarMap['pillar'] as String? ?? '';
              final sentence = pillarMap['sentence'] as String? ?? '';
              final guidance = pillarMap['guidance'] as String? ?? '';

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
                      pillar,
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
                      sentence,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.slate100
                            : AppColors.slate800,
                        height: 1.35,
                      ),
                    ),
                    if (guidance.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        guidance,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.5.sp,
                          color: isDark
                              ? AppColors.slate400
                              : AppColors.slate600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),

            // Complete Model Draft Card
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
                        Icons.check_circle_rounded,
                        color: AppColors.emerald500,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'SYNTHESIZED PARAGRAPH DRAFT',
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
                  SizedBox(height: 10.h),
                  Text(
                    modelDraft,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.slate100
                          : AppColors.slate800,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

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
                            'RHETORICAL HEURISTIC',
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
