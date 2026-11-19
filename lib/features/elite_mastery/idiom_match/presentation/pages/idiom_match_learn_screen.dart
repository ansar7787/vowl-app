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

/// Interactive Learn Phase screen for Idiom Match ("Metaphor & Etymology Vault").
///
/// Instructs learners on historical origins, figurative mental anchors,
/// and communicative registers for master-level idiomatic competence.
class IdiomMatchLearnScreen extends StatefulWidget {
  final int level;

  const IdiomMatchLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<IdiomMatchLearnScreen> createState() => _IdiomMatchLearnScreenState();
}

class _IdiomMatchLearnScreenState extends State<IdiomMatchLearnScreen> {
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
        'assets/curriculum/elite_mastery/idiomMatch_learn_${startLevel}_$endLevel.json';

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
      // Fallback maintains continuity during testing.
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
      gameType: 'idiomMatch',
      level: widget.level,
      phase: 'learn',
    );

    try {
      context.pushReplacement(
        '/practice?category=elite_mastery&gameType=idiomMatch&level=${widget.level}',
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
    final targetIdiom = current['targetIdiom'] as String? ?? 'under the weather';
    final meaning = current['meaning'] as String? ?? (current['explanation'] as String? ?? '');
    final idiomOrigin = current['idiomOrigin'] as String? ?? 'Historical colloquial metaphor.';
    final visualMetaphor = current['visualMetaphor'] as String? ?? 'Visual anchor.';
    final usageContext = current['usageContext'] as String? ?? 'Common workplace usage.';
    final exampleContext = current['exampleContext'] as String? ?? (current['question'] as String? ?? '');
    final authorInsight = current['authorInsight'] as String? ??
        'Idiomatic mastery means grasping the underlying metaphor — once visualized, the figurative meaning becomes second nature.';

    return LearnPhaseScaffold(
      title: 'Idiom Match',
      gameType: 'idiomMatch',
      level: widget.level,
      actionLabel: _currentIndex == _quests.length - 1 ? 'START IDIOM GYM' : 'NEXT IDIOM',
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
                              Icons.format_quote_rounded,
                              size: 13.sp,
                              color: AppColors.amber400,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'ETYMOLOGY & METAPHOR VAULT',
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
                        constraints: BoxConstraints(maxWidth: 170.w),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cyan400.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          usageContext.toUpperCase(),
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
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '"$targetIdiom"',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('learn_audio_button'),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          size: 20.sp,
                          color: AppColors.amber400,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _playAudio(targetIdiom),
                        tooltip: 'Listen to idiom',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // Meaning & Definition Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(14.r),
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
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 15.sp,
                        color: AppColors.indigo400,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'MEANING & CONVERSATIONAL NUANCE',
                          style: TextStyle(
                            fontSize: 10.sp,
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
                  SizedBox(height: 8.h),
                  Text(
                    meaning,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // Etymology Origin Card
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.history_edu_rounded,
                        size: 15.sp,
                        color: AppColors.cyan400,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'HISTORICAL ETYMOLOGY',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cyan400,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    idiomOrigin,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // Visual Metaphor Anchor Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.remove_red_eye_outlined,
                        size: 15.sp,
                        color: AppColors.emerald500,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'VISUAL METAPHOR ANCHOR',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.emerald500,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    visualMetaphor,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white,
                      height: 1.45,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // Authentic Context in Action Card
            if (exampleContext.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppColors.slate900,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.slate700,
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
                                Icons.chat_bubble_outline_rounded,
                                size: 14.sp,
                                color: AppColors.slate400,
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  'AUTHENTIC SCENARIO IN ACTION',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.slate400,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.volume_up_rounded,
                            size: 18.sp,
                            color: AppColors.slate400,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _playAudio(exampleContext),
                          tooltip: 'Listen to context',
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      exampleContext,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ],

            // Author Insight Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.amber400.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.psychology_rounded,
                    size: 18.sp,
                    color: AppColors.amber400,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MENTAL MODEL INSIGHT',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.amber400,
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

            // Advance Button
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
                _currentIndex < _quests.length - 1 ? 'NEXT IDIOM' : 'START IDIOM GYM',
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
      "id": "ELT_IDIOMMATCH_L1_LEARN_Q1",
      "level": 1,
      "phase": "learn",
      "targetIdiom": "under the weather",
      "optimalResponse": "under the weather",
      "meaning":
          "'Under the weather' means slightly ill or not quite yourself. It is a mild, polite way to explain a sick day without giving details.",
      "idiomOrigin":
          "A popular theory links it to sailors sent below deck in bad weather to rest and recover; the phrase has been in colloquial use for centuries.",
      "visualMetaphor":
          "Picture a small grey rain cloud parked over someone's head as they sneeze into a tissue.",
      "usageContext":
          "Casual and polite; handy for calling in sick or explaining why you're quiet today.",
      "exampleContext":
          "Marco texted his manager: 'I can't come in today. I've been sneezing all morning and I feel awful.'",
      "instruction": "Study the metaphor, historical etymology, and authentic usage of this idiom.",
      "explanation":
          "'Under the weather' means slightly ill or not quite yourself. It is a mild, polite way to explain a sick day without giving details.",
      "hint": "Think of a storm cloud sitting right over your head.",
      "authorInsight":
          "Idiomatic mastery means grasping the underlying metaphor — once visualized, the figurative meaning becomes second nature."
    }
  ];
}
