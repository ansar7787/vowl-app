import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/mixins/grammar_game_screen_mixin.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/grammar/voice_swap/presentation/widgets/voice_swap_instruction.dart';
import 'package:vowl/features/grammar/voice_swap/presentation/widgets/voice_swap_toggle.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';

class VoiceSwapScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const VoiceSwapScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.voiceSwap,
  });

  @override
  State<VoiceSwapScreen> createState() => _VoiceSwapScreenState();
}

class _VoiceSwapScreenState extends State<VoiceSwapScreen>
    with GrammarGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<bool> _isPassive = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _isPassive.dispose();
    _scrollController.dispose();
    disposeGrammarGame();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
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
    isFirstStagePassedNotifier.addListener(_onStagePassedScroll);

    initGrammarGame();
  }

  void _submitAnswer(GameQuest? quest) {
    if (isAnsweredNotifier.value ||
        isFirstStagePassedNotifier.value ||
        quest == null) {
      return;
    }

    final selectedVoice = _isPassive.value ? "Passive" : "Active";
    bool isCorrect =
        selectedVoice.toLowerCase() ==
        (quest.correctAnswerCategory?.toLowerCase() ??
            quest.correctAnswer?.toLowerCase());

    if (isCorrect) {
      hapticService.success();
      soundService.playCorrect();

      final match = RegExp(
        r'flip to:\s*(.*?)(?:\.|\s)*$',
      ).firstMatch(quest.explanation ?? '');
      final expectedConversion = match?.group(1) ?? "";

      if (expectedConversion.isEmpty) {
        isAnsweredNotifier.value = true;
        isCorrectNotifier.value = true;
        context.read<GrammarBloc>().add(SubmitAnswer(true));
      } else {
        isFirstStagePassedNotifier.value = true;
        _scrollToBottom();
      }
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      context.read<GrammarBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (isAnsweredNotifier.value) {
      return;
    }

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = nailedIt;

    if (nailedIt) {
      hapticService.success();
      soundService.playCorrect();
      context.read<GrammarBloc>().add(SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      context.read<GrammarBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  void onQuestionReset() {
    _isPassive.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listenWhen: grammarListenWhen,
      listener: onGrammarStateChanged,
      builder: (context, state) {
        final quest = (state is GrammarLoaded)
            ? state.currentQuest as GrammarQuest?
            : null;

        String targetVoiceStr = "";
        String expectedConversion = "";
        if (quest != null) {
          if (_isPassive.value) {
            targetVoiceStr = "Active";
          } else {
            targetVoiceStr = "Passive";
          }
          final match = RegExp(
            r'flip to:\s*(.*?)(?:\.|\s)*$',
          ).firstMatch(quest.explanation ?? '');
          if (match != null && match.group(1) != null) {
            expectedConversion = match.group(1)!;
          }
        }

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _isPassive,
            isFirstStagePassedNotifier,
          ]),
          builder: (context, _) {
            return GrammarBaseLayout(
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered:
                  isAnsweredNotifier.value &&
                  (isCorrectNotifier.value != null ||
                      !isFirstStagePassedNotifier.value),
              isCorrect: isCorrectNotifier.value,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: showConfettiNotifier.value,
              useScrolling: false,
              onContinue: () => context.read<GrammarBloc>().add(NextQuestion()),
              onHint: () => context.read<GrammarBloc>().add(GrammarHintUsed()),
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            AnimatedPadding(
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeOut,
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(
                                  context,
                                ).viewInsets.bottom,
                              ),
                              child: RawScrollbar(
                                controller: _scrollController,
                                thumbColor: theme.primaryColor.withValues(
                                  alpha: 0.5,
                                ),
                                radius: Radius.circular(8.r),
                                thickness: 4.w,
                                crossAxisMargin: 2,
                                child: CustomScrollView(
                                  controller: _scrollController,
                                  physics: (!isFirstStagePassedNotifier.value)
                                      ? const NeverScrollableScrollPhysics()
                                      : const BouncingScrollPhysics(),
                                  slivers: [
                                    SliverFillRemaining(
                                      hasScrollBody: false,
                                      child: IgnorePointer(
                                        ignoring:
                                            isFirstStagePassedNotifier.value,
                                        child: Builder(
                                          builder: (context) {
                                            final maxHeight = MediaQuery.of(
                                              context,
                                            ).size.height;
                                            final isCompact = maxHeight < 700;

                                            return Column(
                                              children: [
                                                SizedBox(
                                                  height: isCompact
                                                      ? 4.h
                                                      : 10.h,
                                                ),
                                                SizedBox(
                                                  height: isCompact
                                                      ? 25.h
                                                      : 35.h,
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: VoiceSwapInstruction(
                                                      primaryColor:
                                                          theme.primaryColor,
                                                    ),
                                                  ),
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
                                                                ? 15.sp
                                                                : 20.sp,
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

                                                SizedBox(height: 60.h),

                                                // Voice Toggle
                                                VoiceSwapToggle(
                                                  isPassive: _isPassive.value,
                                                  isAnswered:
                                                      isAnsweredNotifier
                                                          .value &&
                                                      (isCorrectNotifier
                                                                  .value !=
                                                              null ||
                                                          !isFirstStagePassedNotifier
                                                              .value),
                                                  primaryColor:
                                                      theme.primaryColor,
                                                  isDark: isDark,
                                                  onToggle: (val) =>
                                                      _isPassive.value = val,
                                                ),

                                                const Spacer(),

                                                if (!isAnsweredNotifier.value)
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 24.w,
                                                        ),
                                                    child:
                                                        ScaleButton(
                                                              onTap: () =>
                                                                  _submitAnswer(
                                                                    quest,
                                                                  ),
                                                              child: Container(
                                                                width: double
                                                                    .infinity,
                                                                height:
                                                                    isCompact
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
                                                                  child: FittedBox(
                                                                    fit: BoxFit
                                                                        .scaleDown,
                                                                    child: Text(
                                                                      "ENGAGE TRANSMUTER",
                                                                      style: TextStyle(
                                                                        fontFamily:
                                                                            'Outfit',
                                                                        fontSize:
                                                                            isCompact
                                                                            ? 13.sp
                                                                            : 16.sp,
                                                                        fontWeight:
                                                                            FontWeight.w900,
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
                                                              onPlay: (c) =>
                                                                  c.repeat(
                                                                    reverse:
                                                                        true,
                                                                  ),
                                                            )
                                                            .shimmer(
                                                              duration:
                                                                  2.seconds,
                                                              color: Colors
                                                                  .white24,
                                                            ),
                                                  ),

                                                SizedBox(
                                                  height: isCompact
                                                      ? 12.h
                                                      : 40.h,
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    SliverToBoxAdapter(
                                      child: SizedBox(
                                        height:
                                            (isFirstStagePassedNotifier.value &&
                                                !isAnsweredNotifier.value)
                                            ? 180.h
                                            : 60.h,
                                      ),
                                    ),
                                    if (isFirstStagePassedNotifier.value &&
                                        !isAnsweredNotifier.value)
                                      SliverToBoxAdapter(
                                        child: Column(
                                          children: [
                                            TypeToConfirmOverlay(
                                              expectedText: expectedConversion,
                                              displayText:
                                                  "Type the $targetVoiceStr conversion to lock it in",
                                              primaryColor: theme.primaryColor,
                                              onConfirmed: () =>
                                                  _submitVerbalEvaluation(true),
                                              onSkipped: () =>
                                                  _submitVerbalEvaluation(
                                                    false,
                                                  ),
                                              isPositioned: false,
                                            ),
                                            SizedBox(height: 60.h),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
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
