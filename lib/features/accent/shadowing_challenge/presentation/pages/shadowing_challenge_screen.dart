import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/mixins/accent_game_screen_mixin.dart';
import 'package:vowl/features/accent/presentation/layout/accent_base_layout.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/widgets/shadowing_challenge_instruction.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/widgets/shadowing_challenge_prompt_card.dart';

import 'package:vowl/features/accent/shadowing_challenge/presentation/widgets/shadowing_challenge_pulse_speaker.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/widgets/shadowing_challenge_dialogue_list.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/widgets/shadowing_challenge_speed_slider.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/shadow_playback_compare.dart';

class ShadowingChallengeScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ShadowingChallengeScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.shadowingChallenge,
  });

  @override
  State<ShadowingChallengeScreen> createState() =>
      _ShadowingChallengeScreenState();
}

class _ShadowingChallengeScreenState extends State<ShadowingChallengeScreen>
    with AccentGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ScrollController _scrollController = ScrollController();

  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ValueNotifier<double> _currentSpeed = ValueNotifier(1.0);

  @override
  void initState() {
    super.initState();
    initAccentGame();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _selectedIndex.dispose();
    _currentSpeed.dispose();
    disposeAccentGame();
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

  void _playTts(String text) {
    hapticService.selection();
    // Assuming base speed is around 0.4. We'll adjust it by _currentSpeed.
    soundService.playTts(text, speed: 0.4 * _currentSpeed.value);
  }

  void _submitChoice(int index, int correct) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;
    _selectedIndex.value = index;

    bool isCorrect = index == correct;

    if (isCorrect) {
      hapticService.success();
      soundService.playCorrect();
      isFirstStagePassedNotifier.value = true;
      _scrollToBottom();
      // Wait for Phase 2
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (isAnsweredNotifier.value) return;

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = nailedIt;

    if (nailedIt) {
      hapticService.success();
      soundService.playCorrect();
      context.read<AccentBloc>().add(const AccentSpeakConfirmed(5));
      context.read<AccentBloc>().add(SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  void onQuestionReset() {
    _selectedIndex.value = null;

    _currentSpeed.value = 1.0;
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
        final rawOptions = quest?.options ?? ["A", "B"];
        final options = List<String>.from(rawOptions)
          ..shuffle(Random(quest?.id.hashCode ?? 0));

        final originalCorrectAnswer =
            quest?.correctAnswer ??
            ((quest?.options != null && quest!.options!.isNotEmpty)
                ? quest.options![quest.correctAnswerIndex ?? 0]
                : "A");

        final correctIndex = options.indexOf(originalCorrectAnswer);
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
              _currentSpeed,
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
                onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
                useScrolling: false,
                child: quest == null
                    ? GameShimmerLoading(primaryColor: theme.primaryColor)
                    : LayoutBuilder(
                        builder: (context, constraints) {
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
                                  child: IgnorePointer(
                                    ignoring: isFirstStagePassedNotifier.value,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: constraints.maxHeight,
                                      ),
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 24.w,
                                              vertical: 24.h,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                ShadowingChallengeInstruction(
                                                  color: theme.primaryColor,
                                                  instruction:
                                                      isFirstStagePassedNotifier
                                                          .value
                                                      ? "Great job! Now record yourself saying the phrase."
                                                      : quest.instruction,
                                                ),
                                                SizedBox(height: 16.h),
                                                ShadowingChallengePromptCard(
                                                  word: quest.word ?? "",
                                                  ipa: quest.phonetic ?? "",
                                                  color: theme.primaryColor,
                                                  isDark: isDark,
                                                ),
                                                SizedBox(height: 24.h),
                                                ShadowingChallengePulseSpeaker(
                                                  text: quest.textToSpeak ?? "",
                                                  color: theme.primaryColor,
                                                  onPlayTts: _playTts,
                                                ),
                                                SizedBox(height: 16.h),
                                                ShadowingChallengeSpeedSlider(
                                                  speed: _currentSpeed.value,
                                                  onChanged: (val) {
                                                    _currentSpeed.value = val;
                                                  },
                                                  color: theme.primaryColor,
                                                  isDark: isDark,
                                                ),
                                                SizedBox(height: 32.h),
                                                ShadowingChallengeDialogueList(
                                                  options: options,
                                                  correctIndex: correctIndex,
                                                  color: theme.primaryColor,
                                                  isDark: isDark,
                                                  isAnswered:
                                                      isAnsweredNotifier
                                                          .value ||
                                                      isFirstStagePassedNotifier
                                                          .value,
                                                  selectedIndex:
                                                      _selectedIndex.value,
                                                  onSubmitChoice: _submitChoice,
                                                ),
                                                SizedBox(height: 24.h),
                                              ],
                                            ),
                                          ),

                                          SizedBox(
                                            height:
                                                (isAnsweredNotifier.value ||
                                                    isFirstStagePassedNotifier
                                                        .value)
                                                ? 10.h
                                                : 60.h,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (isFirstStagePassedNotifier.value &&
                                    (!isAnsweredNotifier.value ||
                                        isCorrectNotifier.value == null))
                                  SliverToBoxAdapter(
                                    child: Column(
                                      children: [
                                        SizedBox(height: 32.h),
                                        ShadowPlaybackCompare(
                                          expectedText: quest.textToSpeak ?? "",
                                          displayText: quest.textToSpeak ?? "",
                                          primaryColor: theme.primaryColor,
                                          isPositioned: false,
                                          speedMultiplier: _currentSpeed.value,
                                          onConfirmed: () =>
                                              _submitVerbalEvaluation(true),
                                          onSkipped: () =>
                                              _submitVerbalEvaluation(false),
                                        ),
                                        SizedBox(height: 60.h),
                                      ],
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
