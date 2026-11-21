import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/vocabulary/topic_vocab/domain/entities/topic_practice_quest.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/controllers/topic_vocab_controller.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_matrix_grid.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_word_peek_sheet.dart';

/// Guided active recall screen for Topic Vocab ("Practice: Word Groups").
/// Learners practice grouping tiles into 3-word semantic clusters with hints,
/// one-away feedback, audio tap feedback, and strongly-typed domain models.
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
  TopicVocabController? _controller;
  late final HapticService _hapticService = di.sl.isRegistered<HapticService>()
      ? di.sl<HapticService>()
      : HapticService();

  @override
  void initState() {
    super.initState();
    _loadCurriculum();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  int get _batchStart => ((widget.level - 1) ~/ 10) * 10 + 1;
  int get _batchEnd => _batchStart + 9;

  Future<void> _loadCurriculum() async {
    final batchPath =
        'assets/curriculum/vocabulary/topicVocab_practice_${_batchStart}_$_batchEnd.json';
    try {
      final jsonString = await rootBundle.loadString(batchPath);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests = (data['quests'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      final filtered = rawQuests
          .where((q) => (q['level'] as int? ?? widget.level) == widget.level)
          .map((q) => TopicPracticeQuest.fromJson(q))
          .toList();

      if (mounted) {
        setState(() {
          _quests = filtered.isNotEmpty ? filtered : _buildFallbackQuests();
          _isLoading = false;
          _initControllerForCurrentQuest();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _quests = _buildFallbackQuests();
          _isLoading = false;
          _initControllerForCurrentQuest();
        });
      }
    }
  }

  List<TopicPracticeQuest> _buildFallbackQuests() {
    return [
      TopicPracticeQuest(
        id: 'VOC_TOPICVOCAB_L${widget.level}_PRACTICE_FALLBACK',
        level: widget.level,
        conceptTitle: 'Practice: Word Groups',
        boards: const [
          TopicPracticeBoard(
            targetClusterSize: 3,
            tiles: [
              'Boiling',
              'Scorching',
              'Steaming',
              'Freezing',
              'Icy',
              'Chilly',
            ],
            clusters: [
              TopicPracticeCluster(
                categoryName: 'Intense Heat',
                emoji: '🔥',
                words: ['Boiling', 'Scorching', 'Steaming'],
                explanation: 'Words describing high heat and vapor.',
              ),
              TopicPracticeCluster(
                categoryName: 'Extreme Cold',
                emoji: '❄️',
                words: ['Freezing', 'Icy', 'Chilly'],
                explanation: 'Words describing freezing cold and ice.',
              ),
            ],
            clues: {
              'catAClue': 'Think of high temperatures and boiling heat.',
              'catBClue': 'Think of freezing ice and cold winter weather.',
            },
          ),
        ],
      ),
    ];
  }

  void _initControllerForCurrentQuest() {
    _controller?.dispose();
    if (_quests.isEmpty) return;

    final quest = _quests[_currentIndex];
    if (quest.boards.isEmpty) return;

    final board = quest.boards.first;
    final parsedClusters = board.clusters.map((c) {
      return TopicClusterGroup(
        categoryName: c.categoryName,
        emoji: c.emoji,
        words: c.words,
        explanation: c.explanation,
      );
    }).toList();

    _controller =
        TopicVocabController(
          targetClusters: parsedClusters,
          targetClusterSize: board.targetClusterSize,
          initialTiles: board.tiles,
          hapticService: _hapticService,
        )..addListener(() {
          if (mounted) setState(() {});
        });
  }

  void _handleFuse() {
    _controller?.submitFusion();
  }

  void _handleHint() {
    if (_quests.isEmpty) return;
    final quest = _quests[_currentIndex];
    if (quest.boards.isEmpty) return;
    final board = quest.boards.first;

    final clueText = board.clues.isNotEmpty
        ? board.clues.values.join(' • ')
        : 'Look for words that share a common theme or situation.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(clueText),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
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
      definition: matchedExplanation ?? 'Thematic vocabulary item in this lesson.',
      categoryHint: matchedCategory,
      accentColor: theme.primaryColor,
    );
  }

  void _handleNext() {
    _hapticService.light();
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
        _initControllerForCurrentQuest();
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

    if (_isLoading || _controller == null) {
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
              ShimmerLoading.rounded(
                height: 100.h,
                width: double.infinity,
                borderRadius: 16,
              ),
              SizedBox(height: 16.h),
              ShimmerLoading.rounded(
                height: 200.h,
                width: double.infinity,
                borderRadius: 16,
              ),
            ],
          ),
        ),
      );
    }

    final isLast = _currentIndex == _quests.length - 1;
    final isDone = _controller!.isComplete;

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
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: TopicMatrixGrid(
          controller: _controller!,
          accentColor: accentColor,
          onFuse: _handleFuse,
          onTileLongPress: _handleTileLongPress,
        ),
      ),
    );
  }
}
