import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_scrollbar.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/topic_vocab/domain/entities/topic_practice_quest.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_category_tray.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_fusion_tile.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_practice_celebration_card.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_word_peek_sheet.dart';

/// Guided active recall screen for Topic Vocab ("Practice: Word Groups").
/// Features interactive category trays where learners categorize vocabulary
/// items with real-time semantic anchoring, TTS audio, and coaching tips.
class TopicVocabPracticeScreen extends StatefulWidget {
  final int level;

  const TopicVocabPracticeScreen({super.key, required this.level});

  @override
  State<TopicVocabPracticeScreen> createState() =>
      _TopicVocabPracticeScreenState();
}

class _TopicVocabPracticeScreenState extends State<TopicVocabPracticeScreen> {
  int _currentIndex = 0;
  List<TopicPracticeQuest> _quests = [];
  bool _isLoading = true;

  int _activeCategoryIndex = 0;
  final Map<int, List<String>> _placedWords = {};
  List<String> _poolWords = [];
  String? _coachingMessage;

  late final HapticService _hapticService = di.sl.isRegistered<HapticService>()
      ? di.sl<HapticService>()
      : HapticService();

  @override
  void initState() {
    super.initState();
    if (di.sl.isRegistered<TtsService>()) {
      unawaited(di.sl<TtsService>().preWarm());
    }
    _loadCurriculum();
  }

  int get _batchStart => ((widget.level - 1) ~/ 10) * 10 + 1;
  int get _batchEnd => _batchStart + 9;

  Future<void> _loadCurriculum() async {
    final batchPath =
        'assets/curriculum/vocabulary/topicVocab_practice_${_batchStart}_$_batchEnd.json';
    try {
      final jsonString = await rootBundle.loadString(batchPath);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>).cast<Map<String, dynamic>>();

      final filtered = rawQuests
          .where((q) => (q['level'] as int? ?? widget.level) == widget.level)
          .map((q) => TopicPracticeQuest.fromJson(q))
          .toList();

      final loaded = filtered.isNotEmpty
          ? filtered
          : [TopicPracticeQuest.fallback(widget.level)];
      _setLoadedQuests(loaded);
    } catch (_) {
      _setLoadedQuests([TopicPracticeQuest.fallback(widget.level)]);
    }
  }

  void _setLoadedQuests(List<TopicPracticeQuest> loaded) {
    if (mounted) {
      setState(() {
        _quests = loaded;
        _isLoading = false;
        _initBoardForCurrentQuest();
      });
    }
  }

  void _initBoardForCurrentQuest() {
    if (_quests.isEmpty) return;
    final quest = _quests[_currentIndex];
    if (quest.boards.isEmpty) return;

    final board = quest.boards.first;
    _placedWords.clear();
    for (int i = 0; i < board.clusters.length; i++) {
      _placedWords[i] = [];
    }
    _poolWords = List<String>.from(board.tiles);
    _activeCategoryIndex = 0;
    _coachingMessage = null;
  }

  bool get _isBoardComplete {
    if (_quests.isEmpty) return false;
    final quest = _quests[_currentIndex];
    if (quest.boards.isEmpty) return false;
    final board = quest.boards.first;
    for (int i = 0; i < board.clusters.length; i++) {
      if ((_placedWords[i]?.length ?? 0) < board.targetClusterSize) {
        return false;
      }
    }
    return true;
  }

  void _speak(String word) {
    if (di.sl.isRegistered<TtsService>()) {
      try {
        final tts = di.sl<TtsService>();
        tts.stop();
        tts.speak(word);
      } catch (_) {}
    }
  }

  void _handleWordTap(String word) {
    if (_quests.isEmpty) return;
    final quest = _quests[_currentIndex];
    if (quest.boards.isEmpty) return;
    final board = quest.boards.first;
    if (_activeCategoryIndex >= board.clusters.length) return;

    _speak(word);

    final activeCluster = board.clusters[_activeCategoryIndex];
    if (activeCluster.words.contains(word)) {
      _hapticService.light();
      setState(() {
        _coachingMessage = null;
        _poolWords.remove(word);
        _placedWords[_activeCategoryIndex]?.add(word);

        if ((_placedWords[_activeCategoryIndex]?.length ?? 0) >=
            board.targetClusterSize) {
          _hapticService.success();
          if (di.sl.isRegistered<SoundService>()) {
            try { di.sl<SoundService>().playCorrect(comboStep: _isBoardComplete ? 3 : 1); } catch (_) {}
          }
          for (int i = 0; i < board.clusters.length; i++) {
            if ((_placedWords[i]?.length ?? 0) < board.targetClusterSize) {
              _activeCategoryIndex = i;
              break;
            }
          }
        }
      });
    } else {
      _hapticService.error();
      if (di.sl.isRegistered<SoundService>()) {
        try { di.sl<SoundService>().playSoftWrong(); } catch (_) {}
      }
      final matching = board.clusters.firstWhere(
        (c) => c.words.contains(word),
        orElse: () => activeCluster,
      );
      setState(() {
        _coachingMessage =
            "'$word' belongs to ${matching.categoryName}. Select that tray to place it.";
      });
    }
  }

  void _handleRemoveWord(int categoryIndex, String word) {
    _hapticService.light();
    setState(() {
      _coachingMessage = null;
      _placedWords[categoryIndex]?.remove(word);
      if (!_poolWords.contains(word)) {
        _poolWords.add(word);
      }
      _activeCategoryIndex = categoryIndex;
    });
  }

  void _handleTileLongPress(String word) {
    if (_quests.isEmpty) return;
    final quest = _quests[_currentIndex];
    if (quest.boards.isEmpty) return;
    final board = quest.boards.first;

    String? matchedCategory;
    String? matchedExplanation;
    for (final c in board.clusters) {
      if (c.words.contains(word)) {
        matchedCategory = c.categoryName;
        matchedExplanation = c.explanation;
        break;
      }
    }

    final theme = LevelThemeHelper.getTheme('topicVocab', level: widget.level);
    TopicWordPeekSheet.show(
      context,
      word: word,
      definition: matchedExplanation ?? 'Vocabulary item in this lesson.',
      categoryHint: matchedCategory,
      accentColor: theme.primaryColor,
    );
  }

  void _handleHint() {
    if (_quests.isEmpty) return;
    final quest = _quests[_currentIndex];
    if (quest.boards.isEmpty) return;
    final board = quest.boards.first;

    final clueKey = 'cat${String.fromCharCode(65 + _activeCategoryIndex)}Clue';
    final clueText = board.clues[clueKey] ??
        (board.clues.isNotEmpty
            ? board.clues.values.first
            : 'Look for words sharing a situation or condition.');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(clueText),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _handleNext() {
    _hapticService.light();
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
        _initBoardForCurrentQuest();
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'topicVocab',
        level: widget.level,
        phase: 'practice',
      );
      if (mounted) {
        try {
          context.pushReplacement(
            '/game?category=vocabulary&gameType=topicVocab&level=${widget.level}',
          );
        } catch (_) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('topicVocab', level: widget.level);
    final accentColor = theme.primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading || _quests.isEmpty) {
      return PracticePhaseScaffold(
        title: 'Practice: Word Groups',
        gameType: 'topicVocab',
        level: widget.level,
        currentExerciseIndex: 0,
        totalExercises: 1,
        isActionEnabled: false,
        onComplete: () {},
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            children: [
              ShimmerLoading.rounded(height: 110.h, width: double.infinity, borderRadius: 16),
              SizedBox(height: 14.h),
              ShimmerLoading.rounded(height: 110.h, width: double.infinity, borderRadius: 16),
            ],
          ),
        ),
      );
    }

    final quest = _quests[_currentIndex];
    final board = quest.boards.first;
    final isDone = _isBoardComplete;
    final isLast = _currentIndex == _quests.length - 1;

    return PracticePhaseScaffold(
      title: 'Practice: Word Groups',
      gameType: 'topicVocab',
      level: widget.level,
      currentExerciseIndex: _currentIndex,
      totalExercises: _quests.length,
      isActionEnabled: isDone,
      actionLabel: isLast ? 'Start Mastery Challenge' : 'Next Word Group',
      onComplete: _handleNext,
      onHint: _handleHint,
      isHintAvailable: !isDone,
      child: GameScrollbar(
        thumbColor: accentColor.withValues(alpha: 0.55),
        thickness: 3.5.w,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Text(
                  'Tap a category tray, then tap matching words to place them.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ),
              ...List.generate(board.clusters.length, (idx) {
                final cluster = board.clusters[idx];
                final placed = _placedWords[idx] ?? [];
                final isTrayComplete = placed.length >= board.targetClusterSize;
                final isTrayActive = _activeCategoryIndex == idx;

                return TopicCategoryTray(
                  categoryName: cluster.categoryName,
                  emoji: cluster.emoji,
                  clue: board.clues['cat${String.fromCharCode(65 + idx)}Clue'],
                  explanation: cluster.explanation,
                  collocations: cluster.collocations,
                  targetCount: board.targetClusterSize,
                  placedWords: placed,
                  isActive: isTrayActive,
                  isCompleted: isTrayComplete,
                  accentColor: accentColor,
                  onTap: () {
                    _hapticService.selection();
                    setState(() => _activeCategoryIndex = idx);
                  },
                  onRemoveWord: (w) => _handleRemoveWord(idx, w),
                  onWordTap: _speak,
                );
              }),
              if (_coachingMessage != null)
                TopicPracticeCoachingBanner(message: _coachingMessage!),
              SizedBox(height: 6.h),
              if (_poolWords.isNotEmpty) ...[
                Text(
                  'Available Words (${_poolWords.length}):',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                SizedBox(height: 8.h),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _poolWords.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        (_poolWords.length == 3 || _poolWords.length >= 5) ? 3 : 2,
                    crossAxisSpacing: 10.w,
                    mainAxisSpacing: 10.h,
                    childAspectRatio: 1.35,
                  ),
                  itemBuilder: (context, index) {
                    final word = _poolWords[index];
                    return TopicFusionTile(
                      word: word,
                      isSelected: false,
                      accentColor: accentColor,
                      onTap: () => _handleWordTap(word),
                      onLongPress: () => _handleTileLongPress(word),
                    );
                  },
                ),
              ],
              if (isDone) const TopicPracticeCelebrationCard(),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
