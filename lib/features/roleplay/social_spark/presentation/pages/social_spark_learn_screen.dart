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

/// Interactive Learn Phase screen for Social Spark ("Conversational Dynamics & Small Talk").
///
/// Instructs learners on warm greetings, polite space sharing, reciprocal conversation balance,
/// observational hooks, and smooth small-talk rapport building.
class SocialSparkLearnScreen extends StatefulWidget {
  final int level;

  const SocialSparkLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<SocialSparkLearnScreen> createState() => _SocialSparkLearnScreenState();
}

class _SocialSparkLearnScreenState extends State<SocialSparkLearnScreen> {
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
        'assets/curriculum/roleplay/socialSpark_learn_${startLevel}_$endLevel.json';

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
      gameType: 'socialSpark',
      level: widget.level,
      phase: 'learn',
    );

    try {
      context.pushReplacement(
        '/practice?category=roleplay&gameType=socialSpark&level=${widget.level}',
      );
    } catch (_) {}
  }

  static final List<Map<String, dynamic>> _fallbackQuests = [
    {
      'id': 'ss_learn_l1_q1',
      'level': 1,
      'socialContext': 'Apartment Hallway',
      'concept': 'Time-of-Day Check-in & Warm Opening',
      'dialoguePrinciple':
          'Pairing a time-of-day greeting with a quick check-in creates immediate warmth and offers the other person an effortless reply.',
      'situationPrompt':
          'Your neighbor is heading out to work as you step into the hallway at 8 a.m. Greet them with friendly politeness.',
      'optimalResponse': 'Good morning, how are you?',
      'culturalInsight':
          'A bare "hi" can feel abrupt in residential hallways; adding "how are you?" acknowledges the shared community with gentle respect.',
      'interactionType': 'dialogue',
      'timeLimit': 30,
    },
    {
      'id': 'ss_learn_l1_q2',
      'level': 1,
      'socialContext': 'Video Call',
      'concept': 'Group Meeting Greeting Protocol',
      'dialoguePrinciple':
          'Greeting the collective group with "everyone" immediately establishes connection without singling anyone out.',
      'situationPrompt':
          'You have just joined an online team meeting at 7 p.m. and want to greet the whole group smoothly.',
      'optimalResponse': 'Good evening, everyone.',
      'culturalInsight':
          '"Everyone" greets the room in one phrase, and "good evening" provides a professional, polished tone that fits remote meetings.',
      'interactionType': 'dialogue',
      'timeLimit': 30,
    },
    {
      'id': 'ss_learn_l1_q3',
      'level': 1,
      'socialContext': 'Bus Stop',
      'concept': 'Return-Question Balance',
      'dialoguePrinciple':
          'Replying honestly and immediately returning the question prevents conversations from feeling one-sided.',
      'situationPrompt':
          'A classmate asks how things are going and you are doing fine. Build a balanced, engaging reply.',
      'optimalResponse': 'Not bad, thanks. How about you?',
      'culturalInsight':
          '"Not bad" is a common native idiom indicating contentment without bragging; returning the question shows mutual social interest.',
      'interactionType': 'dialogue',
      'timeLimit': 30,
    },
  ];

  void _playAudio(String text) {
    if (text.isEmpty) return;
    try {
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playTts(text);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final current = _quests[_currentIndex.clamp(0, _quests.length - 1)];
    final socialContext =
        current['socialContext'] as String? ?? 'Social Interaction';
    final concept = current['concept'] as String? ?? 'Conversational Rapport';
    final dialoguePrinciple =
        current['dialoguePrinciple'] as String? ?? '';
    final situationPrompt = current['situationPrompt'] as String? ?? '';
    final optimalResponse = current['optimalResponse'] as String? ?? '';
    final culturalInsight = current['culturalInsight'] as String? ?? '';

    return LearnPhaseScaffold(
      title: 'Social Spark',
      gameType: 'socialSpark',
      level: widget.level,
      actionLabel: _currentIndex == _quests.length - 1
          ? 'START PRACTICE'
          : 'NEXT SITUATION',
      onComplete: _onNext,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Situation Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.forum_outlined,
                              size: 14.sp,
                              color: AppColors.indigo400,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'SOCIAL SCENE',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.indigo400,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        constraints: BoxConstraints(maxWidth: 160.w),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cyan400.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          socialContext.toUpperCase(),
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
                    situationPrompt,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // Conversational Strategy & Blueprint Card
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
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 16.sp,
                          color: AppColors.indigo400,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'CONVERSATIONAL BLUEPRINT',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.indigo400,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    concept,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    dialoguePrinciple,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.blue300,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // Optimal Social Spark Response Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.indigo500.withValues(alpha: 0.15),
                    AppColors.slate900,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.emerald400.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.emerald400.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 14.sp,
                              color: AppColors.emerald400,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'OPTIMAL RESPONSE',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.emerald400,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('learn_audio_button'),
                        onPressed: () => _playAudio(optimalResponse),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.emerald400,
                          size: 22.sp,
                        ),
                        tooltip: 'Listen to natural response',
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.all(4.r),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    '"$optimalResponse"',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.45,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // Cultural Dynamics Insight Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.amber500.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.amber500,
                    size: 20.sp,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CULTURAL DYNAMICS',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.amber500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          culturalInsight,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.blue300,
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
          ],
        ),
      ),
    );
  }
}
