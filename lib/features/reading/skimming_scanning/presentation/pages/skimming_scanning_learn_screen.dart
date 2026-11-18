import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive Learn Phase screen for Skimming & Scanning ("Visual Saccade & Key Anchor Finder").
///
/// Teaches learners how to execute high-speed visual jumps (saccades), recognize
/// typographic shape patterns (capital letters, digits, punctuation), and filter distractors.
class SkimmingScanningLearnScreen extends StatefulWidget {
  final int level;

  const SkimmingScanningLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<SkimmingScanningLearnScreen> createState() =>
      _SkimmingScanningLearnScreenState();
}

class _SkimmingScanningLearnScreenState
    extends State<SkimmingScanningLearnScreen> {
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
        'assets/curriculum/reading/skimmingScanning_learn_${startLevel}_$endLevel.json';

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
          'id': 'RDG_SKIMMINGSCANNING_LEARN_FALLBACK_1',
          'level': widget.level,
          'strategyBadge': 'VISUAL SACCADE & SCANNING RADAR',
          'techniqueTitle':
              'Spotting Capitalized Proper Nouns and Day Markers at High Speed',
          'coreRule':
              'Scan with visual jumps (saccades) looking for shape patterns like capital letters and numerals.',
          'instruction':
              'Master high-speed scanning by identifying visual anchors and target entities.',
          'passage': "Maria's book club meets every Thursday evening.",
          'targetItem': 'Thursday',
          'targetInfo': 'Day of the week',
          'correctAnswer': 'Thursday',
          'distractorAnalysis': [
            {
              'word': 'Thursday',
              'status': 'TARGET FOUND',
              'reason':
                  'Capitalized weekday noun directly satisfying the search for "Day of the week".',
            },
            {
              'word': 'Tuesday',
              'status': 'DISTRACTOR',
              'reason':
                  'A valid day of the week, but absent from this specific passage text.',
            },
            {
              'word': 'evening',
              'status': 'DISTRACTOR',
              'reason':
                  'Indicates time of day rather than a specific weekday name.',
            },
            {
              'word': 'book',
              'status': 'DISTRACTOR',
              'reason':
                  'A common noun related to the activity, not a calendar day marker.',
            },
          ],
          'options': ['Tuesday', 'Thursday', 'evening', 'book'],
          'explanation':
              'The sentence names Thursday as the meeting day, not Tuesday.',
          'hint': 'Look for the name of a day of the week.',
        },
        {
          'id': 'RDG_SKIMMINGSCANNING_LEARN_FALLBACK_2',
          'level': widget.level,
          'strategyBadge': 'CAPITALIZATION & NUMERIC ANCHORS',
          'techniqueTitle':
              'Scanning for Digits, Timestamps, and Numerical Anchors',
          'coreRule':
              'Do not read every word linearly: let peripheral vision locate category anchors.',
          'instruction':
              'Master high-speed scanning by identifying visual anchors and target entities.',
          'passage': "The library closes at six o'clock tonight.",
          'targetItem': 'six',
          'targetInfo': 'Closing time',
          'correctAnswer': 'six',
          'distractorAnalysis': [
            {
              'word': 'six',
              'status': 'TARGET FOUND',
              'reason':
                  'Numerical time indicator directly modifying "o\'clock" to indicate closing hour.',
            },
            {
              'word': 'seven',
              'status': 'DISTRACTOR',
              'reason':
                  'A plausible time digit, but entirely absent from the passage text.',
            },
            {
              'word': 'tonight',
              'status': 'DISTRACTOR',
              'reason':
                  'A temporal adverb indicating general timeframe, not specific hour.',
            },
            {
              'word': 'library',
              'status': 'DISTRACTOR',
              'reason':
                  'The venue noun, unrelated to the requested clock time.',
            },
          ],
          'options': ['seven', 'tonight', 'six', 'library'],
          'explanation':
              "The library's closing time is six; seven does not appear as a time here.",
          'hint': 'Search for the number that tells the time.',
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

    final badge = currentQuest['strategyBadge'] as String? ??
        'VISUAL SACCADE & SCANNING RADAR';
    final technique = currentQuest['techniqueTitle'] as String? ??
        'Spotting Visual Anchors at Speed';
    final rule = currentQuest['coreRule'] as String? ??
        'Scan with visual jumps looking for shape patterns like capital letters and numerals.';
    final passage = currentQuest['passage'] as String? ?? '';
    final targetItem = currentQuest['targetItem'] as String? ?? '';
    final targetInfo = currentQuest['targetInfo'] as String? ?? 'Target Info';

    final rawAnalysis = (currentQuest['distractorAnalysis'] as List<dynamic>? ??
            [])
        .cast<Map<String, dynamic>>();

    final hasNext = _cardIndex < _quests.length - 1;

    return LearnPhaseScaffold(
      title: 'Visual Saccade & Key Anchor Finder',
      gameType: 'skimmingScanning',
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
                        Icons.visibility_rounded,
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

            // Target Objective Card
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.violet500.withValues(alpha: 0.15)
                    : AppColors.indigo50.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.violet500.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.violet500.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.radar_rounded,
                      color: AppColors.violet500,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SEARCH TARGET CRITERION',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.violet500
                                : AppColors.indigo600,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          targetInfo,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.slate900,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 18.h),

            // Passage Scan Box
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
                        Icons.document_scanner_rounded,
                        color: AppColors.indigo500,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'PASSAGE RADAR SCAN',
                          style: TextStyle(
                            color: AppColors.indigo500,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    passage,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.slate900,
                      fontSize: 16.sp,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 18.h),

            // Target Anchor Discovery Banner
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
                        Icons.gps_fixed_rounded,
                        color: AppColors.emerald500,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'KEY ANCHOR IDENTIFIED',
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
                          targetItem.toUpperCase(),
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
                        'The target entity was located immediately via visual scanning.',
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

            // Candidate Distractor Evaluation
            Text(
              'CANDIDATE SCAN EVALUATION',
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
              final status = item['status'] as String? ?? 'DISTRACTOR';
              final reason = item['reason'] as String? ?? '';
              final isFound = status == 'TARGET FOUND';

              final color =
                  isFound ? AppColors.emerald500 : AppColors.rose500;
              final bgColor = isFound
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
                        isFound
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
                              Flexible(
                                child: Text(
                                  '"$word"',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.slate900,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
