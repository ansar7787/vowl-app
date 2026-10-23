import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:vowl/features/grammar/presentation/mixins/grammar_game_screen_mixin.dart';
import 'package:vowl/features/grammar/voice_swap/presentation/widgets/voice_swap_instruction.dart';
import 'package:vowl/features/grammar/voice_swap/presentation/widgets/voice_swap_toggle.dart';

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
    with
        GameScreenMixin<VoiceSwapScreen>,
        GrammarGameScreenMixin<VoiceSwapScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<bool> _isPassive = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  @override
  void dispose() {
    _isPassive.dispose();
    _scrollTimer?.cancel();
    _scrollController.dispose();
    disposeGrammarGame();
    super.dispose();
  }

  void _scrollToBottom() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onStagePassedScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 100), () {
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

  void _submitAnswer(GrammarQuest? quest) {
    if (isAnsweredNotifier.value ||
        isFirstStagePassedNotifier.value ||
        quest == null) {
      return;
    }

    final selectedVoice = _isPassive.value ? "Passive" : "Active";
    final isCorrect = selectedVoice.toLowerCase() ==
        (quest.correctAnswerCategory?.toLowerCase() ??
            quest.correctAnswer?.toLowerCase());

    if (isCorrect) {
      hapticService.success();
      soundService.playCorrect();

      final match = RegExp(
        r'flip to:\s*(.*?)(?:\.|\s)*$',
      ).firstMatch(quest.explanation ?? '');
      String expectedConversion = match?.group(1) ?? "";

      if (expectedConversion.isEmpty) {
        final isCurrentPassive = (quest.correctAnswerCategory?.toLowerCase() ??
                quest.correctAnswer?.toLowerCase()) ==
            'passive';
        expectedConversion = isCurrentPassive
            ? (quest.activeVoice ?? "")
            : (quest.passiveVoice ?? "");
      }

      if (expectedConversion.isEmpty) {
        isAnsweredNotifier.value = true;
        isCorrectNotifier.value = true;
        context.read<GrammarBloc>().add(const SubmitAnswer(true));
      } else {
        isFirstStagePassedNotifier.value = true;
        _scrollToBottom();
      }
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt, GameQuest quest) {
    if (isAnsweredNotifier.value) {
      return;
    }

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = nailedIt;

    if (nailedIt) {
      hapticService.success();
      soundService.playCorrect();
      context.read<GrammarBloc>().add(const SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  @override
  void onQuestionReset() {
    _scrollTimer?.cancel();
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
          targetVoiceStr = _isPassive.value ? "Active" : "Passive";

          final match = RegExp(
            r'flip to:\s*(.*?)(?:\.|\s)*$',
          ).firstMatch(quest.explanation ?? '');
          if (match != null && match.group(1) != null) {
            expectedConversion = match.group(1)!;
          }

          if (expectedConversion.isEmpty) {
            final isCurrentPassive =
                (quest.correctAnswerCategory?.toLowerCase() ??
                        quest.correctAnswer?.toLowerCase()) ==
                    'passive';
            expectedConversion = isCurrentPassive
                ? (quest.activeVoice ?? "")
                : (quest.passiveVoice ?? "");
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
              isAnswered: isAnsweredNotifier.value &&
                  (isCorrectNotifier.value != null ||
                      !isFirstStagePassedNotifier.value),
              isCorrect: isCorrectNotifier.value,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: showConfettiNotifier.value,
              useScrolling: false,
              onContinue: () =>
                  context.read<GrammarBloc>().add(const NextQuestion()),
              onHint: () {},
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final maxHeight = constraints.maxHeight;
                        final isCompact = maxHeight < 680;
                        final reduceMotion =
                            VowlMotion.shouldReduceMotion(context);

                        return AnimatedPadding(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOut,
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
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
                              physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              slivers: [
                                SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: IgnorePointer(
                                    ignoring:
                                        isFirstStagePassedNotifier.value,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20.w,
                                      ),
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            height: isCompact ? 8.h : 14.h,
                                          ),
                                          VoiceSwapInstruction(
                                            primaryColor: theme.primaryColor,
                                            instruction: quest.instruction,
                                          ),
                                          SizedBox(
                                            height: isCompact ? 14.h : 22.h,
                                          ),

                                          // Sentence Card
                                          Builder(
                                            builder: (context) {
                                              final card = Container(
                                                key: const ValueKey(
                                                  'voice_sentence_card',
                                                ),
                                                width: double.infinity,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: isCompact
                                                      ? 16.w
                                                      : 20.w,
                                                  vertical: isCompact
                                                      ? 16.h
                                                      : 22.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? AppColors.slate800
                                                          .withValues(alpha: 0.9)
                                                      : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    isCompact ? 16.r : 20.r,
                                                  ),
                                                  border: Border.all(
                                                    color: theme.primaryColor
                                                        .withValues(
                                                      alpha: 0.18,
                                                    ),
                                                    width: 1.5,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: isDark
                                                          ? Colors.black
                                                              .withValues(
                                                              alpha: 0.25,
                                                            )
                                                          : Colors.black
                                                              .withValues(
                                                              alpha: 0.05,
                                                            ),
                                                      blurRadius: 10,
                                                      offset: const Offset(
                                                        0,
                                                        3,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Text(
                                                  quest.sentence ?? "",
                                                  textAlign: TextAlign.center,
                                                  softWrap: true,
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: isCompact
                                                        ? 16.sp
                                                        : 18.sp,
                                                    color: isDark
                                                        ? Colors.white
                                                        : AppColors.slate900,
                                                    height: 1.45,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                              );
                                              if (reduceMotion) return card;
                                              return card
                                                  .animate()
                                                  .fadeIn(duration: 400.ms)
                                                  .slideY(begin: 0.15, end: 0);
                                            },
                                          ),

                                          SizedBox(
                                            height: isCompact ? 18.h : 30.h,
                                          ),

                                          // Voice Toggle Mechanism
                                          VoiceSwapToggle(
                                            key: const ValueKey(
                                              'voice_swap_toggle',
                                            ),
                                            isPassive: _isPassive.value,
                                            isAnswered: isAnsweredNotifier
                                                    .value &&
                                                (isCorrectNotifier.value !=
                                                        null ||
                                                    !isFirstStagePassedNotifier
                                                        .value),
                                            primaryColor: theme.primaryColor,
                                            isDark: isDark,
                                            onToggle: (val) =>
                                                _isPassive.value = val,
                                          ),

                                          SizedBox(
                                            height: isCompact ? 22.h : 36.h,
                                          ),

                                          // Check Answer Button (comfortably positioned below mechanism)
                                          if (!isAnsweredNotifier.value)
                                            ScaleButton(
                                              key: const ValueKey(
                                                'voice_engage_button',
                                              ),
                                              onTap: () => _submitAnswer(quest),
                                              child: Container(
                                                width: double.infinity,
                                                height: isCompact ? 48.h : 54.h,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    16.r,
                                                  ),
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      theme.primaryColor,
                                                      theme.primaryColor
                                                          .withValues(
                                                        alpha: 0.85,
                                                      ),
                                                    ],
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: theme.primaryColor
                                                          .withValues(
                                                        alpha: 0.35,
                                                      ),
                                                      blurRadius: 14,
                                                      offset: const Offset(
                                                        0,
                                                        4,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    "CHECK ANSWER",
                                                    style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      fontSize: isCompact
                                                          ? 14.sp
                                                          : 16.sp,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white,
                                                      letterSpacing: 0.8,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),

                                          SizedBox(
                                            height: isCompact ? 16.h : 28.h,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Game Mechanism Confirmation Card (with proper standard horizontal padding)
                                if (isFirstStagePassedNotifier.value &&
                                    !isAnsweredNotifier.value)
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      key: const ValueKey(
                                        'voice_overlay_padding',
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20.w,
                                        vertical: 8.h,
                                      ),
                                      child: TypeToConfirmOverlay(
                                        key: const ValueKey(
                                          'voice_type_overlay',
                                        ),
                                        expectedText: expectedConversion,
                                        displayText:
                                            "Rewrite the sentence in $targetVoiceStr voice",
                                        primaryColor: theme.primaryColor,
                                        onConfirmed: () =>
                                            _submitVerbalEvaluation(
                                          true,
                                          quest,
                                        ),
                                        onSkipped: () =>
                                            _submitVerbalEvaluation(
                                          false,
                                          quest,
                                        ),
                                        isPositioned: false,
                                      ),
                                    ),
                                  ),
                                SliverToBoxAdapter(
                                  child: SizedBox(
                                    height: MediaQuery.of(context)
                                                .viewInsets
                                                .bottom >
                                            0
                                        ? MediaQuery.of(context)
                                                .viewInsets
                                                .bottom +
                                            200.h
                                        : 60.h,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
