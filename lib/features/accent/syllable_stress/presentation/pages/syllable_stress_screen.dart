import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/mixins/accent_game_screen_mixin.dart';
import 'package:vowl/features/accent/presentation/layout/accent_base_layout.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/syllable_stress/presentation/widgets/syllable_stress_instruction.dart';
import 'package:vowl/features/accent/syllable_stress/presentation/widgets/syllable_stress_prompt_card.dart';
import 'package:vowl/features/accent/syllable_stress/presentation/widgets/syllable_stress_pulse_speaker.dart';
import 'package:vowl/features/accent/syllable_stress/presentation/widgets/syllable_stress_drum_console.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';

/// Screen host for Syllable Stress exercises, identifying metrical beats and prominence in polysyllabic words.
class SyllableStressScreen extends StatefulWidget {
  /// Current level index.
  final int level;

  /// Game subtype identifier.
  final GameSubtype gameType;

  /// Creates a [SyllableStressScreen] widget.
  const SyllableStressScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.syllableStress,
  });

  @override
  State<SyllableStressScreen> createState() => _SyllableStressScreenState();
}

class _SyllableStressScreenState extends State<SyllableStressScreen>
    with
        GameScreenMixin<SyllableStressScreen>,
        AccentGameScreenMixin<SyllableStressScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ScrollController _scrollController = ScrollController();

  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);

  AccentQuest? _lastQuest;

  @override
  void dispose() {
    _scrollController.dispose();
    _selectedIndex.dispose();
    try {
      soundService.stopTts();
    } catch (_) {}
    disposeAccentGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initAccentGame();
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

  void _playTts(String text) {
    hapticService.selection();
    soundService.playTts(text);
  }

  void _onPadTap(int index, int correct) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;

    _selectedIndex.value = index;

    if (index == correct) {
      hapticService.success();
      soundService.playCorrect();
      isFirstStagePassedNotifier.value = true;
      _scrollToBottom();
      // Wait for Phase 2
    } else {
      final currentQuest = _lastQuest ??
          ((context.read<AccentBloc>().state is AccentLoaded)
              ? (context.read<AccentBloc>().state as AccentLoaded).currentQuest
              : null);
      if (currentQuest != null) {
        submitWrongAnswer(
          quest: currentQuest,
          userAnswer: '',
        );
      }
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (isAnsweredNotifier.value) return;

    if (nailedIt) {
      context.read<AccentBloc>().add(const AccentSpeakConfirmed(5));
      submitCorrectAnswer();
    } else {
      final currentQuest = _lastQuest ??
          ((context.read<AccentBloc>().state is AccentLoaded)
              ? (context.read<AccentBloc>().state as AccentLoaded).currentQuest
              : null);
      if (currentQuest != null) {
        submitWrongAnswer(
          quest: currentQuest,
          userAnswer: '',
        );
      }
    }
  }

  @override
  void onQuestionReset() {
    _selectedIndex.value = null;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
  }

  @override
  void onAccentStateChanged(BuildContext context, AccentState state) {
    if (state is AccentLoaded) {
      _lastQuest = state.currentQuest;
    }
    super.onAccentStateChanged(context, state);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('accent', level: widget.level);

    return BlocConsumer<AccentBloc, AccentState>(
      listenWhen: accentListenWhen,
      listener: onAccentStateChanged,
      builder: (context, state) {
        final AccentQuest? quest = (state is AccentLoaded)
            ? state.currentQuest as AccentQuest?
            : null;
        if (quest != null) {
          _lastQuest = quest;
        }
        final syllables = quest?.syllables ?? [];
        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              isAnsweredNotifier,
              isCorrectNotifier,
              showConfettiNotifier,
              _selectedIndex,
              isFirstStagePassedNotifier,
            ]),
            builder: (context, _) {
              return AccentBaseLayout(
                gameType: widget.gameType,
                level: widget.level,
                isAnswered: isAnsweredNotifier.value,
                isCorrect: isCorrectNotifier.value,
                showConfetti: showConfettiNotifier.value,
                onContinue: () =>
                    context.read<AccentBloc>().add(NextQuestion()),
                onHint: () {},
                useScrolling: false,
                child: quest == null
                    ? GameShimmerLoading(primaryColor: theme.primaryColor)
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final maxHeight = constraints.maxHeight;

                          // Proportional vertical spacing that adapts naturally to screen height
                          final double estimatedContentHeight = 390.h;
                          final remainingHeight =
                              maxHeight - estimatedContentHeight;

                          final double gapUnit = remainingHeight > 0
                              ? remainingHeight / 7
                              : 0;
                          final double gapTop = remainingHeight > 0
                              ? (gapUnit * 0.8).clamp(8.0, 20.0)
                              : 8.0;
                          final double gapInstruction = remainingHeight > 0
                              ? (gapUnit * 0.8).clamp(8.0, 18.0)
                              : 8.0;
                          final double gapPrompt = remainingHeight > 0
                              ? (gapUnit * 1.1).clamp(10.0, 22.0)
                              : 10.0;
                          final double gapSpeaker = remainingHeight > 0
                              ? (gapUnit * 1.3).clamp(12.0, 26.0)
                              : 12.0;
                          final double gapBottom = remainingHeight > 0
                              ? (gapUnit * 1.0).clamp(12.0, 28.0)
                              : 12.0;

                          return RawScrollbar(
                            controller: _scrollController,
                            thumbColor: theme.primaryColor.withValues(
                              alpha: 0.5,
                            ),
                            radius: Radius.circular(8.r),
                            thickness: 4.w,
                            child: CustomScrollView(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              slivers: [
                                SliverToBoxAdapter(
                                  child: Center(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: constraints.maxHeight,
                                        maxWidth: 520.w,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 20.w,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            SizedBox(height: gapTop),
                                            SyllableStressInstruction(
                                              color: theme.primaryColor,
                                              instruction:
                                                  isFirstStagePassedNotifier
                                                          .value
                                                      ? context.tr(
                                                          'games.syllable_stress_phase2',
                                                          fallback:
                                                              'Speak the word with the correct stress',
                                                        )
                                                      : quest.instruction,
                                            ),
                                            SizedBox(height: gapInstruction),
                                            SyllableStressPromptCard(
                                              word: quest.word ?? "",
                                              color: theme.primaryColor,
                                              isDark: isDark,
                                            ),
                                            SizedBox(height: gapPrompt),
                                            SyllableStressPulseSpeaker(
                                              text: quest.textToSpeak ?? "",
                                              color: theme.primaryColor,
                                              onPlayTts: _playTts,
                                            ),
                                            SizedBox(height: gapSpeaker),
                                            SyllableStressDrumConsole(
                                              syllables: syllables,
                                              correctIndex: quest
                                                      .correctAnswerIndex ??
                                                  0,
                                              color: theme.primaryColor,
                                              isDark: isDark,
                                              isAnswered:
                                                  isAnsweredNotifier.value ||
                                                      isFirstStagePassedNotifier
                                                          .value,
                                              selectedIndex:
                                                  _selectedIndex.value,
                                              onPadTap: _onPadTap,
                                            ),
                                            SizedBox(height: gapBottom),
                                            SizedBox(
                                              height:
                                                  (isFirstStagePassedNotifier
                                                              .value &&
                                                          !isAnsweredNotifier
                                                              .value)
                                                      ? 24.h
                                                      : 140.h,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                if (isFirstStagePassedNotifier.value &&
                                    !isAnsweredNotifier.value)
                                  SliverToBoxAdapter(
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: 520.w,
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 20.w,
                                          ),
                                          child: Column(
                                            children: [
                                              SpeakToConfirmOverlay(
                                                title: "Speak to confirm",
                                                subtitle:
                                                    "Say the word clearly with the correct stress",
                                                expectedText: quest.word ?? "",
                                                displayText:
                                                    "${context.tr('games.speak_word_correct_stress', fallback: 'Speak the word with the correct stress:')}\n${quest.word ?? ""}",
                                                primaryColor:
                                                    theme.primaryColor,
                                                onConfirmed: () =>
                                                    _submitVerbalEvaluation(
                                                        true),
                                                onSkipped: () =>
                                                    _submitVerbalEvaluation(
                                                        false),
                                                isPositioned: false,
                                              ),
                                              SizedBox(height: 60.h),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              );
            },
          ),
        );
      },
    );
  }
}
