import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/word_formation/data/services/word_formation_curriculum_service.dart';
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
    if (di.sl.isRegistered<TtsService>()) {
      unawaited(di.sl<TtsService>().preWarm(locale: 'en-US'));
    }
  }

  Future<void> _loadQuests() async {
    final quests =
        await WordFormationCurriculumService().getLearnQuests(widget.level);
    if (mounted) {
      setState(() {
        _quests = quests;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    TtsSpeakerButtonWidget.stopAll();
    super.dispose();
  }

  void _onContinue() {
    TtsSpeakerButtonWidget.stopAll();
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
        title: 'Word Families',
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
          : 'Start Practice',
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
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
