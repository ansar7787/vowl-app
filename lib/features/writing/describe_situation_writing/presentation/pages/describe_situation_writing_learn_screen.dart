import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive Learn Phase screen for Describe Situation Writing ("Sensory & Factual Vocabulary Bank").
///
/// Teaches learners how to break down any scene or situation into core visual
/// elements, choose active descriptive keywords, and model a coherent observational summary.
class DescribeSituationWritingLearnScreen extends StatefulWidget {
  final int level;

  const DescribeSituationWritingLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<DescribeSituationWritingLearnScreen> createState() =>
      _DescribeSituationWritingLearnScreenState();
}

class _DescribeSituationWritingLearnScreenState
    extends State<DescribeSituationWritingLearnScreen> {
  int _cardIndex = 0;
  int _selectedCategoryIndex = 0;
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
        'assets/curriculum/writing/describeSituationWriting_learn_${startLevel}_$endLevel.json';

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
          'id': 'WRT_DESCRIBESITUATIONWRITING_LEARN_FALLBACK_1',
          'instruction': 'STUDY SENSORY & FACTUAL DETAILS',
          'situation':
              'It is seven o\'clock on a weekday morning. Describe what you do at home before you leave for work or school.',
          'emojis': ['⏰', '🪥', '🥣', '🎒'],
          'keywords': {
            '0': ['ALARM', 'WAKE', 'SEVEN'],
            '1': ['TEETH', 'BRUSH', 'BATHROOM'],
            '2': ['CEREAL', 'MILK', 'KITCHEN'],
            '3': ['BAG', 'DOOR', 'LEAVE'],
          },
          'minWords': 15,
          'hint': 'Say what you do in chronological order with one clear action in each sentence.',
          'explanation':
              'Using active verbs and naming familiar objects grounds the reader in the immediate scene.',
          'modelAnswer':
              'My alarm rings at seven, so I wake up and brush my teeth. I eat cereal with milk in the kitchen. Then I take my bag and leave.',
        },
        {
          'id': 'WRT_DESCRIBESITUATIONWRITING_LEARN_FALLBACK_2',
          'instruction': 'STUDY SENSORY & FACTUAL DETAILS',
          'situation':
              'The English lesson is about to start. Describe what the teacher and the students do in the classroom.',
          'emojis': ['🗣️', '📖', '🪑', '👩‍🏫'],
          'keywords': {
            '0': ['TALK', 'SAY', 'GREET'],
            '1': ['BOOK', 'OPEN', 'PAGE'],
            '2': ['DESK', 'SIT', 'CHAIR'],
            '3': ['TEACHER', 'BOARD', 'WRITE'],
          },
          'minWords': 15,
          'hint': 'Give the teacher two actions and the students two actions to establish clear roles.',
          'explanation':
              'Contrasting distinct actors in the scene provides natural narrative balance and momentum.',
          'modelAnswer':
              'The teacher comes in and greets everyone. The students sit at their desks and open their books. Then the teacher writes a new word on the board.',
        },
      ];

  void _onNext() {
    if (_cardIndex < _quests.length - 1) {
      setState(() {
        _cardIndex++;
        _selectedCategoryIndex = 0;
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'describeSituationWriting',
        level: widget.level,
        phase: 'learn',
      );
      context.pushReplacement(
        '/practice?category=writing&gameType=describeSituationWriting&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentQuest = _quests[_cardIndex];
    final situation = currentQuest['situation'] as String? ?? '';
    final emojis = (currentQuest['emojis'] as List<dynamic>? ?? []).cast<String>();
    final keywordsMap = (currentQuest['keywords'] as Map<String, dynamic>? ?? {});
    final modelAnswer = currentQuest['modelAnswer'] as String? ?? '';
    final explanation = currentQuest['explanation'] as String? ?? '';
    final isLastCard = _cardIndex == _quests.length - 1;

    final selectedKey = _selectedCategoryIndex.toString();
    final activeKeywords = (keywordsMap[selectedKey] as List<dynamic>? ?? []).cast<String>();

    return LearnPhaseScaffold(
      title: 'Scene Observation & Vocab Bank',
      gameType: 'describeSituationWriting',
      level: widget.level,
      actionLabel: isLastCard ? 'Start Guided Practice' : 'Next Situation Card',
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
                    color: AppColors.indigo500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColors.indigo500.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_rounded,
                        size: 14.sp,
                        color: AppColors.indigo500,
                      ),
                      SizedBox(width: 5.w),
                      Flexible(
                        child: Text(
                          'SITUATION ${_cardIndex + 1} OF ${_quests.length}',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo500,
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

            // Situation Stimulus Card
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
                        Icons.camera_alt_outlined,
                        size: 16.sp,
                        color: AppColors.indigo500,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'OBSERVE THE SCENARIO',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo500,
                            letterSpacing: 0.8,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    situation,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.slate100 : AppColors.slate900,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Emoji Scene Elements Selector
            Text(
              'SCENE PILLARS & BOOSTER KEYWORDS',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.slate400 : AppColors.slate600,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(emojis.length, (idx) {
                final isSelected = idx == _selectedCategoryIndex;
                final emoji = emojis[idx];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategoryIndex = idx;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.indigo500.withValues(alpha: 0.18)
                            : isDark
                                ? AppColors.slate900
                                : Colors.white,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.indigo500
                              : isDark
                                  ? AppColors.slate800
                                  : AppColors.slate200,
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            emoji,
                            style: TextStyle(fontSize: 24.sp),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Pillar ${idx + 1}',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.indigo500
                                  : isDark
                                      ? AppColors.slate400
                                      : AppColors.slate600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 14.h),

            // Active Category Keywords Box
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
                      Text(
                        emojis.isNotEmpty && _selectedCategoryIndex < emojis.length
                            ? emojis[_selectedCategoryIndex]
                            : '🔍',
                        style: TextStyle(fontSize: 18.sp),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Target Descriptive Vocabulary',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.slate200 : AppColors.slate800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: activeKeywords.map((kw) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: AppColors.indigo500.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 13.sp,
                              color: AppColors.indigo500,
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              kw,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.indigo500,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Model Description Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 16.sp,
                        color: AppColors.emerald500,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'EXEMPLARY MODEL DESCRIPTION',
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
                    '"$modelAnswer"',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.slate100 : AppColors.slate900,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (explanation.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.slate800 : AppColors.slate100,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 14.sp,
                            color: AppColors.amber500,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              explanation,
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
}
