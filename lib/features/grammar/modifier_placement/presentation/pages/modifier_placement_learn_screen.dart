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

/// Data model representing a modifier placement learning concept card.
class ModifierPlacementLearnQuest {
  final String id;
  final int level;
  final String conceptTitle;
  final String modifier;
  final String targetSentence;
  final String awkwardSentence;
  final String grammarRule;
  final String modifierType;
  final String ruleExplanation;
  final String nativeTip;
  final String visualAnchor;
  final String comedyNote;

  const ModifierPlacementLearnQuest({
    required this.id,
    required this.level,
    required this.conceptTitle,
    required this.modifier,
    required this.targetSentence,
    required this.awkwardSentence,
    required this.grammarRule,
    required this.modifierType,
    required this.ruleExplanation,
    required this.nativeTip,
    required this.visualAnchor,
    required this.comedyNote,
  });

  factory ModifierPlacementLearnQuest.fromJson(Map<String, dynamic> json) {
    final mod = json['modifier'] as String? ?? 'modifier';
    final target = json['targetSentence'] as String? ??
        (json['correctAnswer'] as String? ?? '');
    final awkward = json['awkwardSentence'] as String? ??
        'Misplaced modifier: $mod $target';

    return ModifierPlacementLearnQuest(
      id: json['id'] as String? ?? 'mp_learn_default',
      level: json['level'] as int? ?? 1,
      conceptTitle: json['conceptTitle'] as String? ??
          'Modifier Anchor: ${json['grammarRule'] ?? 'Placement'}',
      modifier: mod,
      targetSentence: target,
      awkwardSentence: awkward,
      grammarRule: json['grammarRule'] as String? ?? 'Modifier Placement',
      modifierType: json['modifierType'] as String? ?? 'Modifier',
      ruleExplanation: json['ruleExplanation'] as String? ??
          (json['explanation'] as String? ??
              'Modifiers must sit as close as possible to the words they describe.'),
      nativeTip: json['nativeTip'] as String? ??
          (json['hint'] as String? ??
              'Ask: What exactly is being described? Place the modifier right beside it.'),
      visualAnchor: json['visualAnchor'] as String? ??
          '🎯 Place "$mod" next to its target: "$target"',
      comedyNote: json['comedyNote'] as String? ??
          'Misplacing "$mod" produces awkward phrasing. Keep it anchored to its target word.',
    );
  }
}

/// Rich, interactive Learn Phase screen for Modifier Placement: "Modifier Anchor Engine".
///
/// Features target modifier isolation, natural attachment vs comical misplacement contrast,
/// auditory demonstration, and native speaker alignment tips.
class ModifierPlacementLearnScreen extends StatefulWidget {
  final int level;

  const ModifierPlacementLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<ModifierPlacementLearnScreen> createState() =>
      _ModifierPlacementLearnScreenState();
}

class _ModifierPlacementLearnScreenState
    extends State<ModifierPlacementLearnScreen> {
  List<ModifierPlacementLearnQuest> _quests = const [
    ModifierPlacementLearnQuest(
      id: 'FALLBACK_MP_L1',
      level: 1,
      conceptTitle: 'Modifier Placement: Adjective Placement (Attributive)',
      modifier: 'red',
      targetSentence: 'She picked a red apple from the basket.',
      awkwardSentence: 'Red she picked an apple from the basket.',
      grammarRule: 'Adjective Placement (Attributive)',
      modifierType: 'Adjective',
      ruleExplanation:
          "'Red' describes the apple's color. In English, an adjective sits right before the noun it belongs to: 'red apple'.",
      nativeTip:
          "Find the noun 'red' describes, then place it directly in front of that noun.",
      visualAnchor:
          "🎯 Place 'red' right next to the word it describes: 'She picked a red apple from the basket.'",
      comedyNote:
          "Misplacing 'red' produces awkward phrasing like: 'Red she picked an apple from the basket.' Always anchor modifiers adjacent to the words they modify.",
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
          'assets/curriculum/grammar/modifierPlacement_learn_${startLevel}_$endLevel.json';

      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests = data['quests'] as List<dynamic>? ?? [];

      final loaded = rawQuests
          .map((q) => ModifierPlacementLearnQuest.fromJson(
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
      gameType: 'modifierPlacement',
      level: widget.level,
      phase: 'learn',
    );

    final targetPractice =
        '/practice?category=grammar&gameType=modifierPlacement&level=${widget.level}';
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
      title: 'Modifier Anchor Engine',
      gameType: 'modifierPlacement',
      level: widget.level,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'NEXT MODIFIER CARD'
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
                      quest.modifierType,
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
                      Text('🎯', style: TextStyle(fontSize: 22.sp)),
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

            // Target Modifier Spotlight
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
                        Icons.anchor_rounded,
                        color: AppColors.teal500,
                        size: 20.r,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'MODIFIER SPOTLIGHT',
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
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.teal500.withValues(alpha: 0.25),
                              AppColors.teal500.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: AppColors.teal500,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          quest.modifier,
                          style: TextStyle(
                            color: AppColors.teal500,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Correct Natural Attachment Card
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
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.emerald400,
                            size: 18.r,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'NATURAL ATTACHMENT',
                            style: TextStyle(
                              color: AppColors.emerald400,
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
            SizedBox(height: 12.h),

            // Misplaced Modifier Contrast Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.rose500.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.rose500,
                        size: 18.r,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'MISPLACED MODIFIER (AWKWARD)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.rose500,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    quest.awkwardSentence,
                    style: TextStyle(
                      color: AppColors.slate300,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    quest.comedyNote,
                    style: TextStyle(
                      color: AppColors.rose500.withValues(alpha: 0.9),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
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
                          'VISUAL ANCHOR',
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
