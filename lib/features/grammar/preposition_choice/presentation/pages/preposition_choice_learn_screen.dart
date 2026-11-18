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

/// Data model representing a preposition choice learning concept card.
class PrepositionChoiceLearnQuest {
  final String id;
  final int level;
  final String conceptTitle;
  final String preposition;
  final String spatialHierarchy;
  final String question;
  final String targetSentence;
  final String grammarRule;
  final String prepositionCategory;
  final String ruleExplanation;
  final String nativeTip;
  final String visualAnchor;

  const PrepositionChoiceLearnQuest({
    required this.id,
    required this.level,
    required this.conceptTitle,
    required this.preposition,
    required this.spatialHierarchy,
    required this.question,
    required this.targetSentence,
    required this.grammarRule,
    required this.prepositionCategory,
    required this.ruleExplanation,
    required this.nativeTip,
    required this.visualAnchor,
  });

  factory PrepositionChoiceLearnQuest.fromJson(Map<String, dynamic> json) {
    final prep = json['preposition'] as String? ??
        (json['correctAnswer'] as String? ?? 'in');
    final q = json['question'] as String? ??
        (json['sentence'] as String? ?? 'It is ___ the desk.');
    final target = json['targetSentence'] as String? ??
        q.replaceAll('___', prep);

    return PrepositionChoiceLearnQuest(
      id: json['id'] as String? ?? 'pc_learn_default',
      level: json['level'] as int? ?? 1,
      conceptTitle: json['conceptTitle'] as String? ??
          'Preposition Radar: ${json['grammarRule'] ?? 'Prepositions'}',
      preposition: prep,
      spatialHierarchy: json['spatialHierarchy'] as String? ??
          'Spatial & Direction Relationship',
      question: q,
      targetSentence: target,
      grammarRule: json['grammarRule'] as String? ?? 'Prepositions',
      prepositionCategory: json['prepositionCategory'] as String? ?? 'Place',
      ruleExplanation: json['ruleExplanation'] as String? ??
          (json['explanation'] as String? ??
              'Prepositions show spatial, temporal, or logical relations.'),
      nativeTip: json['nativeTip'] as String? ??
          (json['hint'] as String? ??
              'Notice if this is a precise point, surface contact, or enclosed volume.'),
      visualAnchor: json['visualAnchor'] as String? ??
          '🧭 Preposition "$prep" ➔ "$target"',
    );
  }
}

/// Rich, interactive Learn Phase screen for Preposition Choice: "Spatial & Temporal Radar".
///
/// Features spatial hierarchy box, preposition focus spotlight, auditory demonstration,
/// and native orientation tips.
class PrepositionChoiceLearnScreen extends StatefulWidget {
  final int level;

  const PrepositionChoiceLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<PrepositionChoiceLearnScreen> createState() =>
      _PrepositionChoiceLearnScreenState();
}

class _PrepositionChoiceLearnScreenState
    extends State<PrepositionChoiceLearnScreen> {
  List<PrepositionChoiceLearnQuest> _quests = const [
    PrepositionChoiceLearnQuest(
      id: 'FALLBACK_PC_L1',
      level: 1,
      conceptTitle: 'Preposition Radar: Prepositions of Place',
      preposition: 'in',
      spatialHierarchy: 'Enclosed Space / Volume (e.g. in the room)',
      question: 'My notebook is ___ my backpack, along with my pens.',
      targetSentence: 'My notebook is in my backpack, along with my pens.',
      grammarRule: 'Prepositions of Place',
      prepositionCategory: 'Place',
      ruleExplanation:
          "'In' is used when something is enclosed inside a space, like a backpack, a box, or a drawer.",
      nativeTip:
          'Something fully enclosed inside a container calls for this word.',
      visualAnchor:
          "🧭 Preposition 'in' (Enclosed Space / Volume) ➔ 'My notebook is in my backpack, along with my pens.'",
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
          'assets/curriculum/grammar/prepositionChoice_learn_${startLevel}_$endLevel.json';

      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests = data['quests'] as List<dynamic>? ?? [];

      final loaded = rawQuests
          .map((q) => PrepositionChoiceLearnQuest.fromJson(
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
      gameType: 'prepositionChoice',
      level: widget.level,
      phase: 'learn',
    );

    final targetPractice =
        '/practice?category=grammar&gameType=prepositionChoice&level=${widget.level}';
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

    return LearnPhaseScaffold(
      title: 'Preposition Radar',
      gameType: 'prepositionChoice',
      level: widget.level,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'NEXT PREPOSITION CARD'
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
                      quest.prepositionCategory,
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
                      Text('🧭', style: TextStyle(fontSize: 22.sp)),
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

            // Preposition Spotlight & Spatial Hierarchy
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
                        Icons.layers_rounded,
                        color: AppColors.teal500,
                        size: 20.r,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'SPATIAL & TEMPORAL HIERARCHY',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.teal500,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.teal500.withValues(alpha: 0.25),
                            AppColors.teal500.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: AppColors.teal500,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            quest.preposition.toUpperCase(),
                            style: TextStyle(
                              color: AppColors.teal500,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            quest.spatialHierarchy,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.slate300,
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Articulated Sentence Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.emerald400.withValues(alpha: 0.5),
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
                              Icons.check_circle_rounded,
                              color: AppColors.emerald400,
                              size: 18.r,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'NATURAL SENTENCE',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.emerald400,
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
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.emerald400,
                          size: 20.r,
                        ),
                        onPressed: () => _speakSentence(quest.targetSentence),
                        tooltip: 'Listen to sentence',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    quest.targetSentence,
                    style: TextStyle(
                      color: AppColors.slate100,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Visual Anchor Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.teal500.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🧭', style: TextStyle(fontSize: 20.sp)),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PREPOSITION ANCHOR',
                          style: TextStyle(
                            color: AppColors.teal500,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          quest.visualAnchor,
                          style: TextStyle(
                            color: AppColors.slate200,
                            fontSize: 12.5.sp,
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
            SizedBox(height: 12.h),

            // Rule explanation card
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
                        Icons.menu_book_rounded,
                        color: AppColors.teal500,
                        size: 18.r,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'GRAMMAR PRINCIPLE',
                        style: TextStyle(
                          color: AppColors.teal500,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    quest.ruleExplanation,
                    style: TextStyle(
                      color: AppColors.slate300,
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Native tip card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.amber400.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.amber400.withValues(alpha: 0.25),
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
                          'NATIVE SPEAKER INTUITION',
                          style: TextStyle(
                            color: AppColors.amber400,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          quest.nativeTip,
                          style: TextStyle(
                            color: AppColors.slate200,
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
