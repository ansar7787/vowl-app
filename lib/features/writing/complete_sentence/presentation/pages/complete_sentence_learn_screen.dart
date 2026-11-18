import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive Learn Phase screen for Complete Sentence ("Clause & Predicate Guide").
///
/// Teaches learners how subordinate clauses connect with independent clauses
/// to form grammatically complete, non-fragmented thoughts.
class CompleteSentenceLearnScreen extends StatefulWidget {
  final int level;

  const CompleteSentenceLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<CompleteSentenceLearnScreen> createState() =>
      _CompleteSentenceLearnScreenState();
}

class _CompleteSentenceLearnScreenState
    extends State<CompleteSentenceLearnScreen> {
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
        'assets/curriculum/writing/completeSentence_learn_${startLevel}_$endLevel.json';

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
          'id': 'WRT_COMPLETESENTENCE_LEARN_FALLBACK_1',
          'level': widget.level,
          'title': 'Clause & Predicate Guide',
          'strategyBadge': 'CLAUSE ARCHITECTURE',
          'connector': 'Although',
          'subordinateClause': 'Although the morning traffic was exceptionally heavy,',
          'independentClause': 'our delivery van reached the warehouse on schedule.',
          'completeSentence':
              'Although the morning traffic was exceptionally heavy, our delivery van reached the warehouse on schedule.',
          'coreRule':
              'A subordinate clause introduced by "Although" must be balanced by an independent clause containing its own subject and finite verb.',
          'contrastExample': {
            'incorrect': 'Although the morning traffic was exceptionally heavy.',
            'whyBroken':
                'Leaves a concessive condition without a main clause, creating a dangling sentence fragment.',
          },
          'breakdown': [
            {
              'part': 'Subordinate Clause (Dependent)',
              'text': 'Although the morning traffic was exceptionally heavy,',
              'role': 'Establishes context or condition. Cannot stand alone.',
              'color': 'indigo',
            },
            {
              'part': 'Independent Clause (Main Thought)',
              'text': 'our delivery van reached the warehouse on schedule.',
              'role': 'Contains its own subject and finite verb. Completes the thought.',
              'color': 'emerald',
            },
          ],
        },
        {
          'id': 'WRT_COMPLETESENTENCE_LEARN_FALLBACK_2',
          'level': widget.level,
          'title': 'Causal Predicate Framing',
          'strategyBadge': 'CAUSAL ARCHITECTURE',
          'connector': 'Because',
          'subordinateClause': 'Because the laboratory team calibrated the sensors precisely,',
          'independentClause': 'the experimental data yielded remarkably consistent results.',
          'completeSentence':
              'Because the laboratory team calibrated the sensors precisely, the experimental data yielded remarkably consistent results.',
          'coreRule':
              'Causal subordinate clauses establish reasons that require a main result clause to form a complete grammatical thought.',
          'contrastExample': {
            'incorrect': 'Because the laboratory team calibrated the sensors precisely.',
            'whyBroken':
                'A causal conjunction demands an effect clause; isolated, it fails the independent clause test.',
          },
          'breakdown': [
            {
              'part': 'Subordinate Clause (Dependent)',
              'text': 'Because the laboratory team calibrated the sensors precisely,',
              'role': 'Introduces causal premise.',
              'color': 'indigo',
            },
            {
              'part': 'Independent Clause (Main Thought)',
              'text': 'the experimental data yielded remarkably consistent results.',
              'role': 'Delivers main effect predicate with explicit subject.',
              'color': 'emerald',
            },
          ],
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
        gameType: 'completeSentence',
        level: widget.level,
        phase: 'learn',
      );
      context.pushReplacement(
        '/practice?category=writing&gameType=completeSentence&level=${widget.level}',
      );
    }
  }

  Color _getPartColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'emerald':
        return AppColors.emerald500;
      case 'amber':
        return AppColors.amber500;
      case 'blue':
        return AppColors.blue500;
      default:
        return AppColors.indigo500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentQuest = _quests[_cardIndex];

    final badge = currentQuest['strategyBadge'] as String? ?? 'CLAUSE ARCHITECTURE';
    final connector = currentQuest['connector'] as String? ?? 'Subordinating';
    final completeSentence = currentQuest['completeSentence'] as String? ?? '';
    final coreRule = currentQuest['coreRule'] as String? ?? '';
    final contrastExample =
        currentQuest['contrastExample'] as Map<String, dynamic>? ?? {};
    final breakdown = (currentQuest['breakdown'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    final hasNext = _cardIndex < _quests.length - 1;

    return LearnPhaseScaffold(
      title: 'Clause & Predicate Guide',
      gameType: 'completeSentence',
      level: widget.level,
      actionLabel: hasNext ? 'Next Pattern' : 'Complete Learn Phase',
      onComplete: _onNext,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
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
                    'Connector Focus: "$connector"',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.slate900,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Every dependent clause initiated by "$connector" requires a companion independent clause with its own subject and finite verb to resolve into a complete thought.',
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
                        Icons.check_circle_outline_rounded,
                        color: AppColors.emerald500,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'COMPLETE GRAMMATICAL THOUGHT',
                          style: TextStyle(
                            color: AppColors.emerald500,
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
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Clause Anatomy Breakdown
            Text(
              'CLAUSE ANATOMY',
              style: TextStyle(
                color: isDark ? AppColors.slate400 : AppColors.slate600,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 8.h),

            ...breakdown.map((part) {
              final partTitle = part['part'] as String? ?? 'Clause';
              final partText = part['text'] as String? ?? '';
              final partRole = part['role'] as String? ?? '';
              final color = _getPartColor(part['color'] as String? ?? 'indigo');

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 2.h),
                      width: 8.w,
                      height: 40.h,
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
                            partTitle,
                            style: TextStyle(
                              color: color,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            partText,
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.slate900,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            partRole,
                            style: TextStyle(
                              color: isDark ? AppColors.slate400 : AppColors.slate600,
                              fontSize: 11.sp,
                              height: 1.3,
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
                    Icons.school_rounded,
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

            // Contrast Example: Fragment warning
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
                          Icons.warning_amber_rounded,
                          color: AppColors.rose500,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'AVOID DANGLING FRAGMENTS',
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
