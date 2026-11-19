import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';

/// Interactive Learn Phase screen for Branching Dialogue ("Conversational Strategy Lab").
///
/// Instructs learners on navigating complex conversational scenarios, assessing
/// persona dynamics, evaluating communicative consequences, and selecting assertive,
/// rapport-building responses.
class BranchingDialogueLearnScreen extends StatefulWidget {
  final int level;

  const BranchingDialogueLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<BranchingDialogueLearnScreen> createState() =>
      _BranchingDialogueLearnScreenState();
}

class _BranchingDialogueLearnScreenState
    extends State<BranchingDialogueLearnScreen> {
  int _cardIndex = 0;
  late List<Map<String, dynamic>> _cards;

  @override
  void initState() {
    super.initState();
    _cards = _fallbackCards;
    _loadCurriculum();
  }

  Future<void> _loadCurriculum() async {
    final batchIndex = ((widget.level - 1) ~/ 10) + 1;
    final startLevel = (batchIndex - 1) * 10 + 1;
    final endLevel = batchIndex * 10;
    final assetPath =
        'assets/curriculum/roleplay/branchingDialogue_learn_${startLevel}_$endLevel.json';

    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final levelCards = rawQuests.where((q) {
        final id = q['id'] as String? ?? '';
        final match = RegExp(r'_l(\d+)_', caseSensitive: false).firstMatch(id);
        if (match != null) {
          return int.parse(match.group(1)!) == widget.level;
        }
        return false;
      }).toList();

      if (mounted && levelCards.isNotEmpty) {
        setState(() {
          _cards = levelCards;
        });
      } else if (mounted && rawQuests.isNotEmpty) {
        final startIdx = ((widget.level - 1) % 10) * 3;
        final sublist = rawQuests.skip(startIdx).take(3).toList();
        if (sublist.isNotEmpty) {
          setState(() {
            _cards = sublist;
          });
        }
      }
    } catch (_) {
      // Retain fallback cards on asset failure
    }
  }

  List<Map<String, dynamic>> get _fallbackCards => [
        {
          'id': 'bd_learn_fallback_1',
          'persona': 'Maria, a new coworker',
          'scene':
              "It is your first day at a new job. Maria, who sits at the next desk, turns to you and says: 'Hi, I don't think we've met yet. What's your name?'",
          'optimalResponse': "Hi, I'm Alex. Nice to meet you, Maria.",
          'positiveOutcome':
              'Realistically, you introduce yourself clearly and the conversation gets off to a friendly start.',
          'communicationObjective':
              'Establish friendly rapport with a desk neighbour without stiffness or oversharing.',
          'strategicTip':
              'When someone asks your name, give it clearly and match the casual tone of the setting.',
          'explanation':
              "Maria asked a simple, direct question, so a short, friendly answer with your name fits best. The very formal version answers correctly but sounds out of place for a first chat with a desk neighbour. The last option responds to 'how are you' instead of 'what's your name,' so it doesn't actually give Maria the information she asked for.",
        },
        {
          'id': 'bd_learn_fallback_2',
          'persona': 'A neighbour in your apartment building',
          'scene':
              "You're getting your mail when a neighbour you've never spoken to says: 'Oh, hey — are you new here? I don't think I've seen you before.'",
          'optimalResponse':
              "Yeah, I just moved in last week. I'm Sam, by the way.",
          'positiveOutcome':
              "You confirm you're new, add your name, and open the door to further natural conversation.",
          'communicationObjective':
              'Acknowledge the neighbour, confirm your residency, and introduce yourself naturally.',
          'strategicTip':
              'A one-word answer to a friendly opener can feel cold — add a small extra detail to keep the exchange natural.',
          'explanation':
              "A short confirmation plus your name gives the neighbour just enough to continue the conversation naturally. Answering with only 'Yes' is technically correct but leaves the exchange feeling flat and closed. The long answer overshares personal details a new neighbour hasn't asked for.",
        },
        {
          'id': 'bd_learn_fallback_3',
          'persona': 'Someone at a work networking event',
          'scene':
              "You're at a work event, checking your phone because you're waiting for an important call, when someone taps your shoulder and says: 'Hi, I don't think we've officially met!'",
          'optimalResponse':
              "Hi, I'm Jordan — sorry, I'm just waiting on a call, but great to meet you.",
          'positiveOutcome':
              'Realistically, you introduce yourself and honestly explain your distraction without seeming rude.',
          'communicationObjective':
              'Politely acknowledge the new contact while setting honest expectations about your availability.',
          'strategicTip':
              "When you're genuinely busy, a brief, honest introduction is better than ignoring the person or fully engaging.",
          'explanation':
              "Giving your name and a quick, honest reason for being distracted respects both your situation and the other person's effort to introduce themselves. Brushing them off skips the introduction entirely, while diving into a long conversation ignores your time pressure.",
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

  void _onNext() {
    if (_cardIndex < _cards.length - 1) {
      setState(() {
        _cardIndex++;
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'branchingDialogue',
        level: widget.level,
        phase: 'learn',
      );
      try {
        context.pushReplacement(
          '/practice?category=roleplay&gameType=branchingDialogue&level=${widget.level}',
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = _cards[_cardIndex.clamp(0, _cards.length - 1)];
    final persona = card['persona'] as String? ?? 'Conversational Partner';
    final scene = card['scene'] as String? ?? '';
    final optimalResponse = card['optimalResponse'] as String? ??
        (card['sampleAnswer'] as String? ?? '');
    final positiveOutcome = card['positiveOutcome'] as String? ??
        (card['explanation'] as String? ?? '');
    final objective = card['communicationObjective'] as String? ??
        'Navigate the conversation effectively.';
    final strategicTip = card['strategicTip'] as String? ??
        (card['hint'] as String? ?? 'Balance tone, intent, and relationship.');
    final explanation = card['explanation'] as String? ?? '';

    return LearnPhaseScaffold(
      title: 'Branching Dialogue',
      gameType: 'branchingDialogue',
      level: widget.level,
      actionLabel: _cardIndex < _cards.length - 1
          ? 'NEXT STRATEGY'
          : 'START PRACTICE',
      onComplete: _onNext,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Persona & Scenario Card
            Container(
              key: const Key('dialogue_learn_persona_card'),
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.indigo500.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
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
                              Icons.record_voice_over_rounded,
                              size: 14.sp,
                              color: AppColors.indigo500,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'SCENARIO',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                color: AppColors.indigo500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        constraints: BoxConstraints(maxWidth: 200.w),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          persona,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.indigo500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    scene,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate100,
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // Objective line
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.track_changes_rounded,
                        size: 16.sp,
                        color: AppColors.amber500,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Objective: $objective',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.amber500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Optimal Response Card
            Container(
              key: const Key('dialogue_learn_optimal_card'),
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald500.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
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
                              Icons.check_circle_outline_rounded,
                              size: 14.sp,
                              color: AppColors.emerald500,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'OPTIMAL RESPONSE',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: AppColors.emerald500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('dialogue_learn_audio_btn'),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.emerald500,
                          size: 20.sp,
                        ),
                        onPressed: () => _playAudio(optimalResponse),
                        tooltip: 'Listen to spoken response',
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
                      color: AppColors.emerald500.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: AppColors.emerald500.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      '"$optimalResponse"',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.emerald500,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.insights_rounded,
                        size: 16.sp,
                        color: AppColors.teal500,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          positiveOutcome,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.slate100,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Strategic Tip & Social Nuance Card
            Container(
              key: const Key('dialogue_learn_strategy_card'),
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.teal500.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.teal500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 14.sp,
                          color: AppColors.teal500,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'STRATEGY RULE',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppColors.teal500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    strategicTip,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.teal500,
                      height: 1.4,
                    ),
                  ),
                  if (explanation.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.slate100.withValues(alpha: 0.8),
                        height: 1.45,
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
