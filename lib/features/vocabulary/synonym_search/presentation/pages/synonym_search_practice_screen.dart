import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_error_view.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/vocabulary/synonym_search/data/datasources/synonym_phase_local_data_source.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/controllers/synonym_practice_controller.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/controllers/synonym_tts_helper.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/models/synonym_phase_models.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_contrast_swap_card.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_ladder_card.dart';

/// Practice Phase for Synonym Search.
///
/// Alternates sentence blank matching and word-strength ordering exercises
/// with forgiving retries and guided answers.
class SynonymSearchPracticeScreen extends StatefulWidget {
  final int level;

  @visibleForTesting
  final List<SynonymPracticeExercise>? initialExercises;

  @visibleForTesting
  final AssetBundle? assetBundle;

  const SynonymSearchPracticeScreen({
    super.key,
    required this.level,
    this.initialExercises,
    this.assetBundle,
  });

  @override
  State<SynonymSearchPracticeScreen> createState() =>
      _SynonymSearchPracticeScreenState();
}

class _SynonymSearchPracticeScreenState
    extends State<SynonymSearchPracticeScreen> {
  late final SynonymPracticeController _controller;
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _hasStartedLoad = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = SynonymPracticeController(hapticService: _tryHaptic());
    SynonymTtsHelper.preWarm();

    if (widget.initialExercises != null &&
        widget.initialExercises!.isNotEmpty) {
      _controller.setExercises(widget.initialExercises!);
      _isLoading = false;
      _hasStartedLoad = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasStartedLoad) {
      _hasStartedLoad = true;
      _loadCurriculum();
    }
  }

  HapticService? _tryHaptic() {
    try {
      return di.sl<HapticService>();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadCurriculum() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dataSource = SynonymPhaseLocalDataSource(
        bundle: widget.assetBundle ?? DefaultAssetBundle.of(context),
      );
      final exercises = await dataSource.loadPracticeExercises(widget.level);

      if (!mounted) return;
      _controller.setExercises(exercises);
      setState(() {
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load Level ${widget.level} practice.';
      });
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _handlePrimaryAction() {
    final checked = _controller.hasChecked.value;
    final correct = _controller.isCorrect.value;

    if (!checked) {
      _controller.checkAnswer();
      return;
    }

    if (!correct) {
      if (_controller.wrongAttempts.value >= 2) {
        _controller.revealGuidedSolution();
      }
      return;
    }

    SynonymTtsHelper.stopAll();
    if (_controller.nextExercise()) {
      _scrollToTop();
      return;
    }

    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'synonymSearch',
      level: widget.level,
      phase: 'practice',
    );
    context.pushReplacement(
      '/game?category=vocabulary&gameType=synonymSearch&level=${widget.level}',
    );
  }

  @override
  void dispose() {
    SynonymTtsHelper.stopAll();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.of(
      context,
      'synonymSearch',
      level: widget.level,
    );

    if (_isLoading) {
      return PracticePhaseScaffold(
        title: 'Synonym Practice',
        gameType: 'synonymSearch',
        level: widget.level,
        currentExerciseIndex: 0,
        totalExercises: 1,
        isActionEnabled: false,
        onComplete: () {},
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.screen),
            child: GameShimmerLoading(primaryColor: theme.primaryColor),
          ),
        ),
      );
    }

    if (_errorMessage != null || _controller.exercises.isEmpty) {
      return PracticePhaseScaffold(
        title: 'Synonym Practice',
        gameType: 'synonymSearch',
        level: widget.level,
        currentExerciseIndex: 0,
        totalExercises: 1,
        isActionEnabled: true,
        actionLabel: 'Use Sample Practice',
        onComplete: () {
          _controller.setExercises(
            SynonymPracticeQuest.fallbackExercises(widget.level),
          );
          setState(() {
            _errorMessage = null;
          });
        },
        child: GameErrorView(
          message: _errorMessage ?? 'No practice questions found.',
          primaryColor: theme.primaryColor,
          onRetry: _loadCurriculum,
          onExit: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    return ListenableBuilder(
      listenable: Listenable.merge([
        _controller.currentIndex,
        _controller.contrastAssignments,
        _controller.focusedSlotIndex,
        _controller.ladderPlacements,
        _controller.focusedRungIndex,
        _controller.hasChecked,
        _controller.isCorrect,
        _controller.feedbackMessage,
        _controller.showHint,
        _controller.wrongAttempts,
        _controller.shakeCount,
      ]),
      builder: (context, _) {
        final idx = _controller.currentIndex.value;
        final total = _controller.exercises.length;
        final ex = _controller.currentExercise ?? _controller.exercises.first;
        final hasChecked = _controller.hasChecked.value;
        final isCorrect = _controller.isCorrect.value;
        final wrongCount = _controller.wrongAttempts.value;

        final String ctaLabel;
        final bool ctaEnabled;
        if (!hasChecked) {
          ctaLabel = 'Check Answer';
          ctaEnabled = _controller.canCheck;
        } else if (isCorrect) {
          ctaLabel = idx < total - 1 ? 'Next Question' : 'Start Challenge';
          ctaEnabled = true;
        } else if (wrongCount >= 2) {
          ctaLabel = 'Show Answer';
          ctaEnabled = true;
        } else {
          ctaLabel = 'Tap a blank to change it';
          ctaEnabled = false;
        }

        return PracticePhaseScaffold(
          title: 'Synonym Practice',
          gameType: 'synonymSearch',
          level: widget.level,
          currentExerciseIndex: idx,
          totalExercises: total,
          isHintAvailable:
              !(hasChecked && isCorrect) && !_controller.showHint.value,
          onHint: _controller.toggleHint,
          actionLabel: ctaLabel,
          isActionEnabled: ctaEnabled,
          onComplete: _handlePrimaryAction,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screen,
              12.h,
              AppSpacing.screen,
              24.h,
            ),
            child: ex.type == SynonymPracticeExerciseType.contrastSwap
                ? SynonymContrastSwapCard(
                    exercise: ex,
                    assignments: _controller.contrastAssignments.value,
                    focusedSlotIndex: _controller.focusedSlotIndex.value,
                    hasChecked: hasChecked,
                    isCorrect: isCorrect,
                    showHint: _controller.showHint.value,
                    shakeCount: _controller.shakeCount.value,
                    feedbackMessage: _controller.feedbackMessage.value,
                    primaryColor: theme.primaryColor,
                    onTapSlot: _controller.tapContrastSlot,
                    onAssignWord: _controller.assignContrastWord,
                    onSwapSlots: _controller.swapContrastSlots,
                  )
                : SynonymLadderCard(
                    exercise: ex,
                    placements: _controller.ladderPlacements.value,
                    focusedRungIndex: _controller.focusedRungIndex.value,
                    hasChecked: hasChecked,
                    isCorrect: isCorrect,
                    showHint: _controller.showHint.value,
                    shakeCount: _controller.shakeCount.value,
                    feedbackMessage: _controller.feedbackMessage.value,
                    primaryColor: theme.primaryColor,
                    onTapRung: _controller.tapLadderRung,
                    onPlaceWord: _controller.placeLadderWord,
                  ),
          ),
        );
      },
    );
  }
}
