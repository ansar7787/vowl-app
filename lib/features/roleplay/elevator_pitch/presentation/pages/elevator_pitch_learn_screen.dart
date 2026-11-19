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

/// Interactive Learn Phase screen for Elevator Pitch ("30-Second Hook Blueprint").
///
/// Instructs learners on high-impact hooks, concise value propositions,
/// concrete outcome framing, eliminating buzzwords, and delivering under strict time pressure.
class ElevatorPitchLearnScreen extends StatefulWidget {
  final int level;

  const ElevatorPitchLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<ElevatorPitchLearnScreen> createState() =>
      _ElevatorPitchLearnScreenState();
}

class _ElevatorPitchLearnScreenState extends State<ElevatorPitchLearnScreen> {
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
        'assets/curriculum/roleplay/elevatorPitch_learn_${startLevel}_$endLevel.json';

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
      gameType: 'elevatorPitch',
      level: widget.level,
      phase: 'learn',
    );

    try {
      context.pushReplacement(
        '/practice?category=roleplay&gameType=elevatorPitch&level=${widget.level}',
      );
    } catch (_) {}
  }

  static final List<Map<String, dynamic>> _fallbackQuests = [
    {
      'id': 'ep_learn_l1_q1',
      'level': 1,
      'pitchContext': 'VENTURE CAPITAL & SEED FUNDING',
      'concept': 'Pain-Point Lead & Time Saved Hook',
      'prepTerm': 'Hook, Value Metric, Benefit Lead, Call to Action',
      'pitchBlueprintRule':
          'State the concrete problem the listener recognizes in everyday words, not technical jargon.',
      'scenarioScene':
          'A colleague rambles for two minutes about her new mentoring program before anyone understands what it does. State in one sentence what an elevator pitch does.',
      'optimalPitch':
          'It tells a listener, in the time it takes to cross a lobby, what you offer and why it matters to them.',
      'deliveryGuide': 'brisk 130 WPM cadence, direct eye contact, confident smile',
      'keyTakeaway':
          'An elevator pitch is not a condensed lecture; its sole goal is to land relevance before the listener\'s attention wanders.',
      'targetAudience': 'Venture Partner / Managing Director',
      'timeLimit': 30,
    },
    {
      'id': 'ep_learn_l1_q2',
      'level': 1,
      'pitchContext': 'COMMUNITY & LOCAL INITIATIVE',
      'concept': 'Concrete Outcome Over Administrative Mechanics',
      'prepTerm': 'User Benefit, Friction Reduction, Memorable Outcome',
      'pitchBlueprintRule':
          'Tell the listener what they receive and experience, not how the administrative backend operates.',
      'scenarioScene':
          'You introduce your weekend neighborhood tool-lending library to someone waiting for the same bus with fifteen seconds to spare.',
      'optimalPitch':
          'We lend tools instead of everyone buying their own - drill on Tuesday, ladder on Friday, no clutter in anyone\'s garage.',
      'deliveryGuide': 'warm conversational tempo, casual hand gesture, relaxed tone',
      'keyTakeaway':
          'Leading with immediate tangible results connects far faster than describing organizational structure.',
      'targetAudience': 'Local Resident / Commuter',
      'timeLimit': 30,
    },
    {
      'id': 'ep_learn_l1_q3',
      'level': 1,
      'pitchContext': 'AUDIENCE ADAPTATION & VALUE REALIGNMENT',
      'concept': 'Switching the Lead Value Proposition',
      'prepTerm': 'Audience Calibration, Tailored Hook, Contextual Value',
      'pitchBlueprintRule':
          'The strongest pitch doesn\'t reinvent the product; it leads with the specific problem this listener cares most about.',
      'scenarioScene':
          'The same bus-stop stranger mentions they just moved in and don\'t know anyone yet. Pivot the tool-library pitch to address that.',
      'optimalPitch':
          'It\'s how half the building has met each other - borrowing a ladder turns into knowing your neighbors.',
      'deliveryGuide': 'attentive eye contact, empathetic inflection, welcoming nod',
      'keyTakeaway':
          'Customizing the opening hook to match the listener\'s personal context earns immediate rapport.',
      'targetAudience': 'New Resident / Building Neighbor',
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
    final pitchContext =
        current['pitchContext'] as String? ?? 'ELEVATOR PITCH SCENARIO';
    final concept = current['concept'] as String? ?? 'Hook & Value Proposition';
    final prepTerm = current['prepTerm'] as String? ?? '';
    final pitchBlueprintRule =
        current['pitchBlueprintRule'] as String? ?? '';
    final scenarioScene = current['scenarioScene'] as String? ?? '';
    final optimalPitch = current['optimalPitch'] as String? ?? '';
    final deliveryGuide = current['deliveryGuide'] as String? ?? '';
    final keyTakeaway = current['keyTakeaway'] as String? ?? '';
    final targetAudience =
        current['targetAudience'] as String? ?? 'Decision Maker';
    final timeLimit = current['timeLimit'] as int? ?? 30;

    return LearnPhaseScaffold(
      title: 'Elevator Pitch',
      gameType: 'elevatorPitch',
      level: widget.level,
      actionLabel: _currentIndex == _quests.length - 1
          ? 'START PRACTICE'
          : 'NEXT PITCH',
      onComplete: _onNext,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scenario Setting Card
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
                              Icons.timer_outlined,
                              size: 14.sp,
                              color: AppColors.indigo400,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '$timeLimit SECONDS LIMIT',
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
                          targetAudience.toUpperCase(),
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
                    pitchContext,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    scenarioScene,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.blue300,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // Pitch Formula & Blueprint Card
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
                          Icons.rocket_launch_rounded,
                          size: 16.sp,
                          color: AppColors.indigo400,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'PITCH BLUEPRINT & FORMULA',
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
                    pitchBlueprintRule,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.blue300,
                      height: 1.45,
                    ),
                  ),
                  if (prepTerm.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: prepTerm
                          .split(',')
                          .map(
                            (term) => Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.slate800,
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(
                                  color: AppColors.indigo500.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Text(
                                term.trim(),
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppColors.cyan400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // Optimal Pitch Delivery Card
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
                              'OPTIMAL PITCH',
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
                        onPressed: () => _playAudio(optimalPitch),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.emerald400,
                          size: 22.sp,
                        ),
                        tooltip: 'Listen to optimal pitch',
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.all(4.r),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    '"$optimalPitch"',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (deliveryGuide.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.slate800,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.record_voice_over_rounded,
                            size: 15.sp,
                            color: AppColors.amber500,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Delivery: $deliveryGuide',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.blue300,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // Key Takeaway Card
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
                          'PITCH PERSPECTIVE',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.amber500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          keyTakeaway,
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
