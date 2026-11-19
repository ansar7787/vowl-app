import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';

/// Interactive Practice Phase screen for Conflict Resolver ("De-Escalation Gym").
///
/// Drills learners on identifying non-defensive language, active de-escalation,
/// and constructive dispute resolution under high-tension scenarios.
class ConflictResolverPracticeScreen extends StatefulWidget {
  final int level;

  const ConflictResolverPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<ConflictResolverPracticeScreen> createState() =>
      _ConflictResolverPracticeScreenState();
}

class _ConflictResolverPracticeScreenState
    extends State<ConflictResolverPracticeScreen> {
  int _exerciseIndex = 0;
  int? _selectedOptionIndex;
  bool _hasChecked = false;
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
        'assets/curriculum/roleplay/conflictResolver_practice_${startLevel}_$endLevel.json';

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

  void _playAudio(String text) {
    if (text.isEmpty) return;
    try {
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playTts(text);
      }
    } catch (_) {}
  }

  void _onOptionSelected(int index) {
    if (_hasChecked) return;
    setState(() {
      _selectedOptionIndex = index;
    });
    try {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().selection();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playClick();
      }
    } catch (_) {}
  }

  void _onCheck() {
    if (_selectedOptionIndex == null || _hasChecked) return;

    final current = _quests[_exerciseIndex.clamp(0, _quests.length - 1)];
    final correctIdx = current['correctAnswerIndex'] as int? ?? 0;
    final isCorrect = _selectedOptionIndex == correctIdx;

    setState(() {
      _hasChecked = true;
    });

    try {
      if (di.sl.isRegistered<HapticService>()) {
        if (isCorrect) {
          di.sl<HapticService>().success();
        } else {
          di.sl<HapticService>().error();
        }
      }
      if (di.sl.isRegistered<SoundService>()) {
        if (isCorrect) {
          di.sl<SoundService>().playCorrect();
        } else {
          di.sl<SoundService>().playWrong();
        }
      }
    } catch (_) {}
  }

  void _onContinue() {
    try {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().light();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playClick();
      }
    } catch (_) {}

    if (_exerciseIndex < _quests.length - 1) {
      setState(() {
        _exerciseIndex++;
        _selectedOptionIndex = null;
        _hasChecked = false;
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
      phase: 'practice',
    );

    try {
      context.pushReplacement(
        '/game?category=roleplay&gameType=conflictResolver&level=${widget.level}',
      );
    } catch (_) {}
  }

  static final List<Map<String, dynamic>> _fallbackQuests = [
    {
      'id': 'cr_practice_l1_q1',
      'level': 1,
      'conflictContext': 'WORKPLACE CRITICISM & BLUNT FEEDBACK',
      'disputeScene':
          'A senior colleague leaves blunt, dismissive comments on your project review, questioning your technical competence in front of the team.',
      'escalationLevel': 4,
      'question':
          'How should you de-escalate blunt, critical workplace feedback?',
      'options': [
        'I appreciate the review. Let us walk through the formulas together so I can address the specific discrepancies you noted.',
        'If you knew how to read code you wouldn\'t be making such rude remarks.',
        'Ignore the feedback completely and complain to HR about their tone.',
      ],
      'correctAnswerIndex': 0,
      'correctAnswer':
          'I appreciate the review. Let us walk through the formulas together so I can address the specific discrepancies you noted.',
      'explanation':
          'Addressing the specific discrepancies directly while maintaining an even, constructive tone defuses hostility and solves the problem.',
      'empathyScore': 0.85,
    },
    {
      'id': 'cr_practice_l1_q2',
      'level': 1,
      'conflictContext': 'DOMESTIC & SHARED LIVING BOUNDARIES',
      'disputeScene':
          'You open the fridge exhausted after a long day and find your labeled dinner leftovers gone, with your roommate watching TV nearby.',
      'escalationLevel': 3,
      'question':
          'Choose the most constructive response to a roommate boundary violation:',
      'options': [
        'You are the most selfish and inconsiderate person I have ever lived with!',
        'Hey, I had labeled that dinner for tonight. Going forward, please ask first or replace what you eat so we avoid surprises.',
        'Throw their belongings into the hallway and refuse to speak to them.',
      ],
      'correctAnswerIndex': 1,
      'correctAnswer':
          'Hey, I had labeled that dinner for tonight. Going forward, please ask first or replace what you eat so we avoid surprises.',
      'explanation':
          'Calmly stating the rule and setting expectations for future behavior addresses the issue without escalating into personal insults.',
      'empathyScore': 0.85,
    },
    {
      'id': 'cr_practice_l1_q3',
      'level': 1,
      'conflictContext': 'TEAM MILESTONES & MISSED DEADLINES',
      'disputeScene':
          'A teammate misses a critical milestone, then tells the client on a group call that you failed to provide the necessary specs in time.',
      'escalationLevel': 5,
      'question':
          'Select the best way to handle blame-shifting during a live client call:',
      'options': [
        'Stop lying right now! I emailed you the specs three weeks ago and you ignored them!',
        'Let us prioritize delivering the immediate solution for the client today. Afterward, our team will review the timeline workflow to ensure complete alignment.',
        'Mute yourself and disconnect from the call in protest.',
      ],
      'correctAnswerIndex': 1,
      'correctAnswer':
          'Let us prioritize delivering the immediate solution for the client today. Afterward, our team will review the timeline workflow to ensure complete alignment.',
      'explanation':
          'Re-centering the call on the client\'s immediate needs protects professional reputation while reserving accountability discussions for private follow-up.',
      'empathyScore': 0.85,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final current =
        _quests[_exerciseIndex.clamp(0, _quests.length - 1)];
    final conflictContext =
        current['conflictContext'] as String? ?? 'DISPUTE RESOLUTION';
    final disputeScene = current['disputeScene'] as String? ?? '';
    final escalationLevel = current['escalationLevel'] as int? ?? 3;
    final question = current['question'] as String? ??
        'Select the most de-escalating response:';
    final options = (current['options'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final correctIdx = current['correctAnswerIndex'] as int? ?? 0;
    final explanation = current['explanation'] as String? ?? '';
    final isCorrect = _selectedOptionIndex == correctIdx;

    return PracticePhaseScaffold(
      title: 'Conflict Resolver Practice',
      gameType: 'conflictResolver',
      level: widget.level,
      currentExerciseIndex: _exerciseIndex,
      totalExercises: _quests.length,
      onComplete: _markCompleteAndNavigate,
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
                  color: AppColors.indigo500.withValues(alpha: 0.35),
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            constraints: BoxConstraints(maxWidth: 150.w),
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
                          SizedBox(width: 4.w),
                          IconButton(
                            key: const Key('practice_audio_button'),
                            icon: Icon(
                              Icons.volume_up_rounded,
                              size: 18.sp,
                              color: AppColors.indigo400,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _playAudio(disputeScene),
                            tooltip: 'Listen to dispute scenario',
                          ),
                        ],
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

            // Question Prompt
            Text(
              question,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.slate100,
              ),
            ),
            SizedBox(height: 12.h),

            // Options List
            ...List.generate(options.length, (idx) {
              final opt = options[idx];
              final isSelected = _selectedOptionIndex == idx;
              final isThisCorrect = idx == correctIdx;

              Color borderColor = AppColors.slate800;
              Color bgColor = AppColors.slate900;
              Color letterBgColor = AppColors.slate800;
              Color letterTextColor = AppColors.slate300;

              if (_hasChecked) {
                if (isThisCorrect) {
                  borderColor = AppColors.emerald500;
                  bgColor = AppColors.emerald500.withValues(alpha: 0.12);
                  letterBgColor = AppColors.emerald500;
                  letterTextColor = AppColors.white;
                } else if (isSelected && !isThisCorrect) {
                  borderColor = AppColors.rose500;
                  bgColor = AppColors.rose500.withValues(alpha: 0.12);
                  letterBgColor = AppColors.rose500;
                  letterTextColor = AppColors.white;
                }
              } else if (isSelected) {
                borderColor = AppColors.indigo500;
                bgColor = AppColors.indigo500.withValues(alpha: 0.1);
                letterBgColor = AppColors.indigo500;
                letterTextColor = AppColors.white;
              }

              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: Key('practice_option_$idx'),
                    onTap: _hasChecked ? null : () => _onOptionSelected(idx),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: borderColor,
                          width: (isSelected || (_hasChecked && isThisCorrect))
                              ? 2.0
                              : 1.0,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28.w,
                            height: 28.w,
                            decoration: BoxDecoration(
                              color: letterBgColor,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              String.fromCharCode(65 + idx),
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: letterTextColor,
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              opt,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: AppColors.slate100,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            SizedBox(height: 14.h),

            // Check Answer Button
            if (!_hasChecked)
              ElevatedButton(
                key: const Key('practice_check_button'),
                onPressed: _selectedOptionIndex != null ? _onCheck : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo500,
                  disabledBackgroundColor:
                      AppColors.slate800.withValues(alpha: 0.5),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'EVALUATE DE-ESCALATION',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: _selectedOptionIndex != null
                        ? AppColors.white
                        : AppColors.slate500,
                  ),
                ),
              ),

            // Explanation & Next Steps Card
            if (_hasChecked) ...[
              Container(
                key: const Key('practice_explanation_card'),
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppColors.slate900,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isCorrect
                        ? AppColors.emerald500.withValues(alpha: 0.4)
                        : AppColors.rose500.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCorrect
                              ? Icons.check_circle_rounded
                              : Icons.info_outline_rounded,
                          color: isCorrect
                              ? AppColors.emerald500
                              : AppColors.amber500,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            isCorrect
                                ? 'CALIBRATED DE-ESCALATION!'
                                : 'COMMUNICATION ANALYSIS',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: isCorrect
                                  ? AppColors.emerald500
                                  : AppColors.amber500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.slate100,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              ElevatedButton(
                key: const Key('practice_continue_button'),
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isCorrect ? AppColors.emerald500 : AppColors.indigo500,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  _exerciseIndex == _quests.length - 1
                      ? 'ENTER EQUALIZER CONSOLE (MASTERY)'
                      : 'NEXT DISPUTE SCENARIO',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
