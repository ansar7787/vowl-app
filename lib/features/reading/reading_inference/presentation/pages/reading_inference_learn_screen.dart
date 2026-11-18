import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive Learn Phase screen for Reading Inference ("Between the Lines Radar").
///
/// Teaches users how to separate explicit statements from implicit attitudes and subtext,
/// highlighting clues and diagnosing literal traps vs. evidence-anchored deductions.
class ReadingInferenceLearnScreen extends StatefulWidget {
  final int level;

  const ReadingInferenceLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<ReadingInferenceLearnScreen> createState() =>
      _ReadingInferenceLearnScreenState();
}

class _ReadingInferenceLearnScreenState
    extends State<ReadingInferenceLearnScreen> {
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
        'assets/curriculum/reading/readingInference_learn_${startLevel}_$endLevel.json';

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
          'id': 'RDG_READINGINFERENCE_LEARN_FALLBACK_1',
          'level': widget.level,
          'strategyBadge': 'EXPLICIT VS IMPLICIT RADAR',
          'techniqueTitle': 'Distinguishing Direct Fact From Unspoken Subtext',
          'coreRule':
              'Look past literal definitions: what circumstance or emotional reality makes this statement true?',
          'passageTopic': 'Morning Routine',
          'passage':
              '[Morning Routine] Every morning at seven, Kofi makes his bed, feeds his cat, and sits down to breakfast.',
          'cleanPassage':
              'Every morning at seven, Kofi makes his bed, feeds his cat, and sits down to breakfast.',
          'question': "What do Kofi's morning habits suggest?",
          'clueWords': ['Every morning at seven', 'makes his bed, feeds his cat'],
          'explicitStatement':
              'Observable words: "Every morning at seven, Kofi does the same tasks."',
          'implicitSubtext':
              'Underlying reality: They follow the same pattern each day.',
          'goldenRule':
              'A valid inference is never a guess: it is the only deduction that ties all clue words together without adding unstated facts.',
          'candidatesDiagnosis': [
            {
              'option': 'They follow the same pattern each day.',
              'isCorrect': true,
              'category': 'GROUNDED INFERENCE (EVIDENCE-ANCHORED)',
              'diagnosis':
                  'Directly deduced from the textual evidence ("Every morning at seven", "same sequence").',
            },
            {
              'option': 'He has to hurry to get to work on time.',
              'isCorrect': false,
              'category': 'WILD ASSUMPTION (UNFOUNDED LEAP)',
              'diagnosis':
                  'Extrapolates beyond what the passage directly supports; introduces unverified work stress.',
            },
            {
              'option': 'He lives alone with his cat.',
              'isCorrect': false,
              'category': 'LITERAL TRAP (SURFACE REPETITION)',
              'diagnosis':
                  'Focuses on literal mention of the cat without evidence of who else lives in the house.',
            },
            {
              'option': 'He prefers cooking to any other activity.',
              'isCorrect': false,
              'category': 'CONTRADICTION (OPPOSITE SUBTEXT)',
              'diagnosis':
                  'Eating breakfast does not mean cooking is his favorite passion.',
            },
          ],
          'explanation':
              'Kofi does the same tasks in the same sequence at the exact same hour every day.',
        },
        {
          'id': 'RDG_READINGINFERENCE_LEARN_FALLBACK_2',
          'level': widget.level,
          'strategyBadge': 'BEHAVIORAL EVIDENCE RADAR',
          'techniqueTitle': 'Decoding Behavioral Clues and Habit Patterns',
          'coreRule':
              'Actions and habits reveal priorities and unstated emotions far more reliably than spoken claims.',
          'passageTopic': 'Arrivals Hall',
          'passage':
              '[Arrivals Hall] Hana runs across the arrivals hall and hugs her grandmother tightly. "Two whole years!" she says.',
          'cleanPassage':
              'Hana runs across the arrivals hall and hugs her grandmother tightly. "Two whole years!" she says.',
          'question':
              "What does Hana's reaction suggest about her and her grandmother?",
          'clueWords': ['runs across the arrivals hall', 'Two whole years!'],
          'explicitStatement':
              'Observable words: "Hana runs and hugs her grandmother, saying two whole years."',
          'implicitSubtext':
              'Underlying reality: They have been apart for a long time.',
          'goldenRule':
              'Physical actions like running and embracing confirm deep emotion and relief after long absence.',
          'candidatesDiagnosis': [
            {
              'option': 'They have been apart for a long time.',
              'isCorrect': true,
              'category': 'GROUNDED INFERENCE (EVIDENCE-ANCHORED)',
              'diagnosis':
                  'The tight hug combined with "Two whole years!" indicates long separation.',
            },
            {
              'option': 'They see each other most weekends.',
              'isCorrect': false,
              'category': 'CONTRADICTION (OPPOSITE SUBTEXT)',
              'diagnosis':
                  'Directly contradicts "Two whole years!" of separation.',
            },
            {
              'option': 'They met for the first time today.',
              'isCorrect': false,
              'category': 'WILD ASSUMPTION (UNFOUNDED LEAP)',
              'diagnosis':
                  'She is her grandmother, not a stranger met for the first time.',
            },
            {
              'option': 'They argued the last time they met.',
              'isCorrect': false,
              'category': 'LITERAL TRAP (SURFACE REPETITION)',
              'diagnosis':
                  'No mention of conflict or negative feelings exists in the text.',
            },
          ],
          'explanation':
              'The emotional reunion and two-year timeframe point unmistakably to long physical separation.',
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
    if (category.contains('LITERAL')) return AppColors.amber500;
    if (category.contains('CONTRADICTION')) return AppColors.rose500;
    return AppColors.violet500;
  }

  IconData _getCategoryIcon(String category, bool isCorrect) {
    if (isCorrect) return Icons.check_circle_rounded;
    if (category.contains('LITERAL')) return Icons.content_copy_rounded;
    if (category.contains('CONTRADICTION')) return Icons.cancel_rounded;
    return Icons.explore_off_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final quest = _quests.isNotEmpty ? _quests[_cardIndex] : _fallbackQuests.first;
    final isLastCard = _cardIndex >= _quests.length - 1;

    final strategyBadge =
        quest['strategyBadge'] as String? ?? 'BETWEEN THE LINES RADAR';
    final techniqueTitle =
        quest['techniqueTitle'] as String? ?? 'Subtext Analysis';
    final coreRule = quest['coreRule'] as String? ??
        'Analyze unspoken subtext anchored in textual clues.';
    final passageTopic = quest['passageTopic'] as String? ?? 'Passage Scenario';
    final cleanPassage = quest['cleanPassage'] as String? ??
        quest['passage'] as String? ??
        '';
    final question = quest['question'] as String? ?? 'What can be inferred?';
    final clueWords = (quest['clueWords'] as List<dynamic>? ?? []).cast<String>();
    final explicitStatement = quest['explicitStatement'] as String? ?? '';
    final implicitSubtext = quest['implicitSubtext'] as String? ?? '';
    final goldenRule = quest['goldenRule'] as String? ?? '';
    final candidatesDiagnosis =
        (quest['candidatesDiagnosis'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LearnPhaseScaffold(
      title: 'Between the Lines Radar',
      gameType: 'readingInference',
      level: widget.level,
      actionLabel: isLastCard ? 'Complete Learn Phase' : 'Next Card',
      onComplete: _nextCard,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Radar Strategy Badge & Technique Title
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
                              Icon(Icons.radar_rounded,
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

            // 2. Scenario Passage & Clue Words
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
                          passageTopic,
                          style: TextStyle(
                            color: AppColors.blue500,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(Icons.menu_book_rounded,
                          size: 14.sp,
                          color: isDark
                              ? AppColors.slate400
                              : AppColors.slate500),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    cleanPassage,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.slate900,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  if (clueWords.isNotEmpty) ...[
                    SizedBox(height: 14.h),
                    Text(
                      'DETECTED RADAR CLUES:',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.slate400
                            : AppColors.slate600,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 6.h,
                      children: clueWords.map((clue) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.indigo950.withValues(alpha: 0.6)
                                : AppColors.indigo50,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: AppColors.indigo500.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_rounded,
                                  size: 12.sp, color: AppColors.indigo500),
                              SizedBox(width: 5.w),
                              Flexible(
                                child: Text(
                                  clue,
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.indigo400
                                        : AppColors.indigo600,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // 3. Between The Lines Radar Analysis (Explicit vs Implicit)
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
                      Icon(Icons.compare_arrows_rounded,
                          size: 18.sp, color: AppColors.blue500),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'BETWEEN-THE-LINES DECODER',
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

                  // Explicit Fact
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.blue900.withValues(alpha: 0.35)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.blue500.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.visibility_rounded,
                            size: 16.sp, color: AppColors.blue500),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EXPLICIT SURFACE WORDS',
                                style: TextStyle(
                                  color: AppColors.blue500,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                explicitStatement,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.slate900,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // Implicit Subtext
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.emerald950.withValues(alpha: 0.35)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.emerald500.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.psychology_rounded,
                            size: 16.sp, color: AppColors.emerald500),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DECODED UNSTATED SUBTEXT',
                                style: TextStyle(
                                  color: AppColors.emerald500,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                implicitSubtext,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.slate900,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (goldenRule.isNotEmpty) ...[
                    SizedBox(height: 12.h),
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

            // 4. Candidates Diagnosis (Valid Inference vs Traps)
            Text(
              'CANDIDATE OPTIONS RADAR DIAGNOSIS',
              style: TextStyle(
                color: isDark ? AppColors.slate400 : AppColors.slate600,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              question,
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
