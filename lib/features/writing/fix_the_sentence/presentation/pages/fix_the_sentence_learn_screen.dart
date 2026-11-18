import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive Learn Phase screen for Fix The Sentence ("Common Error Gallery & The Editor's Eye").
///
/// Teaches learners how to spot, categorize, and surgically repair common grammatical,
/// syntactic, and inflectional errors before testing their editing skills.
class FixTheSentenceLearnScreen extends StatefulWidget {
  final int level;

  const FixTheSentenceLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<FixTheSentenceLearnScreen> createState() =>
      _FixTheSentenceLearnScreenState();
}

class _FixTheSentenceLearnScreenState extends State<FixTheSentenceLearnScreen> {
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
        'assets/curriculum/writing/fixTheSentence_learn_${startLevel}_$endLevel.json';

    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final levelQuests = rawQuests.where((q) {
        final id = q['id'] as String? ?? '';
        final match = RegExp(r'_L(\d+)_').firstMatch(id);
        if (match != null) {
          return int.parse(match.group(1)!) == widget.level;
        }
        return false;
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
          'id': 'WRT_FIXTHESENTENCE_LEARN_FALLBACK_1',
          'instruction': 'IDENTIFY & STUDY THE ERROR',
          'passage': 'My cousin play football at the park every Sunday.',
          'missingWord': 'play',
          'correctAnswer': 'plays',
          'errorType': 'Agreement Error',
          'hint': 'Think about how many people the subject names, then check whether the verb ending matches.',
          'explanation':
              'One person is doing the action, so the simple-present verb takes -s: "plays". "Playing" and "to play" cannot work as the main verb here.',
        },
        {
          'id': 'WRT_FIXTHESENTENCE_LEARN_FALLBACK_2',
          'instruction': 'IDENTIFY & STUDY THE ERROR',
          'passage': 'The bus to the airport leave from Gate 4 every twenty minutes.',
          'missingWord': 'leave',
          'correctAnswer': 'leaves',
          'errorType': 'Agreement Error',
          'hint': 'Is "the bus" one thing or several? Let the answer decide the verb ending.',
          'explanation':
              '"The bus" is a singular subject, so the present-simple verb requires the third-person -s inflection: "leaves".',
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
        gameType: 'fixTheSentence',
        level: widget.level,
        phase: 'learn',
      );
      context.pushReplacement(
        '/practice?category=writing&gameType=fixTheSentence&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentQuest = _quests[_cardIndex];
    final passage = currentQuest['passage'] as String? ?? '';
    final missingWord = currentQuest['missingWord'] as String? ?? '';
    final correctAnswer = currentQuest['correctAnswer'] as String? ?? '';
    final errorType = currentQuest['errorType'] as String? ?? 'Grammar Error';
    final explanation = currentQuest['explanation'] as String? ?? '';
    final hint = currentQuest['hint'] as String? ?? '';
    final isLastCard = _cardIndex == _quests.length - 1;

    final correctedPassage = passage.replaceFirst(missingWord, correctAnswer);

    return LearnPhaseScaffold(
      title: 'Common Error Gallery',
      gameType: 'fixTheSentence',
      level: widget.level,
      actionLabel: isLastCard ? 'Start Error Surgeon Gym' : 'Next Error Pattern',
      onComplete: _onNext,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pacing & Progress Tracker Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: AppColors.rose500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColors.rose500.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bug_report_outlined,
                        size: 14.sp,
                        color: AppColors.rose500,
                      ),
                      SizedBox(width: 5.w),
                      Flexible(
                        child: Text(
                          'PATTERN ${_cardIndex + 1} OF ${_quests.length}',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.rose500,
                            letterSpacing: 0.6,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.slate800 : AppColors.slate200,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Level ${widget.level}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.slate400 : AppColors.slate600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Error Spotlight Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.rose500.withValues(alpha: 0.4),
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
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: AppColors.rose500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          errorType.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.rose500,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'FLAWED PASSAGE DETECTED',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.slate400 : AppColors.slate600,
                            letterSpacing: 0.8,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Passage with highlighted flawed word
                  RichText(
                    text: TextSpan(
                      children: _buildPassageSpans(
                        passage,
                        missingWord,
                        isDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Diagnostic Repair Card (Contrasting View)
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16.sp,
                        color: AppColors.emerald500,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'SURGICAL REPAIR (CORRECTED)',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.emerald500,
                            letterSpacing: 0.8,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    correctedPassage,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.slate100 : AppColors.slate900,
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Substitution Pill
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.slate800 : AppColors.slate100,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          missingWord,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.rose500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 14.sp,
                            color: isDark ? AppColors.slate400 : AppColors.slate600,
                          ),
                        ),
                        Text(
                          correctAnswer,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.emerald500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Editor's Diagnostic Rule Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : AppColors.slate50,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 16.sp,
                        color: AppColors.amber500,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'EDITOR\'S GRAMMATICAL RULE',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.amber500,
                            letterSpacing: 0.8,
                          ),
                          overflow: TextOverflow.ellipsis,
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
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.slate200 : AppColors.slate800,
                      height: 1.45,
                    ),
                  ),
                  if (hint.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppColors.amber500.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.psychology_outlined,
                            size: 14.sp,
                            color: AppColors.amber500,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              hint,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.slate300 : AppColors.slate700,
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
          ],
        ),
      ),
    );
  }

  List<InlineSpan> _buildPassageSpans(
    String passage,
    String missingWord,
    bool isDark,
  ) {
    if (missingWord.isEmpty || !passage.contains(missingWord)) {
      return [
        TextSpan(
          text: passage,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.slate100 : AppColors.slate900,
            height: 1.45,
          ),
        ),
      ];
    }

    final index = passage.indexOf(missingWord);
    final before = passage.substring(0, index);
    final after = passage.substring(index + missingWord.length);

    return [
      TextSpan(
        text: before,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.slate100 : AppColors.slate900,
          height: 1.45,
        ),
      ),
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: AppColors.rose500.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(
              color: AppColors.rose500,
              width: 1.5,
            ),
          ),
          child: Text(
            missingWord,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.rose500,
            ),
          ),
        ),
      ),
      TextSpan(
        text: after,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.slate100 : AppColors.slate900,
          height: 1.45,
        ),
      ),
    ];
  }
}
