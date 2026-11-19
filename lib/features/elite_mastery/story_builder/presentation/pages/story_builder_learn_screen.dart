import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';

/// Interactive Learn Phase screen for Story Builder ("Narrative Arc Anatomy & Discourse Cohesion").
///
/// Instructs learners on Freytag's Pyramid, chronological sequencing, cause-and-effect transitions,
/// and logical prerequisite dependencies in master-level narrative architecture.
class StoryBuilderLearnScreen extends StatefulWidget {
  final int level;

  const StoryBuilderLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<StoryBuilderLearnScreen> createState() => _StoryBuilderLearnScreenState();
}

class _StoryBuilderLearnScreenState extends State<StoryBuilderLearnScreen> {
  int _currentIndex = 0;
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
        'assets/curriculum/elite_mastery/storyBuilder_learn_${startLevel}_$endLevel.json';

    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final levelQuests = rawQuests.where((q) {
        final id = q['id'] as String? ?? '';
        final match = RegExp(r'_l(\d+)_', caseSensitive: false).firstMatch(id);
        if (match != null) {
          return int.parse(match.group(1)!) == widget.level;
        }
        return false;
      }).toList();

      if (levelQuests.isNotEmpty && mounted) {
        setState(() {
          _quests = levelQuests;
        });
      }
    } catch (_) {
      // Fallback quests maintain continuity during testing or missing assets.
    }
  }

  void _onNext() {
    try {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().light();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playClick();
      }
    } catch (_) {}

    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _markCompleteAndNavigate();
    }
  }

  void _markCompleteAndNavigate() {
    try {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().success();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playCorrect();
      }
    } catch (_) {}

    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'storyBuilder',
      level: widget.level,
      phase: 'learn',
    );

    try {
      context.pushReplacement(
        '/practice?category=elite_mastery&gameType=storyBuilder&level=${widget.level}',
      );
    } catch (_) {}
  }

  void _playAudio(String text) {
    if (text.isEmpty) return;
    try {
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playTts(text);
      }
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().light();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final current = _quests.isNotEmpty ? _quests[_currentIndex] : _fallbackQuests.first;
    final storyTitle = current['storyTitle'] as String? ?? 'Narrative Arc Analysis';
    final narrativeStage = current['narrativeStage'] as String? ?? 'Exposition, Climax, Resolution';
    final sequenceLogic = current['sequenceLogic'] as String? ?? 'Chronological Progression';
    final storyParagraph = current['storyParagraph'] as String? ??
        (current['optimalNarrativeSequence'] as String? ?? '');
    final rawEvents = current['chronologicalEvents'] as List<dynamic>? ?? [];
    final chronologicalEvents = rawEvents.cast<String>();
    final authorInsight = current['authorInsight'] as String? ??
        (current['explanation'] as String? ?? 'Events follow an organic cause-and-effect progression.');

    return LearnPhaseScaffold(
      title: 'Story Builder',
      gameType: 'storyBuilder',
      level: widget.level,
      actionLabel: _currentIndex == _quests.length - 1
          ? 'START PLOT GYM'
          : 'NEXT NARRATIVE ARC',
      onComplete: _onNext,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Badge Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.amber400.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amber400.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_stories,
                              size: 13.sp,
                              color: AppColors.amber400,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'NARRATIVE ARCHITECTURE',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.amber400,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        constraints: BoxConstraints(maxWidth: 180.w),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cyan400.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          sequenceLogic.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cyan400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    storyTitle,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Arc Pattern: $narrativeStage',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.slate300,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // Cohesive Story Passage Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.indigo400.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              size: 15.sp,
                              color: AppColors.indigo400,
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                'COHESIVE DISCOURSE PASSAGE',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.indigo400,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('learn_audio_button'),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          size: 20.sp,
                          color: AppColors.indigo400,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _playAudio(storyParagraph),
                        tooltip: 'Listen to story',
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: AppColors.slate800,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.slate700,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      storyParagraph,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // Chronological Progression Steps
            if (chronologicalEvents.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppColors.slate900,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.teal400.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.format_list_numbered_rounded,
                          size: 15.sp,
                          color: AppColors.teal400,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            'CHRONOLOGICAL EVENT BREAKDOWN',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.teal400,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    for (int i = 0; i < chronologicalEvents.length; i++)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22.w,
                              height: 22.h,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.teal400.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.teal400,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                chronologicalEvents[i],
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.white,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ],

            // Author's Cohesion Insight Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.cyan400.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 18.sp,
                    color: AppColors.cyan400,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AUTHOR\'S COHESION PRINCIPLE',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cyan400,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          authorInsight,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.slate300,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Advance Action Button
            ElevatedButton(
              key: const Key('learn_continue_button'),
              onPressed: _onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo500,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: Text(
                _currentIndex < _quests.length - 1 ? 'NEXT NARRATIVE ARC' : 'START PLOT GYM',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  static const List<Map<String, dynamic>> _fallbackQuests = [
    {
      "id": "ELT_STORYBUILDER_L1_LEARN_Q1",
      "level": 1,
      "phase": "learn",
      "storyTitle": "Narrative Arc: Start, Process, Result, Enjoyment",
      "narrativeStage": "Start, Process, Result, Enjoyment",
      "cohesionPrinciple": "Chronological Progression",
      "storyParagraph":
          "Priya filled the kettle at the sink. The water inside began to boil. Priya poured it over a tea bag in her favorite mug. The tea was warm enough to sip at the window.",
      "chronologicalEvents": [
        "Priya filled the kettle at the sink.",
        "The water inside began to boil.",
        "Priya poured it over a tea bag in her favorite mug.",
        "The tea was warm enough to sip at the window."
      ],
      "optimalNarrativeSequence":
          "Priya filled the kettle at the sink. The water inside began to boil. Priya poured it over a tea bag in her favorite mug. The tea was warm enough to sip at the window.",
      "sequenceLogic": "Chronological Progression",
      "plotStructure": "Start, Process, Result, Enjoyment",
      "explanation":
          "Water cannot boil until the kettle has been filled and heated, and it cannot be poured until it is hot. Each step gives the next one something to work with.",
      "hint": "Ask which action has to happen before the water can boil.",
      "authorInsight":
          "Masterful discourse relies on Chronological Progression — each sentence establishes the indispensable foundation for the next."
    }
  ];
}
