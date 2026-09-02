import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/controllers/prefix_suffix_controller.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/widgets/prefix_suffix_mission_control.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/widgets/prefix_suffix_synthesizer.dart';
import 'package:vowl/core/presentation/game_mechanics/type_to_confirm_overlay.dart';

class PrefixSuffixScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const PrefixSuffixScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.prefixSuffix,
  });

  @override
  State<PrefixSuffixScreen> createState() => _PrefixSuffixScreenState();
}

class _PrefixSuffixScreenState extends State<PrefixSuffixScreen> {
  late final PrefixSuffixController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = PrefixSuffixController(
      hapticService: di.sl<HapticService>(),
      soundService: di.sl<SoundService>(),
      ttsService: di.sl<TtsService>(),
      onSubmitAnswer: (bool isCorrect) {
        if (mounted) {
          context.read<VocabularyBloc>().add(SubmitAnswer(isCorrect));
        }
      },
    );
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          final isNewQuestion =
              state.currentIndex != _controller.lastProcessedIndex;
          final isRetry =
              !state.answerStatus.isAnswered && _controller.isAnswered;

          if (isNewQuestion || isRetry) {
            _controller.reset(state.currentQuest, state.currentIndex);
          } else if (state.answerStatus.isAnswered && !_controller.isAnswered) {
            _controller.setAnswered(state.answerStatus.asBoolOrNull ?? false);
          }
        }
        if (state is VocabularyGameComplete) {
          _controller.completeGame();
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'LEXICAL MASTER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final theme = LevelThemeHelper.getTheme(
          'vocabulary',
          level: widget.level,
        );

        if (state is VocabularyLoading ||
            (state is! VocabularyGameComplete &&
                _controller.lastQuest == null &&
                state is! VocabularyLoaded &&
                state is! VocabularyError)) {
          return Scaffold(
            body: GameShimmerLoading(primaryColor: theme.primaryColor),
          );
        }

        final quest = (state is VocabularyLoaded)
            ? state.currentQuest
            : _controller.lastQuest;

        return ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            final baseLayout = VocabularyBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _controller.isAnswered,
              isCorrect: _controller.isCorrect,
              isFinalFailure: (state is VocabularyLoaded)
                  ? state.isFinalFailure
                  : false,
              showConfetti: _controller.showConfetti,
              hasStage2: true,
              onContinue: () =>
                  context.read<VocabularyBloc>().add(NextQuestion()),
              useScrolling: false,
              onHint: () {
                _controller.onHint(quest);
              },
              child: quest == null
                  ? const SizedBox()
                  : Stack(
                      children: [
                        RawScrollbar(
                          controller: _scrollController,
                          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                    vertical: 20.h,
                                  ),
                                  child: Column(
                                    children: [
                                      PrefixSuffixMissionControl(
                                        primaryColor: theme.primaryColor,
                                        instruction:
                                            quest.hint ?? quest.instruction,
                                      ),
                                      SizedBox(height: 20.h),
                                      IgnorePointer(
                                        ignoring:
                                            _controller.isFirstStagePassed,
                                        child: PrefixSuffixSynthesizer(
                                          rootWord: quest.rootWord ?? "???",
                                          options: quest.options ?? [],
                                          correctAnswer:
                                              quest.correctAnswer ?? "",
                                          selectedAffix:
                                              _controller.selectedAffix,
                                          hintedAffix: _controller.hintedAffix,
                                          isFirstStagePassed:
                                              _controller.isFirstStagePassed,
                                          primaryColor: theme.primaryColor,
                                          isDark: isDark,
                                          onAffixSelected: (affix, isPrefix) =>
                                              _controller.onAffixSelected(
                                                affix,
                                                quest,
                                                isPrefix,
                                              ),
                                        ),
                                      ),
                                      SizedBox(
                                        height:
                                            (_controller.isFirstStagePassed &&
                                                !_controller.isAnswered)
                                            ? 380.h
                                            : 60.h,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_controller.isFirstStagePassed &&
                            !_controller.isAnswered)
                          TypeToConfirmOverlay(
                            isPositioned: true,
                            expectedText: quest.correctAnswer ?? "",
                            primaryColor: theme.primaryColor,
                            onConfirmed: () =>
                                _controller.submitFinalAnswer(true, quest),
                            onBypassed: () =>
                                _controller.submitFinalAnswer(true, quest),
                            onSkipped: () =>
                                _controller.submitFinalAnswer(false, quest),
                          ),
                      ],
                    ),
            );
            return baseLayout;
          },
        );
      },
    );
  }
}
