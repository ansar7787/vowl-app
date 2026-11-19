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

/// Interactive Learn Phase screen for Situational Response ("Social Norms Playbook").
///
/// Instructs learners on navigating social contexts, matching interpersonal formality,
/// understanding cultural expectations, and expressing respectful, natural responses.
class SituationalResponseLearnScreen extends StatefulWidget {
  final int level;

  const SituationalResponseLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<SituationalResponseLearnScreen> createState() =>
      _SituationalResponseLearnScreenState();
}

class _SituationalResponseLearnScreenState
    extends State<SituationalResponseLearnScreen> {
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
        'assets/curriculum/roleplay/situationalResponse_learn_${startLevel}_$endLevel.json';

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
          'id': 'sr_learn_fallback_1',
          'scene':
              "A man holding the elevator door asks, 'Which floor?' You're heading to the third.",
          'optimalResponse': "Three, please. Thanks for waiting.",
          'formalityScore': 40,
          'socialNormRule':
              "He's being helpful; answer the exact question he asked with a brief courtesy.",
          'culturalNote':
              "In shared spaces like elevators, a short answer and a quick thank-you is the whole expected exchange.",
          'explanation':
              "Giving the floor plus a brief thanks answers him directly and acknowledges the courtesy. Questioning his motive or refusing his help turns a friendly moment into friction.",
        },
        {
          'id': 'sr_learn_fallback_2',
          'scene':
              "A barista calls out, 'Oat latte for Sam?' and holds up a cup. That's your order.",
          'optimalResponse': "That's mine, thanks.",
          'formalityScore': 30,
          'socialNormRule':
              "She has already named you and your drink; quickly confirm without fuss.",
          'culturalNote':
              "Baristas call names because orders pile up; a quick claim of the cup keeps the line moving.",
          'explanation':
              "Confirming it's yours completes the handoff with no fuss. Asking her to re-verify suggests you doubt something that already matches.",
        },
        {
          'id': 'sr_learn_fallback_3',
          'scene':
              "You're at the café waiting for a friend. She texts: 'Running 5 min late!'",
          'optimalResponse': "No problem, I'll grab us a table.",
          'formalityScore': 20,
          'socialNormRule':
              "A five-minute delay is small; acknowledge calmly and take a helpful action.",
          'culturalNote':
              "Between friends, five minutes late is usually unremarkable; reassuring her removes any pressure she feels.",
          'explanation':
              "A relaxed reply that also does something useful keeps the mood light. Blame or ultimatums for a tiny delay damage interpersonal goodwill.",
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
        gameType: 'situationalResponse',
        level: widget.level,
        phase: 'learn',
      );
      try {
        context.pushReplacement(
          '/practice?category=roleplay&gameType=situationalResponse&level=${widget.level}',
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = _cards[_cardIndex.clamp(0, _cards.length - 1)];
    final scene = card['scene'] as String? ?? '';
    final optimalResponse = card['optimalResponse'] as String? ??
        (card['sampleAnswer'] as String? ?? '');
    final formalityScore = card['formalityScore'] as int? ?? 40;
    final culturalNote = card['culturalNote'] as String? ??
        'Match social tone to preserve mutual respect.';
    final socialNormRule = card['socialNormRule'] as String? ??
        (card['hint'] as String? ?? 'Observe interpersonal tone.');
    final explanation = card['explanation'] as String? ?? '';

    return LearnPhaseScaffold(
      title: 'Situational Response',
      gameType: 'situationalResponse',
      level: widget.level,
      actionLabel: _cardIndex < _cards.length - 1
          ? 'NEXT SITUATION'
          : 'START PRACTICE',
      onComplete: _onNext,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scenario Card
            Container(
              key: const Key('situational_learn_scenario_card'),
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
                              Icons.public_rounded,
                              size: 14.sp,
                              color: AppColors.indigo500,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'SOCIAL SCENARIO',
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
                        constraints: BoxConstraints(maxWidth: 180.w),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amber500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'FORMALITY: $formalityScore%',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.amber500,
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
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Optimal Response Card
            Container(
              key: const Key('situational_learn_optimal_card'),
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
                              'CALIBRATED RESPONSE',
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
                        key: const Key('situational_learn_audio_btn'),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.emerald500,
                          size: 20.sp,
                        ),
                        onPressed: () => _playAudio(optimalResponse),
                        tooltip: 'Listen to natural response',
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
                          explanation,
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

            // Social Norm & Cultural Note Card
            Container(
              key: const Key('situational_learn_norm_card'),
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
                          Icons.menu_book_rounded,
                          size: 14.sp,
                          color: AppColors.teal500,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'SOCIAL PLAYBOOK RULE',
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
                    socialNormRule,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.teal500,
                      height: 1.4,
                    ),
                  ),
                  if (culturalNote.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.language_rounded,
                          size: 15.sp,
                          color: AppColors.amber500,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            culturalNote,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.slate100.withValues(alpha: 0.85),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
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
