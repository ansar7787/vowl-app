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

/// Data model representing an article insertion learning concept card.
class ArticleInsertionLearnQuest {
  final String id;
  final int level;
  final String conceptTitle;
  final String articleRule;
  final String correctArticle;
  final String topicEmoji;
  final String sentenceWithBlank;
  final String completedSentence;
  final List<String> options;
  final String grammarRule;
  final String ruleExplanation;
  final String nativeTip;
  final String visualAnchor;
  final String example;

  const ArticleInsertionLearnQuest({
    required this.id,
    required this.level,
    required this.conceptTitle,
    required this.articleRule,
    required this.correctArticle,
    required this.topicEmoji,
    required this.sentenceWithBlank,
    required this.completedSentence,
    required this.options,
    required this.grammarRule,
    required this.ruleExplanation,
    required this.nativeTip,
    required this.visualAnchor,
    required this.example,
  });

  factory ArticleInsertionLearnQuest.fromJson(Map<String, dynamic> json) {
    final correctArt = json['correctArticle'] as String? ??
        (json['correctAnswer'] as String? ?? 'a');
    final rule = json['grammarRule'] as String? ??
        (json['articleRule'] as String? ?? 'Article Usage');
    final artRule = json['articleRule'] as String? ?? 'Article: $correctArt';
    final sentenceWithBlank = json['sentenceWithBlank'] as String? ??
        (json['sentence'] as String? ?? (json['question'] as String? ?? ''));

    String cleanArt = (correctArt == '(no article)' || correctArt == 'Ø')
        ? ''
        : correctArt;
    final completedSentence = json['completedSentence'] as String? ??
        sentenceWithBlank.replaceFirst('___', cleanArt.isNotEmpty ? '$cleanArt ' : '').replaceAll('  ', ' ');

    letEmoji() {
      if (correctArt == 'an') return '🅰️';
      if (correctArt == 'the') return '🎯';
      if (correctArt == '(no article)' || correctArt == 'Ø') return '🚫';
      return '🔤';
    }

    return ArticleInsertionLearnQuest(
      id: json['id'] as String? ?? 'ai_learn_default',
      level: json['level'] as int? ?? 1,
      conceptTitle: json['conceptTitle'] as String? ?? 'Article Radar: $artRule',
      articleRule: artRule,
      correctArticle: correctArt,
      topicEmoji: json['topicEmoji'] as String? ?? letEmoji(),
      sentenceWithBlank: sentenceWithBlank,
      completedSentence: completedSentence,
      options: (json['options'] as List<dynamic>? ?? ['a', 'an', 'the', '(no article)'])
          .map((e) => e.toString())
          .toList(),
      grammarRule: rule,
      ruleExplanation: json['ruleExplanation'] as String? ??
          "Use '$correctArt' according to phonetic flow and specificity rules.",
      nativeTip: json['nativeTip'] as String? ??
          'Check whether the sound immediately after the gap is a vowel or consonant.',
      visualAnchor: json['visualAnchor'] as String? ??
          '${letEmoji()} $correctArt: $rule',
      example: json['example'] as String? ?? completedSentence,
    );
  }
}

/// Interactive Learn Phase screen for Article Insertion: "A/An/The Sound Radar".
///
/// Features phonetic sound radar visualization, acoustic flow demonstration,
/// audible sentence synthesis, and native specificity heuristics.
class ArticleInsertionLearnScreen extends StatefulWidget {
  final int level;

  const ArticleInsertionLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<ArticleInsertionLearnScreen> createState() =>
      _ArticleInsertionLearnScreenState();
}

class _ArticleInsertionLearnScreenState
    extends State<ArticleInsertionLearnScreen> {
  List<ArticleInsertionLearnQuest> _quests = const [
    ArticleInsertionLearnQuest(
      id: 'FALLBACK_AI_1',
      level: 1,
      conceptTitle: 'Article Radar: Indefinite Article (a)',
      articleRule: 'Indefinite Article (a)',
      correctArticle: 'a',
      topicEmoji: '🔤',
      sentenceWithBlank:
          "I need to grab ___ jacket before we head out — it's chilly.",
      completedSentence:
          "I need to grab a jacket before we head out — it's chilly.",
      options: ['an', 'the', 'a', '(no article)'],
      grammarRule: 'Indefinite article before a consonant sound',
      ruleExplanation:
          "'Jacket' begins with a consonant sound, so it takes 'a'. We say 'a jacket', introducing it for the first time.",
      nativeTip:
          "Say the first sound of 'jacket' out loud — it starts with a consonant sound.",
      visualAnchor: '🔤 a: Indefinite article before a consonant sound',
      example: "I need to grab a jacket before we head out — it's chilly.",
    ),
    ArticleInsertionLearnQuest(
      id: 'FALLBACK_AI_2',
      level: 1,
      conceptTitle: 'Article Radar: Indefinite Article (an)',
      articleRule: 'Indefinite Article (an)',
      correctArticle: 'an',
      topicEmoji: '🅰️',
      sentenceWithBlank: 'Can you hand me ___ envelope from that drawer?',
      completedSentence: 'Can you hand me an envelope from that drawer?',
      options: ['an', 'a', 'the', '(no article)'],
      grammarRule: 'Indefinite article before a vowel sound',
      ruleExplanation:
          "'Envelope' starts with a vowel sound, so 'an' is required. We say 'an envelope' to prevent a glottal stop clash.",
      nativeTip: 'Notice the vowel sound right at the start of envelope.',
      visualAnchor: '🅰️ an: Indefinite article before a vowel sound',
      example: 'Can you hand me an envelope from that drawer?',
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
          'assets/curriculum/grammar/articleInsertion_learn_${startLevel}_$endLevel.json';

      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests = data['quests'] as List<dynamic>? ?? [];

      final loaded = rawQuests
          .map((q) => ArticleInsertionLearnQuest.fromJson(
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
      gameType: 'articleInsertion',
      level: widget.level,
      phase: 'learn',
    );

    final targetPractice =
        '/practice?category=grammar&gameType=articleInsertion&level=${widget.level}';
    context.pushReplacement(targetPractice);
  }

  Color _getArticleColor(String article) {
    switch (article.toLowerCase()) {
      case 'an':
        return AppColors.amber500;
      case 'the':
        return AppColors.violet500;
      case '(no article)':
      case 'ø':
        return AppColors.rose500;
      case 'a':
      default:
        return AppColors.teal500;
    }
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
    final activeColor = _getArticleColor(quest.correctArticle);

    return LearnPhaseScaffold(
      title: 'Sound Radar',
      gameType: 'articleInsertion',
      level: widget.level,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'NEXT ARTICLE CARD'
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

            // Sound & Specificity Radar Visualization
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
                        Icons.radar_rounded,
                        color: activeColor,
                        size: 18.r,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'ARTICLE ACOUSTIC RADAR',
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
                      _buildRadarNode(
                        label: 'A',
                        subtext: 'Consonant',
                        isActive: quest.correctArticle.toLowerCase() == 'a',
                        nodeColor: AppColors.teal500,
                      ),
                      SizedBox(width: 6.w),
                      _buildRadarNode(
                        label: 'AN',
                        subtext: 'Vowel',
                        isActive: quest.correctArticle.toLowerCase() == 'an',
                        nodeColor: AppColors.amber500,
                      ),
                      SizedBox(width: 6.w),
                      _buildRadarNode(
                        label: 'THE',
                        subtext: 'Specific',
                        isActive: quest.correctArticle.toLowerCase() == 'the',
                        nodeColor: AppColors.violet500,
                      ),
                      SizedBox(width: 6.w),
                      _buildRadarNode(
                        label: 'Ø',
                        subtext: 'Zero Art',
                        isActive: quest.correctArticle.toLowerCase() ==
                                '(no article)' ||
                            quest.correctArticle == 'Ø',
                        nodeColor: AppColors.rose500,
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
                                'NATURAL SPEECH FLOW',
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
                          'HOW THE ARTICLE FLOWS',
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

  Widget _buildRadarNode({
    required String label,
    required String subtext,
    required bool isActive,
    required Color nodeColor,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: isActive
              ? nodeColor.withValues(alpha: 0.2)
              : AppColors.slate950,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isActive ? nodeColor : AppColors.slate800,
            width: isActive ? 2.0 : 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: nodeColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? nodeColor : AppColors.slate300,
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              subtext,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isActive ? nodeColor : AppColors.slate500,
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
