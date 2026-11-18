import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive Learn Phase screen for Reading Conclusion ("Logical Extrapolation Matrix").
///
/// Teaches learners how to trace cause-and-effect trajectories and premise chains to sound,
/// inevitable conclusions while identifying and filtering fallacies, premature leaps, and contradictions.
class ReadingConclusionLearnScreen extends StatefulWidget {
  final int level;

  const ReadingConclusionLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<ReadingConclusionLearnScreen> createState() =>
      _ReadingConclusionLearnScreenState();
}

class _ReadingConclusionLearnScreenState
    extends State<ReadingConclusionLearnScreen> {
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
        'assets/curriculum/reading/readingConclusion_learn_${startLevel}_$endLevel.json';

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
          'id': 'RDG_READINGCONCLUSION_LEARN_FALLBACK_1',
          'level': widget.level,
          'strategyBadge': 'LOGICAL EXTRAPOLATION MATRIX',
          'techniqueTitle':
              'Tracing Premise Chains to Sound Inevitable Outcomes',
          'coreRule':
              'A sound conclusion must follow necessarily from the sequence of established premises.',
          'passage':
              'Maya left her bicycle outside overnight. In the morning, the seat and handlebars were covered in tiny drops of water, even though no one had touched the bike.',
          'logicChain': [
            'Bike left outside overnight -> water found on bike -> no one touched it -> rain fell overnight'
          ],
          'logicChainSteps': [
            'Bike left outside overnight',
            'Water found on seat & handlebars',
            'No human touched or moved the bike',
            'Precipitation (rain) occurred overnight',
          ],
          'conclusion': 'It rained during the night.',
          'goldenRule':
              'A valid conclusion is the natural destination of the premise chain; if any link breaks, the conclusion collapses.',
          'candidatesDiagnosis': [
            {
              'option': 'It rained during the night.',
              'isCorrect': true,
              'category': 'SOUND CONCLUSION (INEVITABLE OUTCOME)',
              'diagnosis':
                  'Necessarily follows from the established premises in the logic chain.',
            },
            {
              'option': 'Maya washed her bicycle before going to bed.',
              'isCorrect': false,
              'category': 'PREMATURE LEAP (UNFOUNDED SPECULATION)',
              'diagnosis':
                  'Leaps beyond the verified chain of evidence; introduces unstated evening chores.',
            },
            {
              'option': 'The bicycle was stored inside a garage.',
              'isCorrect': false,
              'category': 'DIRECT CONTRADICTION (REVERSED PREMISE)',
              'diagnosis':
                  'Directly conflicts with premise: Maya left the bike outside.',
            },
            {
              'option': 'Someone poured water on the bicycle on purpose.',
              'isCorrect': false,
              'category': 'IRRELEVANT DISTRACTION (UNRELATED TOPIC)',
              'diagnosis':
                  'Contradicts premise that no one touched or tampered with the bike.',
            },
          ],
          'explanation':
              'The bike was outside, dry before night, wet in the morning, and untouched. Rain is the only premise-consistent deduction.',
        },
        {
          'id': 'RDG_READINGCONCLUSION_LEARN_FALLBACK_2',
          'level': widget.level,
          'strategyBadge': 'PREMISE LINK RADAR',
          'techniqueTitle': 'Linking Intermediary Evidence to Core Deductions',
          'coreRule':
              'Do not leap past the evidence: each link in the logic chain must be physically or causally verified.',
          'passage':
              'Mrs. Ortiz baked a tray of cookies and left them on the counter to cool. When she came back, half the cookies were gone, and her young son had chocolate smudges around his mouth.',
          'logicChain': [
            'Cookies disappear -> son has chocolate on his mouth -> son ate the cookies'
          ],
          'logicChainSteps': [
            'Fresh cookies left unattended on counter',
            'Half of the cookies vanished',
            'Young son has chocolate smudges on mouth',
            'Son consumed the missing cookies',
          ],
          'conclusion': 'Her son ate some of the cookies.',
          'goldenRule':
              'Physical evidence at the scene directly anchors the actor to the outcome.',
          'candidatesDiagnosis': [
            {
              'option': 'Her son ate some of the cookies.',
              'isCorrect': true,
              'category': 'SOUND CONCLUSION (INEVITABLE OUTCOME)',
              'diagnosis':
                  'Directly anchored by the physical evidence of chocolate smudges.',
            },
            {
              'option': 'The neighbors came inside and ate the cookies.',
              'isCorrect': false,
              'category': 'PREMATURE LEAP (UNFOUNDED SPECULATION)',
              'diagnosis':
                  'Introduces unmentioned external actors with zero supporting evidence.',
            },
            {
              'option': 'The cookies were never baked at all.',
              'isCorrect': false,
              'category': 'DIRECT CONTRADICTION (REVERSED PREMISE)',
              'diagnosis':
                  'Contradicts the opening fact that Mrs. Ortiz baked them.',
            },
            {
              'option': 'Mrs. Ortiz ate the cookies herself.',
              'isCorrect': false,
              'category': 'IRRELEVANT DISTRACTION (UNRELATED TOPIC)',
              'diagnosis':
                  'Ignores the son\'s physical chocolate traces.',
            },
          ],
          'explanation':
              'The disappearance of chocolate cookies combined with chocolate traces on the child connects him conclusively to the missing items.',
        },
      ];

  void _nextCard() {
    if (_cardIndex < _quests.length - 1) {
      setState(() {
        _cardIndex++;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  Color _getCategoryColor(String category, bool isCorrect) {
    if (isCorrect) return AppColors.emerald500;
    if (category.contains('CONTRADICTION')) return AppColors.rose500;
    if (category.contains('PREMATURE')) return AppColors.amber500;
    return AppColors.indigo500;
  }

  IconData _getCategoryIcon(String category, bool isCorrect) {
    if (isCorrect) return Icons.check_circle_rounded;
    if (category.contains('CONTRADICTION')) return Icons.cancel_rounded;
    if (category.contains('PREMATURE')) return Icons.fast_forward_rounded;
    return Icons.alt_route_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final quest = _quests.isNotEmpty ? _quests[_cardIndex] : _fallbackQuests.first;
    final isLastCard = _cardIndex >= _quests.length - 1;

    final strategyBadge = quest['strategyBadge'] as String? ??
        'LOGICAL EXTRAPOLATION MATRIX';
    final techniqueTitle = quest['techniqueTitle'] as String? ??
        'Tracing Premise Chains to Sound Inevitable Outcomes';
    final coreRule = quest['coreRule'] as String? ??
        'A sound conclusion must follow necessarily from established premises.';
    final passage = quest['passage'] as String? ?? '';
    final logicChainSteps = (quest['logicChainSteps'] as List<dynamic>? ?? [])
        .cast<String>();
    final goldenRule = quest['goldenRule'] as String? ?? '';
    final candidatesDiagnosis =
        (quest['candidatesDiagnosis'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LearnPhaseScaffold(
      title: 'Logical Extrapolation Matrix',
      gameType: 'readingConclusion',
      level: widget.level,
      actionLabel: isLastCard ? 'Complete Learn Phase' : 'Next Card',
      onComplete: _nextCard,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Strategy Badge & Technique Title
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.indigo950.withValues(alpha: 0.5)
                    : AppColors.indigo50.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.4),
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
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.violet500,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.hub_rounded,
                                  size: 14.sp, color: Colors.white),
                              SizedBox(width: 5.w),
                              Flexible(
                                child: Text(
                                  strategyBadge,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Card ${_cardIndex + 1} of ${_quests.length}',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.slate400
                              : AppColors.slate600,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    techniqueTitle,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.slate900,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    coreRule,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.slate300
                          : AppColors.slate700,
                      fontSize: 12.sp,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // 2. Scenario Passage Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark
                      ? AppColors.slate700
                      : AppColors.slate200,
                  width: 1.5,
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
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.blue900.withValues(alpha: 0.4)
                              : AppColors.blue50,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'SCENARIO PREMISES',
                          style: TextStyle(
                            color: AppColors.blue500,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(Icons.auto_stories_rounded,
                          size: 14.sp,
                          color: isDark
                              ? AppColors.slate400
                              : AppColors.slate500),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    passage,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.slate900,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // 3. Logic Chain Trajectory (Extrapolation Matrix)
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.slate800.withValues(alpha: 0.7)
                    : AppColors.slate100,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark
                      ? AppColors.slate700
                      : AppColors.slate300,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.route_rounded,
                          size: 18.sp, color: AppColors.violet500),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'PREMISE-TO-CONCLUSION MATRIX',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.slate300
                                : AppColors.slate800,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  ...List.generate(logicChainSteps.length, (sIdx) {
                    final stepText = logicChainSteps[sIdx];
                    final isConclusion = sIdx == logicChainSteps.length - 1;
                    final stepNumber = sIdx + 1;

                    return Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: isConclusion
                                ? (isDark
                                    ? AppColors.emerald950
                                        .withValues(alpha: 0.4)
                                    : AppColors.emerald50)
                                : (isDark
                                    ? AppColors.slate900
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isConclusion
                                  ? AppColors.emerald500
                                  : (isDark
                                      ? AppColors.slate700
                                      : AppColors.slate300),
                              width: isConclusion ? 1.6 : 1.0,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22.w,
                                height: 22.h,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isConclusion
                                      ? AppColors.emerald500
                                      : AppColors.violet500,
                                ),
                                alignment: Alignment.center,
                                child: isConclusion
                                    ? Icon(Icons.check_rounded,
                                        size: 14.sp, color: Colors.white)
                                    : Text(
                                        '$stepNumber',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isConclusion
                                          ? 'LOGICAL CONCLUSION'
                                          : 'PREMISE $stepNumber',
                                      style: TextStyle(
                                        color: isConclusion
                                            ? AppColors.emerald500
                                            : AppColors.violet500,
                                        fontSize: 9.sp,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    SizedBox(height: 3.h),
                                    Text(
                                      stepText,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.slate900,
                                        fontSize: 12.sp,
                                        fontWeight: isConclusion
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (sIdx < logicChainSteps.length - 1) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.h),
                            child: Icon(
                              Icons.arrow_downward_rounded,
                              size: 16.sp,
                              color: isDark
                                  ? AppColors.slate500
                                  : AppColors.slate400,
                            ),
                          ),
                        ],
                      ],
                    );
                  }),

                  if (goldenRule.isNotEmpty) ...[
                    SizedBox(height: 14.h),
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.amber900.withValues(alpha: 0.35)
                            : AppColors.amber100,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: AppColors.amber500.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_rounded,
                              size: 16.sp, color: AppColors.amber500),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              goldenRule,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.amber400
                                    : AppColors.amber900,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
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

            SizedBox(height: 18.h),

            // 4. Candidate Options Diagnosis (Sound vs Fallacies)
            Text(
              'CANDIDATE CONCLUSIONS DIAGNOSIS',
              style: TextStyle(
                color: isDark ? AppColors.slate400 : AppColors.slate600,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Which conclusion necessarily follows from the premises?',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.slate900,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10.h),

            ...candidatesDiagnosis.map((cand) {
              final optText = cand['option'] as String? ?? '';
              final isCorrect = cand['isCorrect'] as bool? ?? false;
              final cat = cand['category'] as String? ?? '';
              final diagnosis = cand['diagnosis'] as String? ?? '';
              final color = _getCategoryColor(cat, isCorrect);
              final icon = _getCategoryIcon(cat, isCorrect);

              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate900 : Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: color.withValues(alpha: isCorrect ? 0.8 : 0.45),
                    width: isCorrect ? 1.8 : 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, size: 16.sp, color: color),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              SizedBox(height: 5.h),
                              Text(
                                optText,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.slate900,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.slate800.withValues(alpha: 0.5)
                            : AppColors.slate50,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        diagnosis,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.slate300
                              : AppColors.slate700,
                          fontSize: 11.sp,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
