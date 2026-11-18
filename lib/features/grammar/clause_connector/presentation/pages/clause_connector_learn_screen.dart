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

/// Data model representing a clause connector learning concept card.
class ClauseConnectorLearnQuest {
  final String id;
  final int level;
  final String conceptTitle;
  final String connectorCategory;
  final String correctConnector;
  final String sentenceWithBlank;
  final String completedSentence;
  final List<String> options;
  final String grammarRule;
  final String ruleExplanation;
  final String nativeTip;
  final String visualAnchor;

  const ClauseConnectorLearnQuest({
    required this.id,
    required this.level,
    required this.conceptTitle,
    required this.connectorCategory,
    required this.correctConnector,
    required this.sentenceWithBlank,
    required this.completedSentence,
    required this.options,
    required this.grammarRule,
    required this.ruleExplanation,
    required this.nativeTip,
    required this.visualAnchor,
  });

  factory ClauseConnectorLearnQuest.fromJson(Map<String, dynamic> json) {
    final correctConn = json['correctConnector'] as String? ??
        (json['correctAnswer'] as String? ?? 'and');
    final sentenceWithBlank = json['sentenceWithBlank'] as String? ??
        (json['sentence'] as String? ?? (json['question'] as String? ?? ''));
    final completed = json['completedSentence'] as String? ??
        sentenceWithBlank.replaceFirst('____', correctConn).replaceFirst('___', correctConn);

    return ClauseConnectorLearnQuest(
      id: json['id'] as String? ?? 'cc_learn_default',
      level: json['level'] as int? ?? 1,
      conceptTitle: json['conceptTitle'] as String? ??
          'Clause Bridge: ${json['connectorCategory'] ?? 'Connector'} ($correctConn)',
      connectorCategory: json['connectorCategory'] as String? ?? 'Logical Bridge',
      correctConnector: correctConn,
      sentenceWithBlank: sentenceWithBlank,
      completedSentence: completed,
      options: (json['options'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      grammarRule: json['grammarRule'] as String? ?? 'Clause Connection',
      ruleExplanation: json['ruleExplanation'] as String? ??
          (json['explanation'] as String? ??
              'Select the connector that accurately captures the relationship between both clauses.'),
      nativeTip: json['nativeTip'] as String? ??
          (json['hint'] as String? ??
              'Identify whether the two thoughts express addition, contrast, reason, or condition.'),
      visualAnchor: json['visualAnchor'] as String? ??
          '🌉 Clause A ──[ $correctConn ]── Clause B',
    );
  }
}

/// Rich, interactive Learn Phase screen for Clause Connector: "Clause Bridge Engine".
///
/// Features clause breakdown, logical connector node visualization,
/// natural flow audio articulation, and native speaker transition intuition.
class ClauseConnectorLearnScreen extends StatefulWidget {
  final int level;

  const ClauseConnectorLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<ClauseConnectorLearnScreen> createState() =>
      _ClauseConnectorLearnScreenState();
}

class _ClauseConnectorLearnScreenState
    extends State<ClauseConnectorLearnScreen> {
  List<ClauseConnectorLearnQuest> _quests = const [
    ClauseConnectorLearnQuest(
      id: 'FALLBACK_CC_L1',
      level: 1,
      conceptTitle: 'Clause Bridge: Addition (and)',
      connectorCategory: 'Addition',
      correctConnector: 'and',
      sentenceWithBlank:
          'Maria packed her backpack ____ she put on her hiking boots.',
      completedSentence:
          'Maria packed her backpack and she put on her hiking boots.',
      options: ['so', 'and', 'but', 'or'],
      grammarRule: 'Addition - and',
      ruleExplanation:
          "'And' links two ordinary steps in getting ready. Putting on her boots isn't a result of packing the backpack, so 'so' doesn't fit here, and there's no contrast for 'but' or choice for 'or' - both actions just happen together.",
      nativeTip:
          'Think about whether the second action simply follows the first as another step, without any surprise or cause-and-effect.',
      visualAnchor: '🌉 Clause A ──[ and ]── Clause B',
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
          'assets/curriculum/grammar/clauseConnector_learn_${startLevel}_$endLevel.json';

      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests = data['quests'] as List<dynamic>? ?? [];

      final loaded = rawQuests
          .map((q) => ClauseConnectorLearnQuest.fromJson(
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
      gameType: 'clauseConnector',
      level: widget.level,
      phase: 'learn',
    );

    final targetPractice =
        '/practice?category=grammar&gameType=clauseConnector&level=${widget.level}';
    context.pushReplacement(targetPractice);
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'contrast':
        return AppColors.rose500;
      case 'result':
      case 'cause/effect':
        return AppColors.amber400;
      case 'time':
      case 'condition':
        return AppColors.violet500;
      case 'addition':
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
    final categoryColor = _getCategoryColor(quest.connectorCategory);

    return LearnPhaseScaffold(
      title: 'Clause Bridge Engine',
      gameType: 'clauseConnector',
      level: widget.level,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'NEXT CLAUSE BRIDGE'
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
                    'Bridge ${_currentIndex + 1} of ${_quests.length}',
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
                      color: categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: categoryColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      quest.connectorCategory.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: categoryColor,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
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
                    categoryColor.withValues(alpha: 0.12),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: categoryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('🌉', style: TextStyle(fontSize: 22.sp)),
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
                      color: categoryColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Clause Bridge Interactive Board
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
                        Icons.linear_scale_rounded,
                        color: categoryColor,
                        size: 20.r,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'SYNTACTIC BRIDGE ARCHITECTURE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: categoryColor,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Connector Highlight Badge
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: categoryColor,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: categoryColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🔗', style: TextStyle(fontSize: 16.sp)),
                          SizedBox(width: 8.w),
                          Text(
                            quest.correctConnector.toUpperCase(),
                            style: TextStyle(
                              color: AppColors.slate100,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Connected Sentence Display Card
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: AppColors.slate950,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: categoryColor.withValues(alpha: 0.35),
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
                                'UNIFIED COMPLEX SENTENCE',
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
                                  _speakSentence(quest.completedSentence),
                              icon: Icon(
                                Icons.volume_up_rounded,
                                color: categoryColor,
                                size: 20.r,
                              ),
                              tooltip: 'Listen to connected sentence',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          quest.completedSentence,
                          style: TextStyle(
                            color: AppColors.slate100,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
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

            // Rule Breakdown Card
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
                        color: categoryColor,
                        size: 18.r,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'HOW THE BRIDGE LINKS CLAUSES',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: categoryColor,
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
