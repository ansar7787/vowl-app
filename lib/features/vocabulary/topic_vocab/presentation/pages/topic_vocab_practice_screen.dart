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
import 'package:vowl/features/vocabulary/topic_vocab/presentation/controllers/topic_vocab_controller.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_matrix_grid.dart';

/// Guided active recall screen for Topic Vocab ("Cluster Fusion Gym").
/// Learners practice fusing tiles into 3-word semantic clusters with hints and one-away feedback.
class TopicVocabPracticeScreen extends StatefulWidget {
  final int level;

  const TopicVocabPracticeScreen({super.key, required this.level});

  @override
  State<TopicVocabPracticeScreen> createState() =>
      _TopicVocabPracticeScreenState();
}

class _TopicVocabPracticeScreenState extends State<TopicVocabPracticeScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _quests = [];
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

  List<Map<String, dynamic>> _buildFallbackQuests() {
    return [
      {
        'id': 'VOC_TOPICVOCAB_L${widget.level}_PRACTICE_FALLBACK',
        'level': widget.level,
        'boards': [
          {
            'targetClusterSize': 3,
            'tiles': [
              'Boiling',
              'Scorching',
              'Steaming',
              'Freezing',
              'Icy',
              'Chilly',
            ],
            'clusters': [
              {
                'categoryName': 'Intense Heat',
                'emoji': '🔥',
                'words': ['Boiling', 'Scorching', 'Steaming'],
                'explanation': 'Terms describing extreme heat.',
              },
              {
                'categoryName': 'Extreme Cold',
                'emoji': '❄️',
                'words': ['Freezing', 'Icy', 'Chilly'],
                'explanation': 'Terms describing freezing chill.',
              },
            ],
            'clues': {
              'catAClue': 'Think of hot temperatures and vapor.',
              'catBClue': 'Think of winter ice and frost.',
            },
          },
        ],
      },
    ];
  }

  void _initControllerForCurrentQuest() {
    _controller?.dispose();
    if (_quests.isEmpty) return;

    final quest = _quests[_currentIndex];
    final boards = (quest['boards'] as List<dynamic>?) ?? [];
    if (boards.isEmpty) return;

    final board = boards.first as Map<String, dynamic>;
    final clustersList = (board['clusters'] as List<dynamic>?) ?? [];
    final targetSize = board['targetClusterSize'] as int? ?? 3;
    final initialTiles = (board['tiles'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();

    final parsedClusters = clustersList.map((c) {
      final cmap = c as Map<String, dynamic>;
      return TopicClusterGroup(
        categoryName: cmap['categoryName'] as String? ?? 'Category',
        emoji: cmap['emoji'] as String? ?? '✨',
        words: (cmap['words'] as List<dynamic>)
            .map((e) => e.toString())
            .toList(),
        explanation: cmap['explanation'] as String?,
      );
    }).toList();

    _controller =
        TopicVocabController(
          targetClusters: parsedClusters,
          targetClusterSize: targetSize,
          initialTiles: initialTiles,
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
    final boards = (quest['boards'] as List<dynamic>?) ?? [];
    if (boards.isEmpty) return;
    final board = boards.first as Map<String, dynamic>;
    final clues = board['clues'] as Map<String, dynamic>?;

    final clueText = clues != null
        ? clues.values.join(' • ')
        : 'Look for semantic similarities among remaining tiles.';

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
            '/vocabulary/topicVocab/mastery/${widget.level}',
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
        title: 'Cluster Fusion Gym',
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
      title: 'Cluster Fusion Gym',
      gameType: 'topicVocab',
      level: widget.level,
      currentExerciseIndex: _currentIndex,
      totalExercises: _quests.length,
      isActionEnabled: isDone,
      actionLabel: isLast ? 'Finish Gym & Enter Mastery' : 'Next Fusion Board',
      onComplete: _handleNext,
      onHint: _handleHint,
      isHintAvailable: !isDone,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: TopicMatrixGrid(
          controller: _controller!,
          accentColor: accentColor,
          onFuse: _handleFuse,
        ),
      ),
    );
  }
}
