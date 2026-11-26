import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_error_view.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/vocabulary/synonym_search/data/datasources/synonym_phase_local_data_source.dart';
import 'package:vowl/features/vocabulary/synonym_search/data/datasources/synonym_weak_words_store.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/controllers/synonym_learn_controller.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/controllers/synonym_tts_helper.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/models/synonym_phase_models.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_cousin_preview_strip.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_learn_spotlight_header.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_makeover_card.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_ui_tokens.dart';

/// Learn Phase for Synonym Search.
///
/// Teaches synonym usage through live in-sentence word swaps, plain
/// explanations, spoken audio, and related word examples.
class SynonymSearchLearnScreen extends StatefulWidget {
  final int level;

  @visibleForTesting
  final List<SynonymLearnItem>? initialItems;

  @visibleForTesting
  final AssetBundle? assetBundle;

  const SynonymSearchLearnScreen({
    super.key,
    required this.level,
    this.initialItems,
    this.assetBundle,
  });

  @override
  State<SynonymSearchLearnScreen> createState() =>
      _SynonymSearchLearnScreenState();
}

class _SynonymSearchLearnScreenState extends State<SynonymSearchLearnScreen> {
  late final SynonymLearnController _controller;
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _hasStartedLoad = false;
  String? _errorMessage;
  Map<String, int> _reviewLevelsById = const {};

  @override
  void initState() {
    super.initState();
    _controller = SynonymLearnController(hapticService: _tryHaptic());
    SynonymTtsHelper.preWarm();

    if (widget.initialItems != null && widget.initialItems!.isNotEmpty) {
      _controller.setItems(widget.initialItems!);
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
      final items = await dataSource.loadLearnItems(widget.level);
      final weakPairs = await SynonymWeakWordsStore.loadWeakPairs(
        excludeLevel: widget.level,
        limit: 1,
      );
      final combined = List<SynonymLearnItem>.from(items);
      final reviewLevels = <String, int>{};
      for (final weak in weakPairs) {
        try {
          final priorItems = await dataSource.loadLearnItems(weak.level);
          final match = priorItems.where(
            (it) =>
                it.baseWord.toLowerCase() == weak.baseWord.toLowerCase() &&
                it.synonym.toLowerCase() == weak.synonym.toLowerCase(),
          );
          if (match.isNotEmpty) {
            combined.add(match.first);
            reviewLevels[match.first.id] = weak.level;
          }
        } catch (_) {}
      }

      if (!mounted) return;
      _controller.setItems(combined);
      setState(() {
        _reviewLevelsById = reviewLevels;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load Level ${widget.level} lessons.';
      });
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      if (VowlMotion.shouldReduceMotion(context)) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  void _speakCurrentIfEnabled() {
    if (!_controller.autoSpeak.value) return;
    final item = _controller.currentItem;
    if (item == null) return;
    SynonymTtsHelper.speak(
      '${item.baseWord}. ${item.synonym}. ${item.coreMeaning}',
    );
  }

  void _handleToggleAutoSpeak() {
    _controller.toggleAutoSpeak();
    if (_controller.autoSpeak.value) {
      _speakCurrentIfEnabled();
    } else {
      SynonymTtsHelper.stopAll();
    }
  }

  void _handleToggleMakeover(int scenarioIndex) {
    _controller.toggleMakeoverSwap(scenarioIndex);
    _maybeSpeakMakeover(scenarioIndex);
  }

  void _handlePredictMakeover(int scenarioIndex, bool predictedNatural) {
    _controller.predictMakeover(
      scenarioIndex,
      predictedNatural: predictedNatural,
    );
    _maybeSpeakMakeover(scenarioIndex);
  }

  void _maybeSpeakMakeover(int scenarioIndex) {
    if (!_controller.autoSpeak.value) return;
    final item = _controller.currentItem;
    if (item == null || scenarioIndex >= item.makeovers.length) return;
    final scenario = item.makeovers[scenarioIndex];
    final swapped = _controller.isMakeoverSwapped(scenarioIndex);
    final activeWord = swapped ? scenario.swappedWord : scenario.targetSlotWord;
    final sentence =
        (swapped &&
            scenario.isNaturalSwap &&
            scenario.spokenSentence.isNotEmpty)
        ? scenario.spokenSentence
        : scenario.beforeSentence.replaceAll('___', activeWord);
    SynonymTtsHelper.speak(sentence);
  }

  void _handleSelectCousin(int cousinIndex) {
    _controller.selectCousin(cousinIndex);
    if (!_controller.autoSpeak.value) return;
    final selectedIdx = _controller.selectedCousinIndexForCurrent();
    final item = _controller.currentItem;
    if (selectedIdx == null ||
        item == null ||
        selectedIdx >= item.cousinWords.length) {
      return;
    }
    final cousin = item.cousinWords[selectedIdx];
    SynonymTtsHelper.speak('${cousin.word}. ${cousin.miniContext}');
  }

  void _handleCompleteOrNext() {
    SynonymTtsHelper.stopAll();
    final finishedItem = _controller.currentItem;
    if (finishedItem != null &&
        _reviewLevelsById.containsKey(finishedItem.id)) {
      SynonymWeakWordsStore.markReviewed(
        baseWord: finishedItem.baseWord,
        synonym: finishedItem.synonym,
      );
    }
    if (_controller.nextPair()) {
      _scrollToTop();
      _speakCurrentIfEnabled();
      return;
    }
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'synonymSearch',
      level: widget.level,
      phase: 'learn',
    );
    context.pushReplacement(
      '/practice?category=vocabulary&gameType=synonymSearch&level=${widget.level}',
    );
  }

  void _handlePrevious() {
    SynonymTtsHelper.stopAll();
    _controller.previousPair();
    _scrollToTop();
    _speakCurrentIfEnabled();
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
      return LearnPhaseScaffold(
        title: 'Word Examples',
        gameType: 'synonymSearch',
        level: widget.level,
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

    if (_errorMessage != null || _controller.items.isEmpty) {
      return LearnPhaseScaffold(
        title: 'Word Examples',
        gameType: 'synonymSearch',
        level: widget.level,
        isActionEnabled: true,
        actionLabel: 'Use Sample Lesson',
        onComplete: () {
          _controller.setItems([SynonymLearnItem.fallback(widget.level)]);
          setState(() {
            _errorMessage = null;
          });
        },
        child: GameErrorView(
          message: _errorMessage ?? 'No lesson items found.',
          primaryColor: theme.primaryColor,
          onRetry: _loadCurriculum,
          onExit: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    return ListenableBuilder(
      listenable: Listenable.merge([
        _controller.currentIndex,
        _controller.swappedByQuest,
        _controller.predictionByQuest,
        _controller.selectedCousinByQuest,
        _controller.autoSpeak,
      ]),
      builder: (context, _) {
        final idx = _controller.currentIndex.value;
        final total = _controller.items.length;
        final item = _controller.currentItem ?? _controller.items.first;
        final tested = _controller.testedCountForCurrent();
        final canContinue = tested > 0;
        final reviewLevel = _reviewLevelsById[item.id];

        return LearnPhaseScaffold(
          title: 'Word Examples (${idx + 1}/$total)',
          gameType: 'synonymSearch',
          level: widget.level,
          previousLabel: 'Previous',
          onPrevious: idx > 0 ? _handlePrevious : null,
          actionLabel: !canContinue
              ? 'Check 1 Example'
              : (idx < total - 1 ? 'Next Pair' : 'Start Practice'),
          isActionEnabled: canContinue,
          onComplete: _handleCompleteOrNext,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screen,
              12.h,
              AppSpacing.screen,
              24.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (reviewLevel != null) ...[
                  Container(
                    padding: SynonymUiTokens.badgePadding,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(
                        SynonymUiTokens.badgeRadius,
                      ),
                    ),
                    child: Text(
                      'Review from Level $reviewLevel',
                      style: SynonymUiTokens.badgeLabel(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                ],
                SynonymLearnSpotlightHeader(
                  item: item,
                  pairIndex: idx,
                  totalPairs: total,
                  testedMakeovers: tested,
                  primaryColor: theme.primaryColor,
                  autoSpeak: _controller.autoSpeak.value,
                  onToggleAutoSpeak: _handleToggleAutoSpeak,
                ),
                SizedBox(height: 14.h),
                for (int i = 0; i < item.makeovers.length; i++) ...[
                  SynonymMakeoverCard(
                    scenario: item.makeovers[i],
                    scenarioIndex: i,
                    isSwapped: _controller.isMakeoverSwapped(i),
                    predictedNatural: _controller.predictionFor(i),
                    primaryColor: theme.primaryColor,
                    onToggleSwap: () => _handleToggleMakeover(i),
                    onPredict: (natural) => _handlePredictMakeover(i, natural),
                  ),
                  if (i < item.makeovers.length - 1) SizedBox(height: 12.h),
                ],
                SizedBox(height: 14.h),
                SynonymCousinPreviewStrip(
                  cousins: item.cousinWords,
                  selectedIndex: _controller.selectedCousinIndexForCurrent(),
                  primaryColor: theme.primaryColor,
                  onSelectCousin: _handleSelectCousin,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
