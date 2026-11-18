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

/// Data model representing a grammar quest learning card.
class GrammarQuestLearnQuest {
  final String id;
  final int level;
  final String conceptTitle;
  final String grammarRule;
  final String topicEmoji;
  final String equation;
  final String correctSentence;
  final String contrastSentence;
  final String targetWord;
  final String ruleExplanation;
  final String nativeTip;

  const GrammarQuestLearnQuest({
    required this.id,
    required this.level,
    required this.conceptTitle,
    required this.grammarRule,
    required this.topicEmoji,
    required this.equation,
    required this.correctSentence,
    required this.contrastSentence,
    required this.targetWord,
    required this.ruleExplanation,
    required this.nativeTip,
  });

  factory GrammarQuestLearnQuest.fromJson(Map<String, dynamic> json) {
    return GrammarQuestLearnQuest(
      id: json['id'] as String? ?? 'gq_learn_default',
      level: json['level'] as int? ?? 1,
      conceptTitle: json['conceptTitle'] as String? ?? 'Grammar Rule',
      grammarRule: json['grammarRule'] as String? ?? 'Grammar Rule',
      topicEmoji: json['topicEmoji'] as String? ?? '📜',
      equation: json['equation'] as String? ?? '',
      correctSentence: json['correctSentence'] as String? ?? '',
      contrastSentence: json['contrastSentence'] as String? ?? '',
      targetWord: json['targetWord'] as String? ?? '',
      ruleExplanation: json['ruleExplanation'] as String? ?? '',
      nativeTip: json['nativeTip'] as String? ?? '',
    );
  }
}

/// Interactive Learn Phase screen for Grammar Quest: "Rule Discovery Board".
///
/// Features grammar equations, side-by-side contrasting sentences (Correct vs Clash),
/// audio pronunciation, architectural explanations, and native speaker tips.
class GrammarQuestLearnScreen extends StatefulWidget {
  final int level;

  const GrammarQuestLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<GrammarQuestLearnScreen> createState() =>
      _GrammarQuestLearnScreenState();
}

class _GrammarQuestLearnScreenState extends State<GrammarQuestLearnScreen> {
  List<GrammarQuestLearnQuest> _quests = const [
    GrammarQuestLearnQuest(
      id: 'FALLBACK_GQ_1',
      level: 1,
      conceptTitle: "Verb 'To Be': Present Tense with I",
      grammarRule: "Verb 'To Be': Present Tense with I",
      topicEmoji: '📜',
      equation: 'Subject [I] + Verb [am]',
      correctSentence: 'I am from Brazil.',
      contrastSentence: 'I is from Brazil.',
      targetWord: 'am',
      ruleExplanation:
          "'I' always takes 'am'. It never changes, no matter what comes after it: I am from Brazil, I am tired, I am here.",
      nativeTip: "There is only one form of 'be' that ever goes with 'I'.",
    ),
    GrammarQuestLearnQuest(
      id: 'FALLBACK_GQ_2',
      level: 1,
      conceptTitle: "Verb 'To Be': Third-Person Singular",
      grammarRule: "Verb 'To Be': Third-Person Singular",
      topicEmoji: '📜',
      equation: 'Subject [He/She/It] + Verb [is]',
      correctSentence: 'My brother is a doctor.',
      contrastSentence: 'My brother are a doctor.',
      targetWord: 'is',
      ruleExplanation:
          "'My brother' can be replaced with 'he', and 'he/she/it' always takes 'is'. Compare: My sister is a nurse. The dog is friendly.",
      nativeTip: "'My brother' means 'he'. Which form of 'be' matches he/she/it?",
    ),
    GrammarQuestLearnQuest(
      id: 'FALLBACK_GQ_3',
      level: 1,
      conceptTitle: "Verb 'To Be': Plural Subjects",
      grammarRule: "Verb 'To Be': Plural Subjects",
      topicEmoji: '📜',
      equation: 'Subject [They/We/You] + Verb [are]',
      correctSentence: 'Yes, they are home now.',
      contrastSentence: 'Yes, they is home now.',
      targetWord: 'are',
      ruleExplanation:
          "Plural subjects such as 'they', 'we', and 'you' all take 'are'. Only 'he/she/it' takes 'is', and only 'I' takes 'am'.",
      nativeTip: "'They' is plural, like 'we' and 'you'.",
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
          'assets/curriculum/grammar/grammarQuest_learn_${startLevel}_$endLevel.json';

      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests = data['quests'] as List<dynamic>? ?? [];

      final loaded = rawQuests
          .map((q) =>
              GrammarQuestLearnQuest.fromJson(Map<String, dynamic>.from(q as Map)))
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
      gameType: 'grammarQuest',
      level: widget.level,
      phase: 'learn',
    );
    final targetPractice =
        '/practice?category=grammar&gameType=grammarQuest&level=${widget.level}';
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
      title: 'Rule Discovery Board',
      gameType: 'grammarQuest',
      level: widget.level,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'NEXT RULE'
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
                            'GRAMMAR EQUATION',
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
                  'Rule ${_currentIndex + 1} of ${_quests.length}',
                  style: TextStyle(
                    color: AppColors.slate400,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Rule Formula Card
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
                    quest.grammarRule.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.slate400,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    quest.equation,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Side-by-Side Contrasting Sentences
            Text(
              'CONTRASTING PATTERNS',
              style: TextStyle(
                color: AppColors.slate400,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 10.h),

            // 1. Correct / Natural Pattern
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
                            'CORRECT & NATURAL',
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
                        onPressed: () => _speakText(quest.correctSentence),
                        tooltip: 'Hear natural flow',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    quest.correctSentence,
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

            // 2. Incorrect / Clash Pattern
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
                        'COMMON ERROR / AWKWARD CLASH',
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
                    quest.contrastSentence,
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

            // Deep Rule Explanation
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
                        'WHY THIS RULE WORKS',
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
