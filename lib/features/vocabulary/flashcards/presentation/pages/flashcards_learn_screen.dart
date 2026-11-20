import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_learn_card.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_learn_teaching_section.dart';

/// Rich, interactive Learn Phase screen for Flashcards.
///
/// Teaches each target word in depth before the learner enters guided practice.
class FlashcardsLearnScreen extends StatefulWidget {
  final int level;

  const FlashcardsLearnScreen({super.key, required this.level});

  @override
  State<FlashcardsLearnScreen> createState() => _FlashcardsLearnScreenState();
}

class _FlashcardsLearnScreenState extends State<FlashcardsLearnScreen> {
  final ValueNotifier<bool> _isFlippedNotifier = ValueNotifier<bool>(false);
  List<PhasedQuest> _quests = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadLearnQuests();
  }

  @override
  void dispose() {
    _isFlippedNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadLearnQuests() async {
    try {
      final batchIndex = ((widget.level - 1) ~/ 10) + 1;
      final startLevel = (batchIndex - 1) * 10 + 1;
      final endLevel = batchIndex * 10;
      final path =
          'assets/curriculum/vocabulary/flashcards_learn_${startLevel}_$endLevel.json';
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
          _quests = [
            PhasedQuest(
              id: 'FALLBACK_L${widget.level}_1',
              level: widget.level,
              word: 'WELCOME',
              pronunciation: '/ˈwɛlkəm/',
              definition: 'Greeting used to welcome someone kindly.',
              example: 'Welcome to your Vowl learning session!',
              nativeTip: 'Warm and friendly across all contexts.',
              visualAnchor: '🤝 Open hands greeting a friend',
            ),
          ];
          _isLoading = false;
        });
      }
    }
  }

  void _speak(String text) {
    if (di.sl.isRegistered<TtsService>()) {
      di.sl<TtsService>().speak(text);
    }
  }

  void _flipCard() {
    _isFlippedNotifier.value = !_isFlippedNotifier.value;
    if (di.sl.isRegistered<HapticService>()) {
      di.sl<HapticService>().selection();
    }
    final quest = _quests.isNotEmpty ? _quests[_currentIndex] : null;
    if (_isFlippedNotifier.value && quest?.word != null) {
      _speak(quest!.word!);
    }
  }

  void _nextWord() {
    if (di.sl.isRegistered<HapticService>()) {
      di.sl<HapticService>().light();
    }
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
        _isFlippedNotifier.value = false;
      });
    } else {
      _finishLearnPhase();
    }
  }

  void _finishLearnPhase() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'flashcards',
      level: widget.level,
      phase: 'learn',
    );
    final target =
        '/practice?category=vocabulary&gameType=flashcards&level=${widget.level}';
    context.pushReplacement(target);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.slate950 : AppColors.slate50,
        body: const SafeArea(
          child: GameShimmerLoading(primaryColor: AppColors.indigo500),
        ),
      );
    }

    final quest = _quests.isNotEmpty ? _quests[_currentIndex] : null;
    if (quest == null) {
      return LearnPhaseScaffold(
        title: 'Word Discovery',
        gameType: 'flashcards',
        level: widget.level,
        onComplete: _finishLearnPhase,
        child: const Center(child: Text('No learning material available.')),
      );
    }

    final isLast = _currentIndex == _quests.length - 1;

    return LearnPhaseScaffold(
      title: 'Word ${_currentIndex + 1} of ${_quests.length}',
      gameType: 'flashcards',
      level: widget.level,
      actionLabel: isLast ? 'Start Practice ➔' : 'Next Word ➔',
      onComplete: _nextWord,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 3D Flippable Word Card with ValueListenable isolation
            ValueListenableBuilder<bool>(
              valueListenable: _isFlippedNotifier,
              builder: (context, isFlipped, _) {
                return FlashcardLearnCard(
                  quest: quest,
                  isFlipped: isFlipped,
                  isDark: isDark,
                  onFlip: _flipCard,
                  onSpeak: () {
                    if (quest.word != null) _speak(quest.word!);
                  },
                );
              },
            ),

            SizedBox(height: 20.h),

            // Teaching Sections: Anchors, Tips, Nuances, Families, Cards
            FlashcardLearnTeachingSection(
              quest: quest,
              isDark: isDark,
              onSpeak: _speak,
            ),
          ],
        ),
      ),
    );
  }
}
