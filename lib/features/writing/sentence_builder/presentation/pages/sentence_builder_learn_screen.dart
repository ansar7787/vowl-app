import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive Learn Phase screen for Sentence Builder ("Syntactic Block Architecture").
///
/// Teaches learners English sentence cadence:
/// Subject (Who?) + Verb (Action) + Object (What?) + Adverbial (Where/When/How).
class SentenceBuilderLearnScreen extends StatefulWidget {
  final int level;

  const SentenceBuilderLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<SentenceBuilderLearnScreen> createState() =>
      _SentenceBuilderLearnScreenState();
}

class _SentenceBuilderLearnScreenState
    extends State<SentenceBuilderLearnScreen> {
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
        'assets/curriculum/writing/sentenceBuilder_learn_${startLevel}_$endLevel.json';

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
          'id': 'WRT_SENTENCEBUILDER_LEARN_FALLBACK_1',
          'level': widget.level,
          'title': 'Syntactic Block Architecture',
          'strategyBadge': 'SYNTAX ARCHITECTURE',
          'cadencePattern': 'Subject + Verb + Object + Adverbial',
          'blocks': [
            {'role': 'Subject (Who?)', 'text': 'The curious astronomer', 'color': 'blue'},
            {'role': 'Verb (Action)', 'text': 'observed', 'color': 'violet'},
            {'role': 'Object (What?)', 'text': 'distant galaxies', 'color': 'amber'},
            {'role': 'Adverbial (Context)', 'text': 'through the observatory lens', 'color': 'emerald'},
          ],
          'completeSentence':
              'The curious astronomer observed distant galaxies through the observatory lens.',
          'coreRule':
              'English statements follow an SVO (Subject-Verb-Object) sequence. Modifiers and adverbials anchor at the conclusion.',
          'contrastExample': {
            'incorrect': 'Through the lens observed astronomer galaxies.',
            'whyBroken':
                'Misplacing the subject after the verb without inversion triggers syntactic confusion.',
          },
          'cadenceExplanation':
              'By establishing the actor first, the listener forms a mental focal point before receiving the predicate action.',
        },
        {
          'id': 'WRT_SENTENCEBUILDER_LEARN_FALLBACK_2',
          'level': widget.level,
          'title': 'Transitive Action Framing',
          'strategyBadge': 'ACTION CADENCE',
          'cadencePattern': 'Subject + Verb + Object + Purpose',
          'blocks': [
            {'role': 'Subject (Who?)', 'text': 'Experienced engineers', 'color': 'blue'},
            {'role': 'Verb (Action)', 'text': 'designed', 'color': 'violet'},
            {'role': 'Object (What?)', 'text': 'resilient bridges', 'color': 'amber'},
            {'role': 'Purpose (Why?)', 'text': 'for high-speed transit networks', 'color': 'emerald'},
          ],
          'completeSentence':
              'Experienced engineers designed resilient bridges for high-speed transit networks.',
          'coreRule':
              'Active voice attributes clear responsibility and delivers immediate, energetic cadence.',
          'contrastExample': {
            'incorrect': 'Designed resilient bridges engineers.',
            'whyBroken':
                'Separating the verb from its agent produces an ungrammatical passive fragment.',
          },
          'cadenceExplanation':
              'Keeping verb and direct object adjacent prevents cognitive drag and ensures clarity.',
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
        gameType: 'sentenceBuilder',
        level: widget.level,
        phase: 'learn',
      );
      context.pushReplacement(
        '/practice?category=writing&gameType=sentenceBuilder&level=${widget.level}',
      );
    }
  }

  Color _getBlockColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return AppColors.blue500;
      case 'violet':
        return AppColors.violet500;
      case 'amber':
        return AppColors.amber500;
      case 'emerald':
        return AppColors.emerald500;
      default:
        return AppColors.indigo500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentQuest = _quests[_cardIndex];

    final badge = currentQuest['strategyBadge'] as String? ??
        'SYNTAX ARCHITECTURE';
    final cadencePattern = currentQuest['cadencePattern'] as String? ??
        'Subject + Verb + Object';
    final blocks = (currentQuest['blocks'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final completeSentence = currentQuest['completeSentence'] as String? ?? '';
    final coreRule = currentQuest['coreRule'] as String? ?? '';
    final contrastExample =
        currentQuest['contrastExample'] as Map<String, dynamic>? ?? {};
    final cadenceExplanation = currentQuest['cadenceExplanation'] as String? ?? '';

    final hasNext = _cardIndex < _quests.length - 1;

    return LearnPhaseScaffold(
      title: 'Syntactic Block Architecture',
      gameType: 'sentenceBuilder',
      level: widget.level,
      actionLabel: hasNext ? 'Next Pattern' : 'Complete Learn Phase',
      onComplete: _onNext,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Strategy Badge & Card Header
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : AppColors.indigo50,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark
                      ? AppColors.indigo500.withValues(alpha: 0.3)
                      : AppColors.indigo500.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.indigo500,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          'PATTERN ${_cardIndex + 1} OF ${_quests.length}',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.slate400
                                : AppColors.slate600,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Cadence: $cadencePattern',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.slate900,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    cadenceExplanation,
                    style: TextStyle(
                      color: isDark ? AppColors.slate300 : AppColors.slate700,
                      fontSize: 13.sp,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Complete Sentence Anchor Card
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10.r,
                    offset: Offset(0, 4.h),
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
                        color: AppColors.indigo500,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'COMPLETE NATURAL CADENCE',
                          style: TextStyle(
                            color: AppColors.indigo500,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    '"$completeSentence"',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.slate900,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Semantic Blocks Breakdown
            Text(
              'SYNTACTIC BUILDING BLOCKS',
              style: TextStyle(
                color: isDark ? AppColors.slate400 : AppColors.slate600,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 8.h),

            ...blocks.map((block) {
              final role = block['role'] as String? ?? 'Role';
              final text = block['text'] as String? ?? '';
              final color = _getBlockColor(block['color'] as String? ?? 'blue');

              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate900 : Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: color.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8.w,
                      height: 38.h,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            role,
                            style: TextStyle(
                              color: color,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            text,
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.slate900,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            SizedBox(height: 12.h),

            // Core Rule Card
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.blue900.withValues(alpha: 0.25)
                    : AppColors.blue50,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.blue500.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    color: AppColors.blue500,
                    size: 20.sp,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SYNTACTIC PRINCIPLE',
                          style: TextStyle(
                            color: AppColors.blue500,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          coreRule,
                          style: TextStyle(
                            color: isDark ? AppColors.slate200 : AppColors.slate800,
                            fontSize: 12.sp,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // Contrast Example: Broken vs Natural Cadence
            if (contrastExample.isNotEmpty)
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.rose500.withValues(alpha: 0.12)
                      : AppColors.rose500.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.rose500.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cancel_rounded,
                          color: AppColors.rose500,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'AVOID UNNATURAL WORD ORDER',
                            style: TextStyle(
                              color: AppColors.rose500,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      '"${contrastExample['incorrect'] ?? ''}"',
                      style: TextStyle(
                        color: isDark ? AppColors.rose500 : const Color(0xFFDC2626),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      contrastExample['whyBroken'] as String? ?? '',
                      style: TextStyle(
                        color: isDark ? AppColors.slate300 : AppColors.slate700,
                        fontSize: 12.sp,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
