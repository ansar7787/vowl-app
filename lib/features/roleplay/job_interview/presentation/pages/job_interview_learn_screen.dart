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

/// Interactive Learn Phase screen for Job Interview ("STAR Method Framework").
///
/// Teaches learners the behavioral interview architecture (Situation, Task,
/// Action, Result), showcasing how to structure professional responses with
/// high executive tone, accountability, and measurable impact.
class JobInterviewLearnScreen extends StatefulWidget {
  final int level;

  const JobInterviewLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<JobInterviewLearnScreen> createState() =>
      _JobInterviewLearnScreenState();
}

class _JobInterviewLearnScreenState extends State<JobInterviewLearnScreen> {
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
        'assets/curriculum/roleplay/jobInterview_learn_${startLevel}_$endLevel.json';

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

      if (mounted && levelQuests.isNotEmpty) {
        setState(() {
          _quests = levelQuests;
        });
      } else if (mounted && rawQuests.isNotEmpty) {
        final startIdx = ((widget.level - 1) % 10) * 4;
        final sublist = rawQuests.skip(startIdx).take(4).toList();
        if (sublist.isNotEmpty) {
          setState(() {
            _quests = sublist;
          });
        }
      }
    } catch (_) {
      // Retain fallback quests on asset failure
    }
  }

  List<Map<String, dynamic>> get _fallbackQuests => [
        {
          'id': 'ji_learn_fallback_1',
          'interviewerQuestion':
              'Tell me about a time you handled a tight deadline with conflicting priorities.',
          'situation':
              'Our team was simultaneously launching a new client portal while preparing for a quarterly regulatory audit.',
          'task':
              'I needed to ensure all critical audit security requirements were met without delaying portal deployment.',
          'action':
              'I triaged requirements into non-negotiable audit compliance vs post-launch enhancements, automated verification tests, and aligned daily with stakeholders.',
          'result':
              'We passed the audit with 0 non-conformities and delivered the portal on the scheduled release date with zero production downtime.',
          'optimalResponse':
              "When facing competing client and regulatory deadlines, I triaged deliverables by compliance criticality, automated testing, and delivered both on time with zero defects.",
          'starPillar': 'ACTION & IMPACT',
          'keyTakeaway':
              "Quantify results and clearly distinguish between your individual actions and team contributions.",
        },
        {
          'id': 'ji_learn_fallback_2',
          'interviewerQuestion':
              'Describe a scenario where you had to influence a stakeholder who disagreed with your proposal.',
          'situation':
              'The head of product wanted to skip data caching to launch faster, despite anticipated peak loads.',
          'task':
              'I was responsible for demonstrating the system risk and getting agreement on an incremental caching strategy.',
          'action':
              'I simulated peak load stress tests, visualized drop-off conversion loss costs, and proposed a pre-built cache middleware adding only 2 days to the schedule.',
          'result':
              'The stakeholder approved the hybrid proposal, and during the peak surge, our uptime remained 99.98% under 4x traffic.',
          'optimalResponse':
              "I presented objective risk data through simulated peak testing, linked technical stability to business revenue, and negotiated a low-friction compromise.",
          'starPillar': 'INFLUENCE & METRICS',
          'keyTakeaway':
              "Replace emotional arguments with empirical data, financial impact analysis, and practical middle-ground solutions.",
        },
      ];

  void _playAudio(String text) {
    if (text.isEmpty) return;
    try {
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playTts(text);
      }
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().selection();
      }
    } catch (_) {}
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
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'jobInterview',
        level: widget.level,
        phase: 'learn',
      );
      try {
        context.pushReplacement(
          '/game?category=roleplay&gameType=jobInterview&level=${widget.level}&phase=practice',
        );
      } catch (_) {}
    }
  }

  Widget _buildStarPillarCard({
    required String letter,
    required String title,
    required String content,
    required Color accentColor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.r,
            height: 28.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.2),
              border: Border.all(color: accentColor, width: 1.5),
            ),
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: accentColor,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.slate100,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _quests[_currentIndex.clamp(0, _quests.length - 1)];
    final question = current['interviewerQuestion'] as String? ?? '';
    final situation = current['situation'] as String? ?? '';
    final task = current['task'] as String? ?? '';
    final action = current['action'] as String? ?? '';
    final result = current['result'] as String? ?? '';
    final optimalResponse = current['optimalResponse'] as String? ?? '';
    final starPillar = current['starPillar'] as String? ?? 'STAR METHOD';
    final keyTakeaway = current['keyTakeaway'] as String? ?? '';

    return LearnPhaseScaffold(
      title: 'Job Interview',
      gameType: 'jobInterview',
      level: widget.level,
      actionLabel:
          _currentIndex == _quests.length - 1 ? 'START PRACTICE' : 'NEXT QUESTION',
      onComplete: _onNext,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Question Card
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
                    runSpacing: 8.h,
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
                              Icons.business_center_rounded,
                              size: 14.sp,
                              color: AppColors.indigo500,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'INTERVIEWER QUESTION',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: AppColors.indigo500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amber500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          starPillar,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.amber500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '"$question"',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate100,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // STAR Method Breakdown Section
            Text(
              'STAR STRUCTURE BREAKDOWN',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: AppColors.slate100.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 10.h),

            _buildStarPillarCard(
              letter: 'S',
              title: 'SITUATION (Context)',
              content: situation,
              accentColor: AppColors.blue500,
            ),
            _buildStarPillarCard(
              letter: 'T',
              title: 'TASK (Responsibility)',
              content: task,
              accentColor: AppColors.amber500,
            ),
            _buildStarPillarCard(
              letter: 'A',
              title: 'ACTION (Your Contribution)',
              content: action,
              accentColor: AppColors.indigo500,
            ),
            _buildStarPillarCard(
              letter: 'R',
              title: 'RESULT (Impact & Metrics)',
              content: result,
              accentColor: AppColors.emerald500,
            ),
            SizedBox(height: 8.h),

            // Model Response Card
            Container(
              key: const Key('interview_learn_optimal_card'),
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: 0.4),
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
                    runSpacing: 8.h,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.emerald500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 14.sp,
                              color: AppColors.emerald500,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'MODEL STAR DELIVERY',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: AppColors.emerald500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('interview_learn_audio_btn'),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.emerald500,
                          size: 20.sp,
                        ),
                        onPressed: () => _playAudio(optimalResponse),
                        tooltip: 'Listen to delivery',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: AppColors.slate950,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      optimalResponse,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontStyle: FontStyle.italic,
                        color: AppColors.slate100,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Key Strategy Rule Card
            if (keyTakeaway.isNotEmpty) ...[
              Container(
                key: const Key('interview_learn_strategy_card'),
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppColors.slate900,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.amber500.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_rounded,
                      color: AppColors.amber500,
                      size: 20.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EXECUTIVE TAKEAWAY',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: AppColors.amber500,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            keyTakeaway,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.slate100,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
            ],
          ],
        ),
      ),
    );
  }
}

