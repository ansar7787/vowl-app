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

/// Data model representing a subject-verb agreement learning card.
class SubjectVerbAgreementLearnQuest {
  final String id;
  final int level;
  final String conceptTitle;
  final String subjectType;
  final String topicEmoji;
  final String sentenceWithBlank;
  final String completedSentence;
  final String correctVerb;
  final List<String> options;
  final String grammarRule;
  final String ruleExplanation;
  final String nativeTip;
  final String visualAnchor;
  final String example;

  const SubjectVerbAgreementLearnQuest({
    required this.id,
    required this.level,
    required this.conceptTitle,
    required this.subjectType,
    required this.topicEmoji,
    required this.sentenceWithBlank,
    required this.completedSentence,
    required this.correctVerb,
    required this.options,
    required this.grammarRule,
    required this.ruleExplanation,
    required this.nativeTip,
    required this.visualAnchor,
    required this.example,
  });

  factory SubjectVerbAgreementLearnQuest.fromJson(Map<String, dynamic> json) {
    final subjectType = json['subjectType'] as String? ?? 'Singular';
    final rule = json['grammarRule'] as String? ?? '$subjectType Agreement';
    final emoji = json['topicEmoji'] as String? ??
        (subjectType.toLowerCase().contains('plural') ? '👥' : '⚖️');
    final sentenceWithBlank = json['sentenceWithBlank'] as String? ??
        (json['question'] as String? ?? '');
    final correctVerb = json['correctVerb'] as String? ??
        (json['correctAnswer'] as String? ?? '');
    final completedSentence = json['completedSentence'] as String? ??
        sentenceWithBlank.replaceFirst('___', correctVerb);

    return SubjectVerbAgreementLearnQuest(
      id: json['id'] as String? ?? 'sva_learn_default',
      level: json['level'] as int? ?? 1,
      conceptTitle: json['conceptTitle'] as String? ?? 'Grammar Scale: $rule',
      subjectType: subjectType,
      topicEmoji: emoji,
      sentenceWithBlank: sentenceWithBlank,
      completedSentence: completedSentence,
      correctVerb: correctVerb,
      options: (json['options'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      grammarRule: rule,
      ruleExplanation: json['ruleExplanation'] as String? ??
          'Singular subjects require singular verbs, while plural subjects require plural verbs.',
      nativeTip: json['nativeTip'] as String? ??
          'Look closely at whether the subject is one unit or multiple.',
      visualAnchor: json['visualAnchor'] as String? ??
          '$emoji $subjectType: $correctVerb',
      example: json['example'] as String? ?? completedSentence,
    );
  }
}

/// Interactive Learn Phase screen for Subject-Verb Agreement: "The Grammar Scale".
///
/// Features grammatical balance scale visualization, subject-verb synchronization,
/// audible sentence articulation, and native agreement tips.
class SubjectVerbAgreementLearnScreen extends StatefulWidget {
  final int level;

  const SubjectVerbAgreementLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<SubjectVerbAgreementLearnScreen> createState() =>
      _SubjectVerbAgreementLearnScreenState();
}

class _SubjectVerbAgreementLearnScreenState
    extends State<SubjectVerbAgreementLearnScreen> {
  List<SubjectVerbAgreementLearnQuest> _quests = const [
    SubjectVerbAgreementLearnQuest(
      id: 'FALLBACK_SVA_1',
      level: 1,
      conceptTitle: 'Grammar Scale: Third-Person Singular Present',
      subjectType: 'Singular',
      topicEmoji: '⚖️',
      sentenceWithBlank: 'The bakery ___ fresh croissants at dawn.',
      completedSentence: 'The bakery bakes fresh croissants at dawn.',
      correctVerb: 'bakes',
      options: ['bake', 'bakes'],
      grammarRule: 'Third-person singular subject in the simple present',
      ruleExplanation:
          "'The bakery' names one single business, so it counts as a third-person singular subject. In the simple present, singular subjects take a verb ending in -s or -es.",
      nativeTip:
          'Find the one entity performing the action, then decide if it needs the -s ending.',
      visualAnchor: '⚖️ Singular: bakes',
      example: 'The bakery bakes fresh croissants at dawn.',
    ),
    SubjectVerbAgreementLearnQuest(
      id: 'FALLBACK_SVA_2',
      level: 1,
      conceptTitle: 'Grammar Scale: Plural Subject in Simple Present',
      subjectType: 'Plural',
      topicEmoji: '👥',
      sentenceWithBlank: 'The interns ___ coffee for the team every afternoon.',
      completedSentence:
          'The interns make coffee for the team every afternoon.',
      correctVerb: 'make',
      options: ['makes', 'make'],
      grammarRule: 'Plural subject in the simple present',
      ruleExplanation:
          "'The interns' is a plural subject. Plural subjects in the simple present use the base form of the verb, so 'make' is correct.",
      nativeTip:
          "Notice that 'interns' ends in -s as a noun. Plural nouns pair with base verbs without an extra -s.",
      visualAnchor: '👥 Plural: make',
      example: 'The interns make coffee for the team every afternoon.',
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
          'assets/curriculum/grammar/subjectVerbAgreement_learn_${startLevel}_$endLevel.json';

      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests = data['quests'] as List<dynamic>? ?? [];

      final loaded = rawQuests
          .map((q) => SubjectVerbAgreementLearnQuest.fromJson(
              Map<String, dynamic>.from(q as Map)))
          .where((q) => q.level == widget.level)
          .toList();

      if (mounted) {
        setState(() {
          if (loaded.isNotEmpty) {
            _quests = loaded;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _speakSentence(String text) {
    if (text.isEmpty) return;
    try {
      if (di.sl.isRegistered<TtsService>()) {
        di.sl<TtsService>().speak(text);
      }
    } catch (_) {}
  }

  void _onComplete() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'subjectVerbAgreement',
      level: widget.level,
      phase: 'learn',
    );

    final targetPractice =
        '/practice?category=grammar&gameType=subjectVerbAgreement&level=${widget.level}';
    context.pushReplacement(targetPractice);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.slate950,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.teal500),
        ),
      );
    }

    final quest = _quests[_currentIndex];
    final isPlural = quest.subjectType.toLowerCase().contains('plural');
    final activeColor = isPlural ? AppColors.indigo400 : AppColors.amber500;

    return LearnPhaseScaffold(
      title: 'Grammar Scale',
      gameType: 'subjectVerbAgreement',
      level: widget.level,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'NEXT SCALE CARD'
          : 'CONTINUE TO PRACTICE →',
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
            // Concept Header Pill & Step Counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: activeColor.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          quest.topicEmoji,
                          style: TextStyle(fontSize: 15.sp),
                        ),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: Text(
                            quest.conceptTitle.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: activeColor,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  'Concept ${_currentIndex + 1} of ${_quests.length}',
                  style: TextStyle(
                    color: AppColors.slate500,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Grammar Scale Interactive Balance Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.slate800),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.balance_rounded,
                        color: activeColor,
                        size: 18.r,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'SYNTACTIC EQUILIBRIUM',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: activeColor,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      // Subject Pan
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color: AppColors.slate950,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: activeColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                isPlural ? 'PLURAL SUBJECT' : 'SINGULAR SUBJECT',
                                style: TextStyle(
                                  color: AppColors.slate400,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                quest.subjectType.toUpperCase(),
                                style: TextStyle(
                                  color: activeColor,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Icon(
                          Icons.swap_horiz_rounded,
                          color: AppColors.emerald400,
                          size: 24.r,
                        ),
                      ),
                      // Verb Pan
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color: AppColors.slate950,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: AppColors.emerald500.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'BALANCED VERB',
                                style: TextStyle(
                                  color: AppColors.slate400,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                quest.correctVerb.toUpperCase(),
                                style: TextStyle(
                                  color: AppColors.emerald400,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Completed Sentence Display with Audio
            Container(
              padding: EdgeInsets.all(18.r),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: activeColor.withValues(alpha: 0.3),
                  width: 1.2,
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
                              Icons.format_quote_rounded,
                              color: activeColor,
                              size: 18.r,
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                'NATURAL AGREEMENT',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: activeColor,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _speakSentence(quest.completedSentence),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: activeColor,
                          size: 22.r,
                        ),
                        tooltip: 'Listen to sentence',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    quest.completedSentence,
                    style: TextStyle(
                      color: AppColors.slate100,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Rule & Mechanism Breakdown Card
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
                        color: activeColor,
                        size: 18.r,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'WHY THE SCALE BALANCES',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: activeColor,
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

            // Native Speaker Intuition Tip
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
