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

/// Data model representing a punctuation mastery learning concept card.
class PunctuationMasteryLearnQuest {
  final String id;
  final int level;
  final String conceptTitle;
  final String punctuationMark;
  final String unpunctuatedSentence;
  final String punctuatedSentence;
  final String grammarRule;
  final String punctuationRule;
  final String ruleExplanation;
  final String nativeTip;
  final String visualAnchor;

  const PunctuationMasteryLearnQuest({
    required this.id,
    required this.level,
    required this.conceptTitle,
    required this.punctuationMark,
    required this.unpunctuatedSentence,
    required this.punctuatedSentence,
    required this.grammarRule,
    required this.punctuationRule,
    required this.ruleExplanation,
    required this.nativeTip,
    required this.visualAnchor,
  });

  factory PunctuationMasteryLearnQuest.fromJson(Map<String, dynamic> json) {
    final mark = json['punctuationMark'] as String? ?? '.';
    final unpunctuated = json['unpunctuatedSentence'] as String? ??
        (json['sentence'] as String? ?? (json['question'] as String? ?? ''));
    final punctuated = json['punctuatedSentence'] as String? ??
        (json['correctAnswer'] as String? ?? unpunctuated);

    return PunctuationMasteryLearnQuest(
      id: json['id'] as String? ?? 'pm_learn_default',
      level: json['level'] as int? ?? 1,
      conceptTitle: json['conceptTitle'] as String? ??
          'Punctuation Conductor: ${json['grammarRule'] ?? 'Punctuation'} ($mark)',
      punctuationMark: mark,
      unpunctuatedSentence: unpunctuated,
      punctuatedSentence: punctuated,
      grammarRule: json['grammarRule'] as String? ?? 'Punctuation Mechanics',
      punctuationRule: json['punctuationRule'] as String? ?? 'End Punctuation',
      ruleExplanation: json['ruleExplanation'] as String? ??
          (json['explanation'] as String? ??
              'Proper punctuation guides reader pauses and structural understanding.'),
      nativeTip: json['nativeTip'] as String? ??
          (json['hint'] as String? ??
              'Notice where natural speech requires a breath, full stop, or rising inflection.'),
      visualAnchor: json['visualAnchor'] as String? ??
          '🖋️ $unpunctuated ➔ $punctuated',
    );
  }
}

/// Rich, interactive Learn Phase screen for Punctuation Mastery: "Punctuation Pause Conductor".
///
/// Features punctuation mark anatomy, sentence cadence demonstration,
/// acoustic pause visualization, and native speaker pacing guidance.
class PunctuationMasteryLearnScreen extends StatefulWidget {
  final int level;

  const PunctuationMasteryLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<PunctuationMasteryLearnScreen> createState() =>
      _PunctuationMasteryLearnScreenState();
}

class _PunctuationMasteryLearnScreenState
    extends State<PunctuationMasteryLearnScreen> {
  List<PunctuationMasteryLearnQuest> _quests = const [
    PunctuationMasteryLearnQuest(
      id: 'FALLBACK_PM_L1',
      level: 1,
      conceptTitle: 'Punctuation Conductor: Periods (.)',
      punctuationMark: '.',
      unpunctuatedSentence: 'The library closes at nine tonight',
      punctuatedSentence: 'The library closes at nine tonight.',
      grammarRule: 'Periods',
      punctuationRule: 'End Punctuation',
      ruleExplanation:
          'A sentence that states a fact ends with a period, the most neutral end mark.',
      nativeTip:
          'The sentence is simply reporting information, not asking or exclaiming anything.',
      visualAnchor:
          '🖋️ The library closes at nine tonight ➔ The library closes at nine tonight.',
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
          'assets/curriculum/grammar/punctuationMastery_learn_${startLevel}_$endLevel.json';

      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests = data['quests'] as List<dynamic>? ?? [];

      final loaded = rawQuests
          .map((q) => PunctuationMasteryLearnQuest.fromJson(
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
      gameType: 'punctuationMastery',
      level: widget.level,
      phase: 'learn',
    );

    final targetPractice =
        '/practice?category=grammar&gameType=punctuationMastery&level=${widget.level}';
    context.pushReplacement(targetPractice);
  }

  String _getMarkDescription(String mark) {
    switch (mark) {
      case '?':
        return 'Rising Intonation / Question';
      case '!':
        return 'Emphasis / Exclamation';
      case ',':
        return 'Short Pause / Clause Boundary';
      case ';':
        return 'Connected Thought Link';
      case ':':
        return 'Introduction / Specification';
      case '—':
        return 'Dramatic Break / Parenthetical';
      case '.':
      default:
        return 'Full Stop / Neutral Cadence';
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

    return LearnPhaseScaffold(
      title: 'Punctuation Conductor',
      gameType: 'punctuationMastery',
      level: widget.level,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'NEXT PUNCTUATION CARD'
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
            // Progress tracker chip row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.teal500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColors.teal500.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Punctuation ${_currentIndex + 1} of ${_quests.length}',
                    style: TextStyle(
                      color: AppColors.teal500,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Flexible(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.violet500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.violet500.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      quest.punctuationRule,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.violet500,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Concept title card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.slate900,
                    AppColors.teal500.withValues(alpha: 0.12),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.teal500.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('🖋️', style: TextStyle(fontSize: 22.sp)),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          quest.conceptTitle,
                          style: TextStyle(
                            color: AppColors.slate100,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    quest.grammarRule,
                    style: TextStyle(
                      color: AppColors.teal500,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Punctuation Conductor Board
            Container(
              padding: EdgeInsets.all(18.r),
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
                        Icons.music_note_rounded,
                        color: AppColors.teal500,
                        size: 20.r,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'PUNCTUATION CADENCE & PAUSE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.teal500,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Giant Punctuation Badge
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.teal500.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: AppColors.teal500,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal500.withValues(alpha: 0.3),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            quest.punctuationMark,
                            style: TextStyle(
                              color: AppColors.teal500,
                              fontSize: 32.sp,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _getMarkDescription(quest.punctuationMark),
                            style: TextStyle(
                              color: AppColors.slate300,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Punctuated Master Sentence Card
                  Container(
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: AppColors.slate950,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.teal500.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'PUNCTUATED CADENCE',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.slate400,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  _speakSentence(quest.punctuatedSentence),
                              icon: Icon(
                                Icons.volume_up_rounded,
                                color: AppColors.teal500,
                                size: 18.r,
                              ),
                              tooltip: 'Listen to punctuated sentence',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          quest.punctuatedSentence,
                          style: TextStyle(
                            color: AppColors.slate100,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Grammar Breakdown Card
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
                        color: AppColors.teal500,
                        size: 18.r,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'HOW PUNCTUATION GOVERNS CADENCE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.teal500,
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
