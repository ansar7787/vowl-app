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

/// Data model representing a relative clauses learning concept card.
class RelativeClausesLearnQuest {
  final String id;
  final int level;
  final String conceptTitle;
  final String instruction;
  final String grammarRule;
  final String clauseType;
  final String questionSentence;
  final String targetClause;
  final String completedSentence;
  final String ruleExplanation;
  final String nativeTip;
  final String legoPreview;

  const RelativeClausesLearnQuest({
    required this.id,
    required this.level,
    required this.conceptTitle,
    required this.instruction,
    required this.grammarRule,
    required this.clauseType,
    required this.questionSentence,
    required this.targetClause,
    required this.completedSentence,
    required this.ruleExplanation,
    required this.nativeTip,
    required this.legoPreview,
  });

  factory RelativeClausesLearnQuest.fromJson(Map<String, dynamic> json) {
    final question = json['questionSentence'] as String? ??
        (json['question'] as String? ?? '');
    final target = json['targetClause'] as String? ??
        (json['correctAnswer'] as String? ?? 'who');
    final completed = json['completedSentence'] as String? ??
        (question.contains('___')
            ? question.replaceAll('___', target)
            : question);
    final rule = json['grammarRule'] as String? ?? 'Relative Clauses';
    final clauseType = json['clauseType'] as String? ?? 'defining';

    return RelativeClausesLearnQuest(
      id: json['id'] as String? ?? 'rc_learn_default',
      level: json['level'] as int? ?? 1,
      conceptTitle: json['conceptTitle'] as String? ??
          'Information Snap-In: $rule',
      instruction: json['instruction'] as String? ?? 'INFORMATION SNAP-IN ENGINE',
      grammarRule: rule,
      clauseType: clauseType,
      questionSentence: question,
      targetClause: target,
      completedSentence: completed,
      ruleExplanation: json['ruleExplanation'] as String? ??
          (json['explanation'] as String? ??
              'Relative clauses snap into sentences to give essential (defining) or extra (non-defining) information.'),
      nativeTip: json['nativeTip'] as String? ??
          (json['hint'] as String? ??
              'Look closely at who or what the clause describes to select the right relative link.'),
      legoPreview: json['legoPreview'] as String? ??
          '🧩 Snap Slot: [$clauseType] ➔ "$target"',
    );
  }
}

/// Rich, interactive Learn Phase screen for Relative Clauses: "Information Snap-In Engine".
///
/// Features Lego syntax snap-in previews, defining vs non-defining clause analysis,
/// audio articulation, rule breakdown, and native cadence tips.
class RelativeClausesLearnScreen extends StatefulWidget {
  final int level;

  const RelativeClausesLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<RelativeClausesLearnScreen> createState() =>
      _RelativeClausesLearnScreenState();
}

class _RelativeClausesLearnScreenState
    extends State<RelativeClausesLearnScreen> {
  List<RelativeClausesLearnQuest> _quests = const [
    RelativeClausesLearnQuest(
      id: 'FALLBACK_RC_L1',
      level: 1,
      conceptTitle: 'Information Snap-In: Subject Relative Clauses',
      instruction: 'INFORMATION SNAP-IN ENGINE',
      grammarRule: 'Subject Relative Clause with who',
      clauseType: 'defining',
      questionSentence:
          'The man who is standing by the door is my uncle.',
      targetClause: 'who is standing by the door',
      completedSentence:
          'The man who is standing by the door is my uncle.',
      ruleExplanation:
          "'Who is standing by the door' comes right after 'the man' and adds extra information about him.",
      nativeTip:
          "Try covering up the words that begin right after 'the man' - what extra detail do they add about him?",
      legoPreview: '🧩 Snap Slot: [defining] ➔ "who is standing by the door"',
    ),
  ];

  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurriculum();
  }

  Future<void> _loadCurriculum() async {
    try {
      final batchIndex = ((widget.level - 1) ~/ 10) + 1;
      final startLevel = (batchIndex - 1) * 10 + 1;
      final endLevel = batchIndex * 10;
      final path =
          'assets/curriculum/grammar/relativeClauses_learn_${startLevel}_$endLevel.json';

      final content = await rootBundle.loadString(path);
      final data = jsonDecode(content) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final levelQuests = rawQuests
          .where((q) => (q['level'] as int? ?? 1) == widget.level)
          .map((q) => RelativeClausesLearnQuest.fromJson(q))
          .toList();

      if (mounted) {
        setState(() {
          if (levelQuests.isNotEmpty) {
            _quests = levelQuests;
          } else if (rawQuests.isNotEmpty) {
            _quests = rawQuests
                .map((q) => RelativeClausesLearnQuest.fromJson(q))
                .take(3)
                .toList();
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

  void _playTts(String text) {
    if (di.sl.isRegistered<TtsService>()) {
      di.sl<TtsService>().speak(text);
    }
  }

  void _onComplete() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'relativeClauses',
      level: widget.level,
      phase: 'learn',
    );

    final targetPractice =
        '/practice?category=grammar&gameType=relativeClauses&level=${widget.level}';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LearnPhaseScaffold(
      title: 'Information Snap-In',
      gameType: 'relativeClauses',
      level: widget.level,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'NEXT SNAP CARD'
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
                    'Rule ${_currentIndex + 1} of ${_quests.length}',
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
                      quest.grammarRule,
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

            // Top Badge: Clause Type Indicator
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.violet500.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppColors.violet500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.extension_rounded,
                      color: AppColors.violet500,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quest.conceptTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Clause Type: ${quest.clauseType.toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.teal500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Hero Card: Lego Snap-In Slot Demonstration
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1E38), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: AppColors.violet500.withValues(alpha: 0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.violet500.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Snap Slot Header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.violet500.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'LEGO SYNTAX SLOT',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.teal500,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _playTts(quest.completedSentence),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.teal500,
                          size: 24.sp,
                        ),
                        tooltip: 'Listen to sentence',
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Lego Snap Preview Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1424),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Colors.amberAccent.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Colors.amberAccent,
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            quest.legoPreview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.amberAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Target Clause Snap Pill
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.violet500.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.violet500,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.link_rounded,
                            color: AppColors.teal500,
                            size: 18.sp,
                          ),
                          SizedBox(width: 8.w),
                          Flexible(
                            child: Text(
                              quest.targetClause,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Assembled Sentence Display
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      quest.completedSentence,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Syntactic Principle Box
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        color: Colors.blueAccent,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'SYNTACTIC PRINCIPLE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
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
                      fontSize: 13.sp,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Native Cadence Tip Box
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates_rounded,
                        color: Colors.amber,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'NATIVE SPEAKER CADENCE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    quest.nativeTip,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
