import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/mixins/grammar_game_screen_mixin.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/grammar/tense_mastery/presentation/widgets/tense_mastery_instruction.dart';
import 'package:vowl/features/grammar/tense_mastery/presentation/widgets/tense_mastery_timeline_slider.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';

class TenseMasteryScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const TenseMasteryScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.tenseMastery,
  });

  @override
  State<TenseMasteryScreen> createState() => _TenseMasteryScreenState();
}

class _TenseMasteryScreenState extends State<TenseMasteryScreen>
    with GrammarGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<double> _sliderValue = ValueNotifier(
    0.5,
  ); // Default to Present
  final bool _isFinalFailure = false;
  final ValueNotifier<bool> _isDragging = ValueNotifier(false);
  final ValueNotifier<bool> _pendingSubmit = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _sliderValue.dispose();
    _isDragging.dispose();
    _pendingSubmit.dispose();
    _scrollController.dispose();
    disposeGrammarGame();
    super.dispose();
  }

  String get _currentTense {
    if (_sliderValue.value < 0.25) return "Past";
    if (_sliderValue.value > 0.75) return "Future";
    return "Present";
  }

  void _onStagePassedScroll() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    isAnsweredNotifier.addListener(() {
      if (isAnsweredNotifier.value && mounted && _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    _pendingSubmit.addListener(_onStagePassedScroll);

    initGrammarGame();
  }

  void _onFreezeTimeline() {
    if (isAnsweredNotifier.value) return;

    final state = context.read<GrammarBloc>().state;
    if (state is GrammarLoaded) {
      final quest = state.currentQuest;
      final selectedTense = _currentTense;
      bool isTenseCorrect =
          selectedTense.toLowerCase() ==
          (quest.correctAnswerCategory?.toLowerCase() ??
              quest.correctAnswer?.toLowerCase());

      if (!isTenseCorrect) {
        hapticService.error();
        soundService.playWrong();
        isAnsweredNotifier.value = true;
        isCorrectNotifier.value = false;
        context.read<GrammarBloc>().add(const SubmitAnswer(false));
        return;
      }
    }

    hapticService.heavy();
    _pendingSubmit.value = true;
  }

  void _submitFinalAnswer(GameQuest quest, bool nailedTyping) {
    _pendingSubmit.value = false;

    if (!nailedTyping) {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
      return;
    }

    final selectedTense = _currentTense;
    bool isCorrect =
        selectedTense.toLowerCase() ==
        (quest.correctAnswerCategory?.toLowerCase() ??
            quest.correctAnswer?.toLowerCase());

    if (isCorrect) {
      hapticService.success();
      soundService.playCorrect();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = true;
      context.read<GrammarBloc>().add(const SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  @override
  void onQuestionReset() {
    _sliderValue.value = 0.5;

    _isDragging.value = false;

    _pendingSubmit.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listenWhen: grammarListenWhen,
      listener: onGrammarStateChanged,
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _pendingSubmit,
          ]),
          builder: (context, _) {
            return GrammarBaseLayout(
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              isFinalFailure: _isFinalFailure,
              showConfetti: showConfettiNotifier.value,
              useScrolling: false,
              onContinue: () =>
                  context.read<GrammarBloc>().add(const NextQuestion()),
              onHint: () =>
                  context.read<GrammarBloc>().add(const GrammarHintUsed()),
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            RawScrollbar(
                              controller: _scrollController,
                              thumbColor: theme.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                              radius: Radius.circular(8.r),
                              thickness: 4.w,
                              crossAxisMargin: 2,
                              child: CustomScrollView(
                                controller: _scrollController,
                                physics: const BouncingScrollPhysics(),
                                slivers: [
                                  SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: Builder(
                                      builder: (context) {
                                        final maxHeight = MediaQuery.of(
                                          context,
                                        ).size.height;
                                        final isCompact = maxHeight < 700;

                                        return Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(
                                                  height: isCompact
                                                      ? 4.h
                                                      : 10.h,
                                                ),
                                                isCompact
                                                    ? SizedBox(
                                                        height: 25.h,
                                                        child: FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          child: TenseMasteryInstruction(
                                                            primaryColor: theme
                                                                .primaryColor,
                                                          ),
                                                        ),
                                                      )
                                                    : TenseMasteryInstruction(
                                                        primaryColor:
                                                            theme.primaryColor,
                                                      ),
                                                SizedBox(
                                                  height: isCompact
                                                      ? 8.h
                                                      : 20.h,
                                                ),

                                                // Context Card
                                                Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 24.w,
                                                          ),
                                                      child: Container(
                                                        padding: EdgeInsets.all(
                                                          isCompact
                                                              ? 14.r
                                                              : 22.r,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: isDark
                                                              ? Colors.white
                                                                    .withValues(
                                                                      alpha:
                                                                          0.05,
                                                                    )
                                                              : Colors.black
                                                                    .withValues(
                                                                      alpha:
                                                                          0.03,
                                                                    ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                isCompact
                                                                    ? 16.r
                                                                    : 24.r,
                                                              ),
                                                          border: Border.all(
                                                            color: theme
                                                                .primaryColor
                                                                .withValues(
                                                                  alpha: 0.15,
                                                                ),
                                                            width: 1.5,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          quest.sentence ?? "",
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'Outfit',
                                                            fontSize: isCompact
                                                                ? 14.sp
                                                                : 18.sp,
                                                            color: isDark
                                                                ? Colors.white
                                                                : Colors
                                                                      .black87,
                                                            height: 1.5,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                    .animate()
                                                    .fadeIn(duration: 600.ms)
                                                    .slideY(begin: 0.2, end: 0),

                                                SizedBox(
                                                  height: isCompact
                                                      ? 20.h
                                                      : 60.h,
                                                ),

                                                // Timeline Slider
                                                ListenableBuilder(
                                                  listenable: Listenable.merge([
                                                    _sliderValue,
                                                    _isDragging,
                                                    _pendingSubmit,
                                                  ]),
                                                  builder: (context, _) {
                                                    return TenseMasteryTimelineSlider(
                                                      sliderValue:
                                                          _sliderValue.value,
                                                      currentTense:
                                                          _currentTense,
                                                      isAnswered:
                                                          isAnsweredNotifier
                                                              .value ||
                                                          _pendingSubmit.value,
                                                      isDragging:
                                                          _isDragging.value,
                                                      isDark: isDark,
                                                      primaryColor:
                                                          theme.primaryColor,
                                                      onHapticFeedback:
                                                          hapticService
                                                              .selection,
                                                      onHeavyHapticFeedback:
                                                          hapticService.heavy,
                                                      onSliderChanged:
                                                          (value) =>
                                                              _sliderValue
                                                                      .value =
                                                                  value,
                                                      onDraggingChanged:
                                                          (value) =>
                                                              _isDragging
                                                                      .value =
                                                                  value,
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (!isAnsweredNotifier.value &&
                                                    !_pendingSubmit.value)
                                                  ScaleButton(
                                                        onTap:
                                                            _onFreezeTimeline,
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal:
                                                                    24.w,
                                                              ),
                                                          child: Container(
                                                            width:
                                                                double.infinity,
                                                            height: isCompact
                                                                ? 48.h
                                                                : 65.h,
                                                            decoration: BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    isCompact
                                                                        ? 14.r
                                                                        : 20.r,
                                                                  ),
                                                              gradient: LinearGradient(
                                                                begin: Alignment
                                                                    .topCenter,
                                                                end: Alignment
                                                                    .bottomCenter,
                                                                colors: [
                                                                  theme
                                                                      .primaryColor,
                                                                  theme
                                                                      .primaryColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.8,
                                                                      ),
                                                                ],
                                                              ),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: theme
                                                                      .primaryColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.4,
                                                                      ),
                                                                  blurRadius:
                                                                      isCompact
                                                                      ? 12
                                                                      : 20,
                                                                  offset: Offset(
                                                                    0,
                                                                    isCompact
                                                                        ? 4
                                                                        : 8,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            child: Center(
                                                              child: Text(
                                                                "FREEZE TIMELINE",
                                                                style: TextStyle(
                                                                  fontFamily:
                                                                      'Outfit',
                                                                  fontSize:
                                                                      isCompact
                                                                      ? 13.sp
                                                                      : 16.sp,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w900,
                                                                  color: Colors
                                                                      .white,
                                                                  letterSpacing:
                                                                      isCompact
                                                                      ? 2
                                                                      : 3,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                      .animate(
                                                        onPlay: (c) => c.repeat(
                                                          reverse: true,
                                                        ),
                                                      )
                                                      .shimmer(
                                                        duration: 2.seconds,
                                                        color: Colors.white24,
                                                      ),
                                                SizedBox(
                                                  height: isCompact
                                                      ? 12.h
                                                      : 40.h,
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  if (_pendingSubmit.value &&
                                      !isAnsweredNotifier.value)
                                    SliverToBoxAdapter(
                                      child: TypeToConfirmOverlay(
                                        expectedText: quest.sentence ?? '',
                                        displayText: null,
                                        primaryColor: theme.primaryColor,
                                        onConfirmed: () =>
                                            _submitFinalAnswer(quest, true),
                                        onSkipped: () =>
                                            _submitFinalAnswer(quest, false),
                                        isPositioned: false,
                                        allowSkip: true,
                                      ),
                                    ),
                                  SliverToBoxAdapter(
                                    child: SizedBox(
                                      height:
                                          MediaQuery.of(
                                                context,
                                              ).viewInsets.bottom >
                                              0
                                          ? MediaQuery.of(
                                                  context,
                                                ).viewInsets.bottom +
                                                200.h
                                          : 60.h,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }
}
