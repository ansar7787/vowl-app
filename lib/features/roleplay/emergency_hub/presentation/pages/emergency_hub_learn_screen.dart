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

/// Interactive Learn Phase screen for Emergency Hub ("Emergency Triage & Crisis Response").
///
/// Instructs learners on rapid threat assessment, life-safety triage, dispatch classification,
/// and immediate protective interventions before first responders arrive.
class EmergencyHubLearnScreen extends StatefulWidget {
  final int level;

  const EmergencyHubLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<EmergencyHubLearnScreen> createState() =>
      _EmergencyHubLearnScreenState();
}

class _EmergencyHubLearnScreenState extends State<EmergencyHubLearnScreen> {
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
        'assets/curriculum/roleplay/emergencyHub_learn_${startLevel}_$endLevel.json';

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
      gameType: 'emergencyHub',
      level: widget.level,
      phase: 'learn',
    );

    try {
      context.pushReplacement(
        '/practice?category=roleplay&gameType=emergencyHub&level=${widget.level}',
      );
    } catch (_) {}
  }

  static final List<Map<String, dynamic>> _fallbackQuests = [
    {
      'id': 'eh_learn_l1_q1',
      'level': 1,
      'emergencyCategory': 'DOMESTIC NUISANCE & TRIAGE',
      'concept': 'Distinguishing Danger from Inconvenience',
      'protocolRule':
          'Ask whether anyone is in immediate physical danger right now before calling emergency dispatch.',
      'crisisScene':
          'A neighbor\'s dog has been barking loudly for the past twenty minutes. Input code!',
      'optimalResponse': 'THIS IS NOT AN EMERGENCY',
      'actionGuidance':
          'Noise alone is not an immediate danger to life or property, so it does not warrant police, fire, or ambulance dispatch.',
      'urgencyLevel': 1,
      'timeLimit': 30,
    },
    {
      'id': 'eh_learn_l1_q2',
      'level': 1,
      'emergencyCategory': 'MEDICAL EMERGENCY & FIRST RESPONDER',
      'concept': 'Unresponsive Victim Protocol',
      'protocolRule':
          'An unresponsive person requires immediate advanced medical care to assess breathing and circulation.',
      'crisisScene':
          'A man is lying motionless on the sidewalk and does not respond when people call out to him. Input medical code!',
      'optimalResponse': 'CALL FOR AN AMBULANCE',
      'actionGuidance':
          'An unresponsive individual needs paramedics immediately to verify airways and initiate life-saving resuscitation.',
      'urgencyLevel': 4,
      'timeLimit': 30,
    },
    {
      'id': 'eh_learn_l1_q3',
      'level': 1,
      'emergencyCategory': 'FIRE & STRUCTURAL HAZARD',
      'concept': 'Small Fire Escalation Prevention',
      'protocolRule':
          'Flames in combustible containers can ignite nearby storefronts or structures within seconds.',
      'crisisScene':
          'Flames are rising from a trash can outside a shop, and the plastic bin is starting to melt. Input fire code!',
      'optimalResponse': 'CALL THE FIRE BRIGADE',
      'actionGuidance':
          'Even small outdoor fires can jump to building awnings rapidly; professional firefighters must extinguish and overhaul the scene.',
      'urgencyLevel': 3,
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
    final emergencyCategory =
        current['emergencyCategory'] as String? ?? 'CRISIS SCENARIO';
    final concept = current['concept'] as String? ?? 'Emergency Protocol';
    final protocolRule = current['protocolRule'] as String? ?? '';
    final crisisScene = current['crisisScene'] as String? ?? '';
    final optimalResponse = current['optimalResponse'] as String? ?? '';
    final actionGuidance = current['actionGuidance'] as String? ?? '';
    final urgencyLevel = current['urgencyLevel'] as int? ?? 3;

    return LearnPhaseScaffold(
      title: 'Emergency Hub',
      gameType: 'emergencyHub',
      level: widget.level,
      actionLabel: _currentIndex == _quests.length - 1
          ? 'START PRACTICE'
          : 'NEXT EMERGENCY',
      onComplete: _onNext,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Crisis Scene Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.rose500.withValues(alpha: 0.4),
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
                          color: AppColors.rose500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 14.sp,
                              color: AppColors.rose500,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'URGENCY: $urgencyLevel/5',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.rose500,
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
                          emergencyCategory.toUpperCase(),
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
                    crisisScene,
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

            // Crisis Dispatch Protocol Card
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
                          Icons.emergency_rounded,
                          size: 16.sp,
                          color: AppColors.indigo400,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'CRISIS DISPATCH PROTOCOL',
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
                    protocolRule,
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

            // Optimal Dispatch Action Card
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
                              'OPTIMAL ACTION',
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
                        tooltip: 'Listen to optimal response',
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

            // Life-Saving Action Guidance Card
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
                    Icons.security_rounded,
                    color: AppColors.amber500,
                    size: 20.sp,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LIFE-SAVING ACTION',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.amber500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          actionGuidance,
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
