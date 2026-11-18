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

/// Data model representing a tense mastery timeline concept card.
class TenseMasteryLearnQuest {
  final String id;
  final int level;
  final String conceptTitle;
  final String timelinePosition;
  final String topicEmoji;
  final String sentence;
  final String grammarRule;
  final String ruleExplanation;
  final String nativeTip;
  final String visualAnchor;
  final String example;

  const TenseMasteryLearnQuest({
    required this.id,
    required this.level,
    required this.conceptTitle,
    required this.timelinePosition,
    required this.topicEmoji,
    required this.sentence,
    required this.grammarRule,
    required this.ruleExplanation,
    required this.nativeTip,
    required this.visualAnchor,
    required this.example,
  });

  factory TenseMasteryLearnQuest.fromJson(Map<String, dynamic> json) {
    final timelinePos = json['timelinePosition'] as String? ?? 'Present';
    final rule = json['grammarRule'] as String? ?? '$timelinePos Tense';
    final emoji = json['topicEmoji'] as String? ??
        (timelinePos == 'Past'
            ? '⏮️'
            : (timelinePos == 'Future' ? '⏭️' : '▶️'));

    return TenseMasteryLearnQuest(
      id: json['id'] as String? ?? 'tm_learn_default',
      level: json['level'] as int? ?? 1,
      conceptTitle: json['conceptTitle'] as String? ?? 'Timeline Mapping: $rule',
      timelinePosition: timelinePos,
      topicEmoji: emoji,
      sentence: json['sentence'] as String? ?? '',
      grammarRule: rule,
      ruleExplanation: json['ruleExplanation'] as String? ??
          'This event is positioned on the $timelinePos timeline.',
      nativeTip: json['nativeTip'] as String? ??
          'Observe temporal markers to identify the correct tense.',
      visualAnchor: json['visualAnchor'] as String? ??
          '$emoji $timelinePos: $rule',
      example: json['example'] as String? ?? (json['sentence'] as String? ?? ''),
    );
  }
}

/// Interactive Learn Phase screen for Tense Mastery: "Interactive Time Machine".
///
/// Features chronological timeline visualization (Past | Present | Future),
/// temporal marker anchoring, auditory sentence playback, and deep tense mechanics.
class TenseMasteryLearnScreen extends StatefulWidget {
  final int level;

  const TenseMasteryLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<TenseMasteryLearnScreen> createState() => _TenseMasteryLearnScreenState();
}

class _TenseMasteryLearnScreenState extends State<TenseMasteryLearnScreen> {
  List<TenseMasteryLearnQuest> _quests = const [
    TenseMasteryLearnQuest(
      id: 'FALLBACK_TM_1',
      level: 1,
      conceptTitle: 'Timeline Mapping: Simple Past Tense',
      timelinePosition: 'Past',
      topicEmoji: '⏮️',
      sentence: 'The barista wiped down the espresso machine before closing last night.',
      grammarRule: 'Simple Past Tense',
      ruleExplanation:
          'Wiped is the simple past form of wipe. Last night marks a single completed action, not a routine.',
      nativeTip:
          'This cleaning happened at a specific moment that has already come and gone.',
      visualAnchor: '⏮️ Past: Simple Past Tense',
      example: 'The barista wiped down the espresso machine before closing last night.',
    ),
    TenseMasteryLearnQuest(
      id: 'FALLBACK_TM_2',
      level: 1,
      conceptTitle: 'Timeline Mapping: Simple Present Tense',
      timelinePosition: 'Present',
      topicEmoji: '▶️',
      sentence: 'Every morning, the barista opens the shop and grinds fresh coffee beans.',
      grammarRule: 'Simple Present Tense',
      ruleExplanation:
          'Opens and grinds are simple present forms describing a daily routine rather than a single moment.',
      nativeTip: "This isn't a one-time event — it happens again and again.",
      visualAnchor: '▶️ Present: Simple Present Tense',
      example: 'Every morning, the barista opens the shop and grinds fresh coffee beans.',
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
          'assets/curriculum/grammar/tenseMastery_learn_${startLevel}_$endLevel.json';

      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests = data['quests'] as List<dynamic>? ?? [];

      final loaded = rawQuests
          .map((q) => TenseMasteryLearnQuest.fromJson(Map<String, dynamic>.from(q as Map)))
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

  Color _getTimelineColor(String position) {
    switch (position.toLowerCase()) {
      case 'past':
        return AppColors.amber500;
      case 'future':
        return AppColors.violet500;
      case 'present':
      default:
        return AppColors.teal500;
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
      gameType: 'tenseMastery',
      level: widget.level,
      phase: 'learn',
    );

    final targetPractice =
        '/practice?category=grammar&gameType=tenseMastery&level=${widget.level}';
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
    final activeColor = _getTimelineColor(quest.timelinePosition);

    return LearnPhaseScaffold(
      title: 'Time Machine',
      gameType: 'tenseMastery',
      level: widget.level,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'NEXT TIMELINE CARD'
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
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
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

            // Time Machine Chrono-Rail Visualization
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
                        Icons.access_time_rounded,
                        color: AppColors.slate400,
                        size: 16.r,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'TIMELINE ORIENTATION',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.slate400,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      _buildTimelineNode(
                        label: 'PAST',
                        emoji: '⏮️',
                        isActive: quest.timelinePosition.toLowerCase() == 'past',
                        nodeColor: AppColors.amber500,
                      ),
                      _buildTimelineRail(
                        isActive: quest.timelinePosition.toLowerCase() == 'past' ||
                            quest.timelinePosition.toLowerCase() == 'present',
                        activeColor: activeColor,
                      ),
                      _buildTimelineNode(
                        label: 'PRESENT',
                        emoji: '▶️',
                        isActive: quest.timelinePosition.toLowerCase() == 'present',
                        nodeColor: AppColors.teal500,
                      ),
                      _buildTimelineRail(
                        isActive: quest.timelinePosition.toLowerCase() == 'future',
                        activeColor: activeColor,
                      ),
                      _buildTimelineNode(
                        label: 'FUTURE',
                        emoji: '⏭️',
                        isActive: quest.timelinePosition.toLowerCase() == 'future',
                        nodeColor: AppColors.violet500,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Sentence Card with Audio Playback
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
                                'OBSERVE THE SENTENCE',
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
                        onPressed: () => _speakSentence(quest.sentence),
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
                    quest.sentence,
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
                          'HOW THE TENSE OPERATES',
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

            // Native Speaker Tip Card
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
                          'TEMPORAL MARKER TIP',
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

  Widget _buildTimelineNode({
    required String label,
    required String emoji,
    required bool isActive,
    required Color nodeColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? nodeColor.withValues(alpha: 0.25)
                  : AppColors.slate800,
              border: Border.all(
                color: isActive ? nodeColor : AppColors.slate700,
                width: isActive ? 2.0 : 1.0,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: nodeColor.withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              emoji,
              style: TextStyle(fontSize: 16.sp),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: TextStyle(
              color: isActive ? nodeColor : AppColors.slate500,
              fontSize: 10.sp,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRail({
    required bool isActive,
    required Color activeColor,
  }) {
    return Container(
      width: 24.w,
      height: 2.h,
      color: isActive ? activeColor : AppColors.slate800,
    );
  }
}
