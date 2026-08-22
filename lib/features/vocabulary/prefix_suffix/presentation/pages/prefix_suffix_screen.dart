import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/controllers/prefix_suffix_controller.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import '../widgets/prefix_suffix_mission_control.dart';
import '../widgets/prefix_suffix_docking_terminal.dart';
import '../widgets/prefix_suffix_root_rover.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/widgets/prefix_suffix_meaning_breakdown.dart';
import 'package:vowl/core/presentation/game_mechanics/dynamic_anagram_wrapper.dart';

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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          final isNewQuestion = state.currentIndex != _controller.lastProcessedIndex;
          final isRetry = !state.answerStatus.isAnswered && _controller.isAnswered;

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
            return VocabularyBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _controller.isAnswered,
              isCorrect: _controller.isCorrect,
              isFinalFailure: (state is VocabularyLoaded)
                  ? state.isFinalFailure
                  : false,
              showConfetti: _controller.showConfetti,
              onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
              useScrolling: false,
              onHint: () {
                final isCompact = _controller.safeHeight < 580;
                _controller.onHint(quest, isCompact);
              },
              child: quest == null
                  ? const SizedBox()
                  : CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final screenSize = MediaQuery.of(context).size;
                              final double safeWidth = constraints.maxWidth.isFinite
                                  ? constraints.maxWidth
                                  : screenSize.width;
                              final double safeHeight = constraints.maxHeight.isFinite
                                  ? constraints.maxHeight
                                  : (screenSize.height * 0.6);
                              final isCompact = safeHeight < 580;
                              _controller.updateDimensions(safeWidth, safeHeight);

                        return SizedBox(
                          width: safeWidth,
                          height: safeHeight,
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              // ── STAGE 1: Drag and Drop ──
                              IgnorePointer(
                                ignoring: _controller.isFirstStagePassed,
                                child: Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned(
                                      top: 20.h,
                                      child: PrefixSuffixMissionControl(
                                        primaryColor: theme.primaryColor,
                                        instruction: quest.hint ?? quest.instruction,
                                      )
                                      .animate(target: (_controller.isAnswered || _controller.isFirstStagePassed) ? 1 : 0)
                                      .fadeOut(duration: 400.ms)
                                      .slideY(begin: 0, end: -1.5, duration: 400.ms, curve: Curves.easeIn),
                                    ),

                                    // Docking Terminals
                                    ...List.generate(
                                      quest.options?.length ?? 0,
                                      (i) => PrefixSuffixDockingTerminal(
                                        index: i,
                                        text: quest.options![i],
                                        primaryColor: theme.primaryColor,
                                        isDark: isDark,
                                        position: _controller.getTerminalPosition(
                                          i,
                                          quest.options!.length,
                                          safeWidth,
                                          safeHeight,
                                          isCompact,
                                        ),
                                        parentWidth: safeWidth,
                                        parentHeight: safeHeight,
                                      ),
                                    ),

                                    // The Root Rover
                                    PrefixSuffixRootRover(
                                      rootWord: quest.rootWord ?? "???",
                                      primaryColor: theme.primaryColor,
                                      isDark: isDark,
                                      dragOffset: _controller.dragOffset,
                                      isCompact: isCompact,
                                      onPanUpdate: (d) => _controller.onRoverDrag(d.delta),
                                      onPanEnd: (_) => _controller.onRoverRelease(quest, isCompact),
                                    ),
                                  ],
                                )
                                .animate(target: _controller.isFirstStagePassed ? 1 : 0)
                                .fadeOut(duration: 400.ms)
                                .scale(end: const Offset(0.9, 0.9), duration: 400.ms, curve: Curves.easeIn),
                              ),

                              // End of Stage 1 Stack
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // ── STAGE 2: Anagram Builder ──
                  if (_controller.isFirstStagePassed && !_controller.isAnswered)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (quest.meaningBreakdown != null)
                              PrefixSuffixMeaningBreakdown(
                                meaningBreakdown: quest.meaningBreakdown!,
                                color: theme.primaryColor,
                              ),
                            if (quest.explanation != null && quest.explanation!.isNotEmpty) ...[
                              SizedBox(height: 16.h),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  quest.explanation!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                            SizedBox(height: 30.h),
                            DynamicAnagramWrapper(
                              title: context.tr('prefix_suffix.spell_title', fallback: 'SPELL THE TARGET WORD'),
                              subtitle: context.tr('prefix_suffix.spell_subtitle', fallback: 'Tap all letters to rebuild the word!'),
                              expectedText: quest.correctAnswer ?? '',
                              primaryColor: theme.primaryColor,
                              onConfirmed: () => _controller.submitFinalAnswer(true, quest),
                              onFailed: () {},
                              onFailedWithSpelling: (wrongWord) =>
                                  _controller.submitFinalAnswer(false, quest, wrongWord: wrongWord),
                              isPositioned: false,
                            ),
                            SizedBox(height: 60.h),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 200.ms)
                      .slideY(begin: 0.1, end: 0, duration: 500.ms, curve: Curves.easeOut, delay: 200.ms),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
