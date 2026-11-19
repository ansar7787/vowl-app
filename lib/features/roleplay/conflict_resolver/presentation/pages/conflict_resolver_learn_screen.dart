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

/// Interactive Learn Phase screen for Conflict Resolver ("De-Escalation Toolkit").
///
/// Instructs learners on emotional regulation, high-empathy communication,
/// non-defensive responses, boundary setting, and de-escalating interpersonal disputes.
class ConflictResolverLearnScreen extends StatefulWidget {
  final int level;

  const ConflictResolverLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<ConflictResolverLearnScreen> createState() =>
      _ConflictResolverLearnScreenState();
}

class _ConflictResolverLearnScreenState
    extends State<ConflictResolverLearnScreen> {
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
        'assets/curriculum/roleplay/conflictResolver_learn_${startLevel}_$endLevel.json';

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
      gameType: 'conflictResolver',
      level: widget.level,
      phase: 'learn',
    );

    try {
      context.pushReplacement(
        '/practice?category=roleplay&gameType=conflictResolver&level=${widget.level}',
      );
    } catch (_) {}
  }

  static final List<Map<String, dynamic>> _fallbackQuests = [
    {
      'id': 'cr_learn_l1_q1',
      'level': 1,
      'conflictContext': 'WORKPLACE CRITICISM & BLUNT FEEDBACK',
      'concept': 'Separating Substance from Tone',
      'prepTerm': 'Objective verification, Non-defensive inquiry, Fact-based review',
      'deescalationRule':
          'Acknowledge valid technical points without adopting the other party\'s hostile or dismissive tone.',
      'disputeScene':
          'A senior colleague leaves blunt, dismissive comments on your project review, questioning your technical competence in front of the team.',
      'optimalDeescalatingResponse':
          'I appreciate the review. Let us walk through the formulas together so I can address the specific discrepancies you noted.',
      'deliveryGuide': 'calm, measured tempo, even pitch, neutral cadence',
      'keyTakeaway':
          'Focusing strictly on content and data resolves technical disputes while disarming personal friction.',
      'escalationLevel': 4,
    },
    {
      'id': 'cr_learn_l1_q2',
      'level': 1,
      'conflictContext': 'DOMESTIC & SHARED LIVING BOUNDARIES',
      'concept': 'Naming Behaviors vs. Character Attacks',
      'prepTerm': 'Direct inquiry, Concrete impact statement, Ground-rule realignment',
      'deescalationRule':
          'State what happened and what you need moving forward, rather than attacking the person\'s character.',
      'disputeScene':
          'You open the fridge exhausted after a long day and find your labeled dinner leftovers gone, with your roommate watching TV nearby.',
      'optimalDeescalatingResponse':
          'Hey, I had labeled that dinner for tonight. Going forward, please ask first or replace what you eat so we avoid surprises.',
      'deliveryGuide': 'firm but calm, casual eye contact, no raised volume',
      'keyTakeaway':
          'Clear boundaries paired with straightforward expectations prevent repeated domestic friction without starting a shouting match.',
      'escalationLevel': 3,
    },
    {
      'id': 'cr_learn_l1_q3',
      'level': 1,
      'conflictContext': 'TEAM MILESTONES & MISSED DEADLINES',
      'concept': 'Client-First Focus & Private Alignment',
      'prepTerm': 'Public de-escalation, Private timeline reconciliation, Audit trail',
      'deescalationRule':
          'Never engage in blame-shifting during client-facing meetings; solve the immediate emergency first and align privately later.',
      'disputeScene':
          'A teammate misses a critical milestone, then tells the client on a group call that you failed to provide the necessary specs in time.',
      'optimalDeescalatingResponse':
          'Let us prioritize delivering the immediate solution for the client today. Afterward, our team will review the timeline workflow to ensure complete alignment.',
      'deliveryGuide': 'steady professional warmth, solution-focused inflection',
      'keyTakeaway':
          'Protecting the client relationship during meetings preserves credibility; process audits belong in private follow-ups.',
      'escalationLevel': 5,
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
    final conflictContext =
        current['conflictContext'] as String? ?? 'DISPUTE RESOLUTION';
    final concept = current['concept'] as String? ?? '';
    final prepTerm = current['prepTerm'] as String? ?? '';
    final deescalationRule = current['deescalationRule'] as String? ?? '';
    final disputeScene = current['disputeScene'] as String? ?? '';
    final optimalDeescalatingResponse =
        current['optimalDeescalatingResponse'] as String? ?? '';
    final deliveryGuide = current['deliveryGuide'] as String? ?? '';
    final keyTakeaway = current['keyTakeaway'] as String? ?? '';
    final escalationLevel = current['escalationLevel'] as int? ?? 3;

    return LearnPhaseScaffold(
      title: 'Conflict Resolver',
      gameType: 'conflictResolver',
      level: widget.level,
      actionLabel: _currentIndex == _quests.length - 1
          ? 'START PRACTICE'
          : 'NEXT SCENARIO',
      onComplete: _onNext,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dispute Scenario Card
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
                              Icons.bolt_rounded,
                              size: 14.sp,
                              color: AppColors.indigo400,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'TENSION LEVEL: $escalationLevel/5',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: AppColors.indigo400,
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
                          color: AppColors.slate800,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          conflictContext,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.indigo400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '"$disputeScene"',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate100,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // De-Escalation Protocol Knowledge Section
            Text(
              'DE-ESCALATION PROTOCOL',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: AppColors.slate100.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 8.h),

            // Principle & Rule Card
            _buildProtocolPillar(
              icon: Icons.handshake_rounded,
              title: concept.isNotEmpty ? concept : 'De-Escalation Principle',
              description: deescalationRule,
              accentColor: AppColors.indigo400,
            ),
            SizedBox(height: 10.h),

            // Emotional Regulation Strategy Card
            _buildProtocolPillar(
              icon: Icons.psychology_rounded,
              title: 'REGULATION STRATEGY',
              description: prepTerm,
              accentColor: AppColors.emerald400,
            ),
            SizedBox(height: 16.h),

            // Calibrated De-Escalating Response Card
            Container(
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
                    runSpacing: 6.h,
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
                              color: AppColors.emerald400,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'OPTIMAL RESPONSE',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: AppColors.emerald400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('learn_audio_button'),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.emerald400,
                          size: 20.sp,
                        ),
                        onPressed: () =>
                            _playAudio(optimalDeescalatingResponse),
                        tooltip: 'Listen to optimal response',
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    optimalDeescalatingResponse,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.slate100,
                      height: 1.45,
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
                            Icons.graphic_eq_rounded,
                            size: 14.sp,
                            color: AppColors.slate100.withValues(alpha: 0.7),
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              'DELIVERY TONE: $deliveryGuide',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontFamily: 'monospace',
                                color: AppColors.slate100.withValues(alpha: 0.9),
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
            SizedBox(height: 12.h),

            // Key Takeaway Card
            if (keyTakeaway.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.slate800.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.slate700,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 16.sp,
                      color: AppColors.amber500,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        keyTakeaway,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.slate100.withValues(alpha: 0.85),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocolPillar({
    required IconData icon,
    required String title,
    required String description,
    required Color accentColor,
  }) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.sp, color: accentColor),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              description,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.slate100.withValues(alpha: 0.9),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
