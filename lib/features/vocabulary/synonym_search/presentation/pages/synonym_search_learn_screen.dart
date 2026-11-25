import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_error_view.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/controllers/synonym_learn_controller.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/models/synonym_phase_models.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_cousin_preview_strip.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_learn_spotlight_header.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_makeover_card.dart';

/// Learn Phase for Synonym Search ("Sentence Makeover Studio").
///
/// Teaches synonym nuance through live interactive in-sentence word swaps,
/// native ear verdicts, spoken audio, and word-family cousin comparisons.
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

  @override
  void initState() {
    super.initState();
    _controller = SynonymLearnController(hapticService: _tryHaptic());
    try {
      TtsService().preWarm();
    } catch (_) {}

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

    final batchStart = ((widget.level - 1) ~/ 10) * 10 + 1;
    final batchEnd = batchStart + 9;
    final assetPath =
        'assets/curriculum/vocabulary/synonymSearch_learn_${batchStart}_$batchEnd.json';

    try {
      final bundle = widget.assetBundle ?? DefaultAssetBundle.of(context);
      final rawJson = await bundle.loadString(assetPath);
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final batch = SynonymLearnBatch.fromJson(decoded);
      final items = batch.itemsForLevel(widget.level);

      if (!mounted) return;
      _controller.setItems(
        items.isNotEmpty ? items : [SynonymLearnItem.fallback(widget.level)],
      );
      setState(() {
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Unable to load Level ${widget.level} synonym studio data.';
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

  void _stopAudioSafely() {
    try {
      TtsSpeakerButtonWidget.stopAll();
      TtsService().stop();
    } catch (_) {}
  }

  void _handleCompleteOrNext() {
    _stopAudioSafely();
    if (_controller.nextPair()) {
      _scrollToTop();
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
    _stopAudioSafely();
    _controller.previousPair();
    _scrollToTop();
  }

  @override
  void dispose() {
    _stopAudioSafely();
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
        title: 'Sentence Makeover Studio',
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
        title: 'Sentence Makeover Studio',
        gameType: 'synonymSearch',
        level: widget.level,
        isActionEnabled: true,
        actionLabel: 'Continue with Sample',
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
        _controller.selectedCousinByQuest,
      ]),
      builder: (context, _) {
        final idx = _controller.currentIndex.value;
        final total = _controller.items.length;
        final item = _controller.currentItem ?? _controller.items.first;
        final tested = _controller.testedCountForCurrent();

        return LearnPhaseScaffold(
          title: 'Makeover Studio (${idx + 1}/$total)',
          gameType: 'synonymSearch',
          level: widget.level,
          previousLabel: 'Previous',
          onPrevious: idx > 0 ? _handlePrevious : null,
          actionLabel: idx < total - 1 ? 'Next Pair' : 'Go to Practice',
          isActionEnabled: true,
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
                SynonymLearnSpotlightHeader(
                  item: item,
                  pairIndex: idx,
                  totalPairs: total,
                  testedMakeovers: tested,
                  primaryColor: theme.primaryColor,
                ),
                SizedBox(height: 14.h),
                for (int i = 0; i < item.makeovers.length; i++) ...[
                  SynonymMakeoverCard(
                    scenario: item.makeovers[i],
                    scenarioIndex: i,
                    isSwapped: _controller.isMakeoverSwapped(i),
                    primaryColor: theme.primaryColor,
                    onToggleSwap: () => _controller.toggleMakeoverSwap(i),
                  ),
                  if (i < item.makeovers.length - 1) SizedBox(height: 12.h),
                ],
                SizedBox(height: 14.h),
                SynonymCousinPreviewStrip(
                  cousins: item.cousinWords,
                  selectedIndex: _controller.selectedCousinIndexForCurrent(),
                  primaryColor: theme.primaryColor,
                  onSelectCousin: _controller.selectCousin,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
