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

/// Data model representing a parts-of-speech learning quest.
class PartsOfSpeechLearnQuest {
  final String id;
  final int level;
  final String conceptTitle;
  final String partOfSpeech;
  final String colorCode;
  final String topicEmoji;
  final String targetWord;
  final String sentence;
  final String highlightedWord;
  final String grammarRule;
  final String roleExplanation;
  final String nativeTip;
  final String visualAnchor;
  final String example;

  const PartsOfSpeechLearnQuest({
    required this.id,
    required this.level,
    required this.conceptTitle,
    required this.partOfSpeech,
    required this.colorCode,
    required this.topicEmoji,
    required this.targetWord,
    required this.sentence,
    required this.highlightedWord,
    required this.grammarRule,
    required this.roleExplanation,
    required this.nativeTip,
    required this.visualAnchor,
    required this.example,
  });

  factory PartsOfSpeechLearnQuest.fromJson(Map<String, dynamic> json) {
    return PartsOfSpeechLearnQuest(
      id: json['id'] as String? ?? 'pos_learn_default',
      level: json['level'] as int? ?? 1,
      conceptTitle: json['conceptTitle'] as String? ?? 'Sentence Anatomy',
      partOfSpeech: json['partOfSpeech'] as String? ?? 'Noun',
      colorCode: json['colorCode'] as String? ?? '#3B82F6',
      topicEmoji: json['topicEmoji'] as String? ?? '📦',
      targetWord: json['targetWord'] as String? ?? '',
      sentence: json['sentence'] as String? ?? '',
      highlightedWord: json['highlightedWord'] as String? ?? '',
      grammarRule: json['grammarRule'] as String? ?? 'Grammar Rule',
      roleExplanation: json['roleExplanation'] as String? ?? '',
      nativeTip: json['nativeTip'] as String? ?? '',
      visualAnchor: json['visualAnchor'] as String? ?? '',
      example: json['example'] as String? ?? '',
    );
  }
}

/// Interactive Learn Phase screen for Parts of Speech: "Sentence Anatomy Color-Coder".
///
/// Teaches grammatical anatomy through color-coded lenses, sentence parsing,
/// role explanations, and native syntax rules before testing.
class PartsOfSpeechLearnScreen extends StatefulWidget {
  final int level;

  const PartsOfSpeechLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<PartsOfSpeechLearnScreen> createState() =>
      _PartsOfSpeechLearnScreenState();
}

class _PartsOfSpeechLearnScreenState extends State<PartsOfSpeechLearnScreen> {
  List<PartsOfSpeechLearnQuest> _quests = const [
    PartsOfSpeechLearnQuest(
      id: 'FALLBACK_POS_1',
      level: 1,
      conceptTitle: 'Sentence Anatomy: NOUN',
      partOfSpeech: 'Noun',
      colorCode: '#3B82F6',
      topicEmoji: '📦',
      targetWord: 'kitchen',
      sentence: 'Grandma Rose is baking cookies in the kitchen right now.',
      highlightedWord: 'kitchen',
      grammarRule: 'Common noun naming a place',
      roleExplanation:
          "'Kitchen' is a noun because it names a place — the room where Grandma Rose is baking. Nouns identify people, places, things, or ideas.",
      nativeTip:
          "Nouns name people, places, things, or ideas. Look for the location word following 'in the...'.",
      visualAnchor: '🏠 kitchen → Place → Noun',
      example: 'Grandma Rose is baking cookies in the kitchen right now.',
    ),
    PartsOfSpeechLearnQuest(
      id: 'FALLBACK_POS_2',
      level: 1,
      conceptTitle: 'Sentence Anatomy: VERB',
      partOfSpeech: 'Verb',
      colorCode: '#10B981',
      topicEmoji: '⚡',
      targetWord: 'whistled',
      sentence: 'The referee whistled sharply to stop the game.',
      highlightedWord: 'whistled',
      grammarRule: 'Action verb in past tense',
      roleExplanation:
          "'Whistled' is a verb — it names the action the referee performed to stop the game. Past-tense verbs describe completed actions.",
      nativeTip:
          'Verbs show actions or states of being. Ask yourself: what is the subject DOING?',
      visualAnchor: '⚡ whistled → Action → Verb',
      example: 'The referee whistled sharply to stop the game.',
    ),
    PartsOfSpeechLearnQuest(
      id: 'FALLBACK_POS_3',
      level: 1,
      conceptTitle: 'Sentence Anatomy: ADJECTIVE',
      partOfSpeech: 'Adjective',
      colorCode: '#F59E0B',
      topicEmoji: '🎨',
      targetWord: 'cold',
      sentence: 'The lake felt icy cold after the autumn rain.',
      highlightedWord: 'cold',
      grammarRule: 'Predicate adjective after a linking verb',
      roleExplanation:
          "'Cold' is an adjective describing the lake's temperature. It follows the linking verb 'felt' and tells us what the lake was like.",
      nativeTip:
          'Adjectives describe or modify nouns and pronouns. They answer: what kind? which one? how many?',
      visualAnchor: '🎨 cold → Description → Adjective',
      example: 'The lake felt icy cold after the autumn rain.',
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
          'assets/curriculum/grammar/partsOfSpeech_learn_${startLevel}_$endLevel.json';

      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests = data['quests'] as List<dynamic>? ?? [];

      final loaded = rawQuests
          .map((q) =>
              PartsOfSpeechLearnQuest.fromJson(Map<String, dynamic>.from(q as Map)))
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

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('0xFF$clean'));
    } catch (_) {
      return Colors.blue;
    }
  }

  void _onComplete() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'partsOfSpeech',
      level: widget.level,
      phase: 'learn',
    );
    final targetPractice =
        '/practice?category=grammar&gameType=partsOfSpeech&level=${widget.level}';
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
    final color = _parseColor(quest.colorCode);

    return LearnPhaseScaffold(
      title: 'Sentence Anatomy',
      gameType: 'partsOfSpeech',
      level: widget.level,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'NEXT CONCEPT'
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
            // Step Counter & Lens Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      quest.topicEmoji,
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      quest.partOfSpeech.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Concept ${_currentIndex + 1} of ${_quests.length}',
                style: TextStyle(
                  color: AppColors.slate400,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Main Sentence Anatomy Card
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: AppColors.slate900,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quest.conceptTitle,
                            style: TextStyle(
                              color: color,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            quest.targetWord,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.volume_up_rounded,
                        color: color,
                        size: 26.r,
                      ),
                      onPressed: () => _speakText(
                        '${quest.targetWord}. ${quest.sentence}',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),

                // Sentence with highlighted target word
                Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: _buildSentenceSpans(
                        quest.sentence,
                        quest.highlightedWord,
                        color,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),

                // Grammar Rule Badge
                Row(
                  children: [
                    Icon(Icons.rule_rounded, color: color, size: 16.r),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        quest.grammarRule,
                        style: TextStyle(
                          color: AppColors.slate300,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),

          // Role & Anatomy Explanation Card
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: AppColors.slate900.withValues(alpha: 0.7),
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
                      'HOW IT FUNCTIONS',
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
                  quest.roleExplanation,
                  style: TextStyle(
                    color: AppColors.slate200,
                    fontSize: 13.sp,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),

          // Native Speaker Tip Card
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: AppColors.amber500.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.amber500.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💡', style: TextStyle(fontSize: 18.sp)),
                SizedBox(width: 10.w),
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
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        quest.nativeTip,
                        style: TextStyle(
                          color: AppColors.slate200,
                          fontSize: 12.sp,
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

  List<InlineSpan> _buildSentenceSpans(
    String sentence,
    String target,
    Color highlightColor,
  ) {
    if (target.isEmpty || !sentence.toLowerCase().contains(target.toLowerCase())) {
      return [
        TextSpan(
          text: sentence,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15.sp,
            height: 1.45,
          ),
        )
      ];
    }

    final spans = <InlineSpan>[];
    final lowerSentence = sentence.toLowerCase();
    final lowerTarget = target.toLowerCase();
    int start = 0;

    while (true) {
      final matchIndex = lowerSentence.indexOf(lowerTarget, start);
      if (matchIndex == -1) {
        if (start < sentence.length) {
          spans.add(
            TextSpan(
              text: sentence.substring(start),
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.sp,
                height: 1.45,
              ),
            ),
          );
        }
        break;
      }

      if (matchIndex > start) {
        spans.add(
          TextSpan(
            text: sentence.substring(start, matchIndex),
            style: TextStyle(
              color: Colors.white,
              fontSize: 15.sp,
              height: 1.45,
            ),
          ),
        );
      }

      final matchedText =
          sentence.substring(matchIndex, matchIndex + target.length);
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: highlightColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(color: highlightColor, width: 1.5),
            ),
            child: Text(
              matchedText,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15.sp,
              ),
            ),
          ),
        ),
      );

      start = matchIndex + target.length;
    }

    return spans;
  }
}
