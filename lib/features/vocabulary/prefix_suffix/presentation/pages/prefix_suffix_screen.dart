import 'package:vowl/core/utils/instruction_helper.dart';
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
  bool _hasScrolledToStage2 = false;

  void _onControllerUpdate() {
    if (!mounted) return;
    if (_controller.isFirstStagePassed &&
        !_controller.isAnswered &&
        !_hasScrolledToStage2) {
      _hasScrolledToStage2 = true;
      Future.delayed(const Duration(milliseconds: 400), _scrollToBottom);
    } else if (!_controller.isFirstStagePassed) {
      _hasScrolledToStage2 = false;
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

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

    _controller.addListener(_onControllerUpdate);

    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
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
              disablePadding: true,
              useScrolling: false,
              onHint: () {
                _controller.onHint(quest);
              },
              child: quest == null
                  ? const SizedBox()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final maxHeight = constraints.maxHeight;

                        return RawScrollbar(
                          controller: _scrollController,
                          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: maxHeight,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20.w,
                                      vertical: 20.h,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        PrefixSuffixMissionControl(
                                          primaryColor: theme.primaryColor,
                                          instruction:
                                              quest.hint ??
                                              InstructionHelper.getInstruction(
                                                quest,
                                              ),
                                        ),
                                        SizedBox(height: 32.h),
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
                                            hintedAffix:
                                                _controller.hintedAffix,
                                            isFirstStagePassed:
                                                _controller.isFirstStagePassed,
                                            primaryColor: theme.primaryColor,
                                            isDark: isDark,
                                            onAffixSelected:
                                                (affix, isPrefix) =>
                                                    _controller.onAffixSelected(
                                                      affix,
                                                      quest,
                                                      isPrefix,
                                                    ),
                                          ),
                                        ),
                                        SizedBox(height: 60.h),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (_controller.isFirstStagePassed &&
                                  !_controller.isAnswered)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      bottom:
                                          24.h +
                                          MediaQuery.viewInsetsOf(
                                            context,
                                          ).bottom,
                                    ),
                                    child: TypeToConfirmOverlay(
                                      isPositioned: false,
                                      expectedText: quest.correctAnswer ?? "",
                                      primaryColor: theme.primaryColor,
                                      onConfirmed: () => _controller
                                          .submitFinalAnswer(true, quest),
                                      onBypassed: () => _controller
                                          .submitFinalAnswer(true, quest),
                                      onSkipped: () => _controller
                                          .submitFinalAnswer(false, quest),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            );
            return baseLayout;
          },
        );
      },
    );
  }
}
