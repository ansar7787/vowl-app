import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';

/// Data model representing a word reorder syntax formula card.
class WordReorderLearnQuest {
  final String id;
  final int level;
  final String conceptTitle;
  final String structureType;
  final String topicEmoji;
  final String sentence;
  final List<String> orderedWords;
  final String ruleExplanation;
  final String nativeTip;

  const WordReorderLearnQuest({
    required this.id,
    required this.level,
    required this.conceptTitle,
    required this.structureType,
    required this.topicEmoji,
    required this.sentence,
    required this.orderedWords,
    required this.ruleExplanation,
    required this.nativeTip,
  });

  factory WordReorderLearnQuest.fromJson(Map<String, dynamic> json) {
    return WordReorderLearnQuest(
      id: json['id'] as String? ?? 'wr_learn_default',
      level: json['level'] as int? ?? 1,
      conceptTitle: json['conceptTitle'] as String? ?? 'Syntax & Word Order',
      structureType: json['structureType'] as String? ?? 'S-V-O',
      topicEmoji: json['topicEmoji'] as String? ?? '🧱',
      sentence: json['sentence'] as String? ?? '',
      orderedWords: (json['orderedWords'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      ruleExplanation: json['ruleExplanation'] as String? ?? '',
      nativeTip: json['nativeTip'] as String? ?? '',
    );
  }
}

/// Interactive Learn Phase screen for Word Reorder: "Syntax Engine Animation".
///
/// Demonstrates English word sequence structures (S-V, S-V-O, Modifiers),
/// magnetizing visual syntax blocks, auditory rhythm, and positioning logic.
class WordReorderLearnScreen extends StatefulWidget {
  final int level;

  const WordReorderLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<WordReorderLearnScreen> createState() => _WordReorderLearnScreenState();
}

class _WordReorderLearnScreenState extends State<WordReorderLearnScreen> {
  List<WordReorderLearnQuest> _quests = const [
    WordReorderLearnQuest(
      id: 'FALLBACK_WR_1',
      level: 1,
      conceptTitle: 'Basic Subject-Verb Order (S-V)',
      structureType: 'S-V',
      topicEmoji: '🧱',
      sentence: 'The students laugh.',
      orderedWords: ['The', 'students', 'laugh.'],
      ruleExplanation:
          "English statements begin with the subject before the verb: 'The students' (who) comes before 'laugh' (what they do). There is no object here — the verb alone completes the idea.",
      nativeTip:
          'Find who is doing the laughing, and place that before the action word.',
    ),
    WordReorderLearnQuest(
      id: 'FALLBACK_WR_2',
      level: 1,
      conceptTitle: 'Basic Subject-Verb Order (S-V)',
      structureType: 'S-V',
      topicEmoji: '🧱',
      sentence: 'Local musicians perform.',
      orderedWords: ['Local', 'musicians', 'perform.'],
      ruleExplanation:
          'Local describes musicians, so it stays directly in front of the noun it modifies, and the whole subject phrase comes before the verb perform.',
      nativeTip:
          'The word describing the musicians stays attached to them, right before the verb.',
    ),
  ];

  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  Future<void> _loadQuests() async {
    try {
      final startLevel = ((widget.level - 1) ~/ 10) * 10 + 1;
      final endLevel = startLevel + 9;
      final batchFile =
          'assets/curriculum/grammar/wordReorder_learn_${startLevel}_$endLevel.json';

      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests = data['quests'] as List<dynamic>? ?? [];

      final loaded = rawQuests
          .map((q) =>
              WordReorderLearnQuest.fromJson(Map<String, dynamic>.from(q as Map)))
          .where((q) => q.level == widget.level)
          .toList();

      if (loaded.isNotEmpty && mounted) {
        setState(() {
          _quests = loaded;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {
      // Gracefully fall back to pre-seeded static quests
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _speakText(String text) {
    try {
      if (di.sl.isRegistered<TtsService>()) {
        di.sl<TtsService>().speak(text);
      }
    } catch (_) {}
  }

  void _onComplete() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'wordReorder',
      level: widget.level,
      phase: 'learn',
    );
    final targetPractice =
        '/practice?category=grammar&gameType=wordReorder&level=${widget.level}';
    context.pushReplacement(targetPractice);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.violet500),
        ),
      );
    }

    final quest = _quests[_currentIndex];

    return LearnPhaseScaffold(
      title: 'Syntax Engine',
      gameType: 'wordReorder',
      level: widget.level,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'NEXT FORMULA'
          : 'READY FOR PRACTICE →',
      onComplete: () {
        if (_currentIndex < _quests.length - 1) {
          setState(() => _currentIndex++);
        } else {
          _onComplete();
        }
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Pill & Step Counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: AppColors.violet500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: AppColors.violet500.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          quest.topicEmoji,
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            'PATTERN: ${quest.structureType}',
                            style: TextStyle(
                              color: AppColors.violet500,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Formula ${_currentIndex + 1} of ${_quests.length}',
                  style: TextStyle(
                    color: AppColors.slate400,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Target Sentence Showcase Card
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: AppColors.violet500.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.violet500.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          quest.conceptTitle.toUpperCase(),
                          style: TextStyle(
                            color: AppColors.slate400,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      IconButton(
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.violet500,
                          size: 20.r,
                        ),
                        onPressed: () => _speakText(quest.sentence),
                        tooltip: 'Hear natural sentence',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    quest.sentence,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Magnetizing Syntax Blocks
            Text(
              'ORDERED SYNTAX BLOCKS',
              style: TextStyle(
                color: AppColors.slate400,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 10.h),

            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: List.generate(quest.orderedWords.length, (idx) {
                final word = quest.orderedWords[idx];
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: AppColors.violet500.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.violet500.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          color: AppColors.violet500.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        word,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            SizedBox(height: 16.h),

            // Deep Syntax Explanation
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.slate800),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology_rounded,
                        color: AppColors.violet500,
                        size: 18.r,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'WHY THIS ORDER WORKS',
                        style: TextStyle(
                          color: AppColors.violet500,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    quest.ruleExplanation,
                    style: TextStyle(
                      color: AppColors.slate300,
                      fontSize: 13.sp,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Native Speaker Ear Tip
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.amber500.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.amber500.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡', style: TextStyle(fontSize: 18.sp)),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NATIVE SPEAKER TIP',
                          style: TextStyle(
                            color: AppColors.amber400,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          quest.nativeTip,
                          style: TextStyle(
                            color: AppColors.slate300,
                            fontSize: 13.sp,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}
