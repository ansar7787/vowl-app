import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive Learn Phase screen for Cloze Test ("Collocation & Grammar Filter").
///
/// Teaches learners how surrounding prepositions, articles, and parts of speech
/// constrain which word fits, and how to filter subtle distractors.
class ClozeTestLearnScreen extends StatefulWidget {
  final int level;

  const ClozeTestLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<ClozeTestLearnScreen> createState() => _ClozeTestLearnScreenState();
}

class _ClozeTestLearnScreenState extends State<ClozeTestLearnScreen> {
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
        'assets/curriculum/reading/clozeTest_learn_${startLevel}_$endLevel.json';

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
          'id': 'RDG_CLOZETEST_LEARN_FALLBACK_1',
          'level': widget.level,
          'strategyBadge': 'COLLOCATION & GRAMMAR FILTER',
          'techniqueTitle':
              'Filtering Candidates by Surrounding Prepositions and Articles',
          'coreRule':
              'Analyze preceding articles ("a", "an", "the") and prepositions to narrow down the syntactic class.',
          'instruction':
              'Examine the collocation and grammatical constraints governing this sentence blank.',
          'passage': "Please close the ____ — it's cold outside.",
          'missingWord': 'window',
          'correctAnswer': 'window',
          'wordCategory': 'noun',
          'grammarConstraint': '[noun: fits "close the ____ — it\'s cold"]',
          'precedingCue': 'close the',
          'followingCue': "— it's cold",
          'distractorAnalysis': [
            {
              'word': 'window',
              'status': 'VALID',
              'reason':
                  'Accurately completes "close the window" with precise grammatical agreement and keeps cold air out.',
            },
            {
              'word': 'road',
              'status': 'INVALID',
              'reason':
                  'A road cannot be closed to insulate a room from cold weather.',
            },
            {
              'word': 'shelf',
              'status': 'INVALID',
              'reason':
                  'A shelf has no open/close mechanism affecting room temperature.',
            },
            {
              'word': 'river',
              'status': 'INVALID',
              'reason':
                  'A river cannot be physically closed to keep out cold air.',
            },
          ],
          'options': ['window', 'road', 'shelf', 'river'],
          'explanation':
              'A window can be opened or closed, and closing it keeps cold air out.',
          'hint':
              'Think of the glass part of a room that can be opened or shut.',
        },
        {
          'id': 'RDG_CLOZETEST_LEARN_FALLBACK_2',
          'level': widget.level,
          'strategyBadge': 'PREPOSITIONAL COLLOCATION',
          'techniqueTitle':
              'Identifying Fixed Collocations and Natural Word Pairings',
          'coreRule':
              'Test collocations: native English favors specific verb-noun or adjective-noun bonds.',
          'instruction':
              'Examine the collocation and grammatical constraints governing this sentence blank.',
          'passage': 'The bus stop is just across the ____ from my house.',
          'missingWord': 'street',
          'correctAnswer': 'street',
          'wordCategory': 'noun',
          'grammarConstraint': '[noun: fits "across the ____ from"]',
          'precedingCue': 'across the',
          'followingCue': 'from my house',
          'distractorAnalysis': [
            {
              'word': 'street',
              'status': 'VALID',
              'reason':
                  'The prepositional idiom "across the street" is a canonical English collocation for location.',
            },
            {
              'word': 'shelf',
              'status': 'INVALID',
              'reason':
                  'A shelf does not exist between houses and bus stops.',
            },
            {
              'word': 'spoon',
              'status': 'INVALID',
              'reason':
                  'Collocationally meaningless in urban transit context.',
            },
            {
              'word': 'cloud',
              'status': 'INVALID',
              'reason':
                  'Bus stops cannot be situated across clouds from houses.',
            },
          ],
          'options': ['shelf', 'street', 'spoon', 'cloud'],
          'explanation':
              'A street is a road in a town, and "across the street" means on the other side of it.',
          'hint':
              'This word names the road people cross to get to the other side.',
        },
      ];

  void _onNext() {
    if (_cardIndex < _quests.length - 1) {
      setState(() {
        _cardIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentQuest = _quests[_cardIndex];

    final badge =
        currentQuest['strategyBadge'] as String? ?? 'COLLOCATION & GRAMMAR FILTER';
    final technique = currentQuest['techniqueTitle'] as String? ??
        'Analyzing Sentence Blank Constraints';
    final rule = currentQuest['coreRule'] as String? ??
        'Analyze surrounding words to determine required grammar and natural collocation.';
    final passage = currentQuest['passage'] as String? ?? '';
    final missingWord = currentQuest['missingWord'] as String? ?? '';
    final wordCategory = currentQuest['wordCategory'] as String? ?? 'noun';
    final grammarConstraint = currentQuest['grammarConstraint'] as String? ??
        '[$wordCategory: contextually constrained]';
    final precedingCue = currentQuest['precedingCue'] as String? ?? '';
    final followingCue = currentQuest['followingCue'] as String? ?? '';

    final rawAnalysis = (currentQuest['distractorAnalysis'] as List<dynamic>? ??
            [])
        .cast<Map<String, dynamic>>();

    final hasNext = _cardIndex < _quests.length - 1;

    return LearnPhaseScaffold(
      title: 'Collocation & Grammar Filter',
      gameType: 'clozeTest',
      level: widget.level,
      actionLabel: hasNext ? 'Next Card' : 'Complete Learn Phase',
      onComplete: _onNext,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Strategy Badge & Technique Card
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
                      Text(
                        'CARD ${_cardIndex + 1} OF ${_quests.length}',
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
                  SizedBox(height: 12.h),
                  Text(
                    technique,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.slate900,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_rounded,
                        color: AppColors.amber500,
                        size: 16.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          rule,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.slate300
                                : AppColors.slate700,
                            fontSize: 13.sp,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 18.h),

            // Passage with Stylized Blank Slot
            Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark
                      ? AppColors.slate800
                      : AppColors.slate200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
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
                        Icons.menu_book_rounded,
                        color: AppColors.indigo500,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'SENTENCE CONTEXT WITH BLANK',
                          style: TextStyle(
                            color: AppColors.indigo500,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          wordCategory.toUpperCase(),
                          style: TextStyle(
                            color: AppColors.indigo500,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Passage text with highlighted blank
                  Text(
                    passage,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.slate900,
                      fontSize: 16.sp,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Syntactic Constraint Pill
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: AppColors.indigo500.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: AppColors.indigo500.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_alt_rounded,
                          color: AppColors.indigo500,
                          size: 18.sp,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            grammarConstraint,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.indigo400
                                  : AppColors.indigo600,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (precedingCue.isNotEmpty || followingCue.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        if (precedingCue.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.slate800
                                  : AppColors.slate100,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'Preceding cue: "$precedingCue"',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.slate300
                                    : AppColors.slate700,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (followingCue.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.slate800
                                  : AppColors.slate100,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'Following cue: "$followingCue"',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.slate300
                                    : AppColors.slate700,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 18.h),

            // Solution Anchor Card
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.emerald950.withValues(alpha: 0.3)
                    : AppColors.emerald50,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: 0.4),
                  width: 1.5,
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
                          'TARGET COMPLETION',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.emerald400
                                : AppColors.emerald600,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.emerald500,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          missingWord.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    currentQuest['explanation'] as String? ??
                        'Accurately completes the sentence both grammatically and collocationally.',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.slate900,
                      fontSize: 14.sp,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 18.h),

            // Distractor Filter & Analysis
            Text(
              'CANDIDATE WORD EVALUATION',
              style: TextStyle(
                color: isDark ? AppColors.slate400 : AppColors.slate600,
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 10.h),

            ...rawAnalysis.map((item) {
              final word = item['word'] as String? ?? '';
              final status = item['status'] as String? ?? 'INVALID';
              final reason = item['reason'] as String? ?? '';
              final isValid = status == 'VALID';

              final color =
                  isValid ? AppColors.emerald500 : AppColors.rose500;
              final bgColor = isValid
                  ? (isDark
                      ? AppColors.emerald950.withValues(alpha: 0.25)
                      : AppColors.emerald50)
                  : (isDark
                      ? AppColors.red900.withValues(alpha: 0.2)
                      : AppColors.red50);

              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: color.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isValid
                            ? Icons.check_rounded
                            : Icons.close_rounded,
                        color: color,
                        size: 16.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '"$word"',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.slate900,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            reason,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.slate300
                                  : AppColors.slate700,
                              fontSize: 12.sp,
                              height: 1.35,
                            ),
                          ),
                        ],
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
