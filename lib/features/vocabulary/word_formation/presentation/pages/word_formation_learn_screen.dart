import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/word_formation_learn_compass.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/word_formation_morph_core.dart';

/// Learn Phase screen for Word Formation: The 4-Way Morph Sandbox.
class WordFormationLearnScreen extends StatefulWidget {
  final int level;

  const WordFormationLearnScreen({super.key, required this.level});

  @override
  State<WordFormationLearnScreen> createState() =>
      _WordFormationLearnScreenState();
}

class _WordFormationLearnScreenState extends State<WordFormationLearnScreen> {
  List<PhasedQuest> _quests = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  Future<void> _loadQuests() async {
    try {
      final batchIndex = ((widget.level - 1) ~/ 10) + 1;
      final startLevel = (batchIndex - 1) * 10 + 1;
      final endLevel = batchIndex * 10;
      final path =
          'assets/curriculum/vocabulary/wordFormation_learn_${startLevel}_$endLevel.json';
      final jsonStr = await rootBundle.loadString(path);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final batch = PhasedQuestBatch.fromJson(data);

      final levelQuests = batch.quests
          .where((q) => q.level == widget.level)
          .toList();

      if (mounted) {
        setState(() {
          _quests = levelQuests.isNotEmpty ? levelQuests : batch.quests;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _quests = _buildFallbackQuests();
          _isLoading = false;
        });
      }
    }
  }

  List<PhasedQuest> _buildFallbackQuests() {
    return [
      PhasedQuest(
        id: 'FALLBACK_WF_L1_Q1',
        level: widget.level,
        word: 'DECIDE',
        definition: 'To make a choice after thinking carefully.',
        rawExtra: {
          'rootWord': 'DECIDE',
          'rootMeaning': 'To make a choice after thinking carefully.',
          'northNoun': {
            'word': 'DECISION',
            'role': 'Noun',
            'rule': 'Drop -de, add -sion',
            'example': 'Making a tough career decision takes courage.',
          },
          'eastAdjective': {
            'word': 'DECISIVE',
            'role': 'Adjective',
            'rule': 'Drop -e, add -isive',
            'example': 'A decisive manager resolves issues quickly.',
          },
          'southAdverb': {
            'word': 'DECISIVELY',
            'role': 'Adverb',
            'rule': 'Add -ly to adjective',
            'example': 'She acted decisively during the crisis.',
          },
          'westOpposite': {
            'word': 'INDECISIVE',
            'role': 'Opposite',
            'rule': 'Prefix in- + decisive',
            'example': 'An indecisive customer hesitated for hours.',
          },
        },
      ),
      PhasedQuest(
        id: 'FALLBACK_WF_L1_Q2',
        level: widget.level,
        word: 'CREATE',
        definition: 'To bring something new into existence.',
        rawExtra: {
          'rootWord': 'CREATE',
          'rootMeaning': 'To bring something new into existence.',
          'northNoun': {
            'word': 'CREATION',
            'role': 'Noun',
            'rule': 'Drop -e, add -ion',
            'example': 'The artistic creation took three years.',
          },
          'eastAdjective': {
            'word': 'CREATIVE',
            'role': 'Adjective',
            'rule': 'Drop -e, add -ive',
            'example': 'A creative solution to a hard problem.',
          },
          'southAdverb': {
            'word': 'CREATIVELY',
            'role': 'Adverb',
            'rule': 'Add -ly to adjective',
            'example': 'They thought creatively to save costs.',
          },
          'westOpposite': {
            'word': 'UNCREATIVE',
            'role': 'Opposite',
            'rule': 'Prefix un- + creative',
            'example': 'Copying others is uncreative work.',
          },
        },
      ),
    ];
  }

  void _onContinue() {
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'wordFormation',
        level: widget.level,
        phase: 'learn',
      );
      context.pushReplacement(
        '/practice?category=vocabulary&gameType=wordFormation&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);
    final primaryColor = theme.primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return LearnPhaseScaffold(
        title: 'Word Formation Sandbox',
        gameType: 'wordFormation',
        level: widget.level,
        onComplete: _onContinue,
        child: GameShimmerLoading(primaryColor: primaryColor),
      );
    }

    final quest = _quests[_currentIndex];
    final extra = quest.rawExtra;
    final rootWord = (extra['rootWord'] as String?) ?? quest.word ?? 'ROOT';
    final rootMeaning =
        (extra['rootMeaning'] as String?) ?? quest.definition ?? '';

    final north = extra['northNoun'] is Map
        ? Map<String, dynamic>.from(extra['northNoun'] as Map)
        : <String, dynamic>{'word': '${rootWord}_NOUN', 'role': 'Noun'};
    final east = extra['eastAdjective'] is Map
        ? Map<String, dynamic>.from(extra['eastAdjective'] as Map)
        : <String, dynamic>{'word': '${rootWord}_ADJ', 'role': 'Adjective'};
    final south = extra['southAdverb'] is Map
        ? Map<String, dynamic>.from(extra['southAdverb'] as Map)
        : <String, dynamic>{'word': '${rootWord}_ADV', 'role': 'Adverb'};
    final west = extra['westOpposite'] is Map
        ? Map<String, dynamic>.from(extra['westOpposite'] as Map)
        : <String, dynamic>{'word': '${rootWord}_OPP', 'role': 'Opposite'};

    return LearnPhaseScaffold(
      title: 'Word Formation: $rootWord',
      gameType: 'wordFormation',
      level: widget.level,
      onComplete: _onContinue,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'Next Word'
          : 'Start Practice 🚀',
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: 12.h),
                    WordFormationMorphCore(
                      rootWord: rootWord,
                      rootMeaning: rootMeaning,
                      primaryColor: primaryColor,
                      isDark: isDark,
                    ),
                    SizedBox(height: 16.h),
                    WordFormationLearnCompass(
                      northNoun: north,
                      eastAdjective: east,
                      southAdverb: south,
                      westOpposite: west,
                      primaryColor: primaryColor,
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: 16.h, top: 8.h),
                child: ScaleButton(
                  onTap: _onContinue,
                  child: Container(
                    width: double.infinity,
                    height: 52.h,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentIndex < _quests.length - 1
                              ? 'Next Word'
                              : 'Start Practice',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18.r,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
