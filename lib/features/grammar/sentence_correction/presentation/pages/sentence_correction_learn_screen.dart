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

/// Data model representing a sentence correction diagnostic card.
class SentenceCorrectionLearnQuest {
  final String id;
  final int level;
  final String conceptTitle;
  final String errorHighlight;
  final String topicEmoji;
  final String faultySentence;
  final String incorrectPart;
  final String correctedSentence;
  final String correctedPart;
  final String ruleExplanation;
  final String nativeTip;

  const SentenceCorrectionLearnQuest({
    required this.id,
    required this.level,
    required this.conceptTitle,
    required this.errorHighlight,
    required this.topicEmoji,
    required this.faultySentence,
    required this.incorrectPart,
    required this.correctedSentence,
    required this.correctedPart,
    required this.ruleExplanation,
    required this.nativeTip,
  });

  factory SentenceCorrectionLearnQuest.fromJson(Map<String, dynamic> json) {
    return SentenceCorrectionLearnQuest(
      id: json['id'] as String? ?? 'sc_learn_default',
      level: json['level'] as int? ?? 1,
      conceptTitle: json['conceptTitle'] as String? ?? 'Error Diagnosis',
      errorHighlight: json['errorHighlight'] as String? ?? 'Grammar Error',
      topicEmoji: json['topicEmoji'] as String? ?? '🔍',
      faultySentence: json['faultySentence'] as String? ?? '',
      incorrectPart: json['incorrectPart'] as String? ?? '',
      correctedSentence: json['correctedSentence'] as String? ?? '',
      correctedPart: json['correctedPart'] as String? ?? '',
      ruleExplanation: json['ruleExplanation'] as String? ?? '',
      nativeTip: json['nativeTip'] as String? ?? '',
    );
  }
}

/// Interactive Learn Phase screen for Sentence Correction: "The Editor's Lens".
///
/// Features side-by-side diagnostic cards comparing faulty versus corrected sentences,
/// audible natural phrasing, grammatical breakdown, and native intuition tips.
class SentenceCorrectionLearnScreen extends StatefulWidget {
  final int level;

  const SentenceCorrectionLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<SentenceCorrectionLearnScreen> createState() =>
      _SentenceCorrectionLearnScreenState();
}

class _SentenceCorrectionLearnScreenState
    extends State<SentenceCorrectionLearnScreen> {
  List<SentenceCorrectionLearnQuest> _quests = const [
    SentenceCorrectionLearnQuest(
      id: 'FALLBACK_SC_1',
      level: 1,
      conceptTitle: 'Subject-Verb Agreement: Be Verb with Plural Subjects',
      errorHighlight: 'Incorrect verb',
      topicEmoji: '🔍',
      faultySentence: 'The children is playing in the yard.',
      incorrectPart: 'is',
      correctedSentence: 'The children are playing in the yard.',
      correctedPart: 'are',
      ruleExplanation:
          "The subject 'children' is plural, so it needs the plural form 'are' instead of the singular 'is'.",
      nativeTip:
          "Look at the subject 'children' — is it one child or more than one?",
    ),
    SentenceCorrectionLearnQuest(
      id: 'FALLBACK_SC_2',
      level: 1,
      conceptTitle: 'Subject-Verb Agreement: Singular Uncountable Nouns',
      errorHighlight: 'Incorrect verb',
      topicEmoji: '🔍',
      faultySentence: "The news are on at six o'clock every evening.",
      incorrectPart: 'are',
      correctedSentence: "The news is on at six o'clock every evening.",
      correctedPart: 'is',
      ruleExplanation:
          "'News' looks plural because of the final -s, but it is grammatically singular and takes 'is', not 'are'.",
      nativeTip:
          "Some nouns that end in -s, like 'news', are actually singular. What verb goes with a singular subject?",
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
          'assets/curriculum/grammar/sentenceCorrection_learn_${startLevel}_$endLevel.json';

      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests = data['quests'] as List<dynamic>? ?? [];

      final loaded = rawQuests
          .map((q) => SentenceCorrectionLearnQuest.fromJson(
              Map<String, dynamic>.from(q as Map)))
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
      gameType: 'sentenceCorrection',
      level: widget.level,
      phase: 'learn',
    );
    final targetPractice =
        '/practice?category=grammar&gameType=sentenceCorrection&level=${widget.level}';
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
      title: "Editor's Lens",
      gameType: 'sentenceCorrection',
      level: widget.level,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'NEXT DIAGNOSIS'
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
                            'DIAGNOSIS: ${quest.errorHighlight.toUpperCase()}',
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
                  'Diagnosis ${_currentIndex + 1} of ${_quests.length}',
                  style: TextStyle(
                    color: AppColors.slate400,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Rule Headline Card
            Container(
              padding: EdgeInsets.all(18.r),
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
                  Text(
                    'GRAMMATICAL PRINCIPLE',
                    style: TextStyle(
                      color: AppColors.slate400,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    quest.conceptTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Side-by-Side Diagnostic Showcase
            Text(
              "THE EDITOR'S COMPARISON",
              style: TextStyle(
                color: AppColors.slate400,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 10.h),

            // 1. Corrected & Fluent Version
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.emerald500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.emerald500,
                            size: 18.r,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'CORRECTED & NATURAL',
                            style: TextStyle(
                              color: AppColors.emerald500,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.emerald400,
                          size: 20.r,
                        ),
                        onPressed: () => _speakText(quest.correctedSentence),
                        tooltip: 'Hear fluent sentence',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    quest.correctedSentence,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),

            // 2. Faulty Sentence with Highlighted Error
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.rose500.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.rose500.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cancel_rounded,
                        color: AppColors.rose500,
                        size: 18.r,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'FAULTY DRAFT',
                        style: TextStyle(
                          color: AppColors.rose500,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    quest.faultySentence,
                    style: TextStyle(
                      color: AppColors.slate300,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppColors.rose500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Detailed Rule Explanation
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
                      Expanded(
                        child: Text(
                          'WHY THIS SOUNDS AWKWARD TO NATIVE EARS',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.violet500,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
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
