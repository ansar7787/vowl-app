import 'dart:async';
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
import 'package:vowl/features/accent/connected_speech/presentation/widgets/connected_speech_instruction.dart';
import 'package:vowl/features/accent/connected_speech/presentation/widgets/connected_speech_prompt_card.dart';
import 'package:vowl/features/accent/connected_speech/presentation/widgets/connected_speech_pulse_speaker.dart';
import 'package:vowl/features/accent/connected_speech/presentation/widgets/connected_speech_linker_cards.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/shadow_playback_compare.dart';

class ConnectedSpeechScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ConnectedSpeechScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.connectedSpeech,
  });

  @override
  State<ConnectedSpeechScreen> createState() => _ConnectedSpeechScreenState();
}

class _ConnectedSpeechScreenState extends State<ConnectedSpeechScreen>
    with AccentGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  AccentQuest? _lastQuest;

  final List<String> _shuffledOptions = [];
  final int _shuffledCorrectIndex = 0;

  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  Timer? _resetTimer;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    initAccentGame();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _selectedIndex.dispose();
    _resetTimer?.cancel();
    disposeAccentGame();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _scrollController.hasClients) {
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

  void _submitChoice(int index, int correct) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;
    _selectedIndex.value = index;

    final bool isCorrect = index == correct;

    if (isCorrect) {
      hapticService.selection();
      isFirstStagePassedNotifier.value = true;
      _scrollToBottom();
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
            ? state.currentQuest
            : _lastQuest;
        final options = _shuffledOptions.isNotEmpty
            ? _shuffledOptions
            : (quest?.options ?? ["A", "B"]);
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
                onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
                useScrolling: false,
                child: quest == null
                    ? GameShimmerLoading(primaryColor: theme.primaryColor)
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final maxHeight = constraints.maxHeight;
                          final bool isCompact = maxHeight < 580;

                          // Estimated content height in ScreenUtil units
                          final double estimatedContentHeight =
                              24.h +
                              (isCompact ? 90.h : 120.h) +
                              100.h +
                              (isCompact ? 130.h : 172.h);
                          final remainingHeight =
                              maxHeight - estimatedContentHeight;

                          // Dynamic layout spacers based on remaining height
                          final double gapUnit = remainingHeight > 0
                              ? remainingHeight / 8
                              : 0;
                          final double gapTop = remainingHeight > 0
                              ? (gapUnit * 1).clamp(8.0, 24.0)
                              : 8.0;
                          final double gapInstruction = remainingHeight > 0
                              ? (gapUnit * 1).clamp(8.0, 24.0)
                              : 8.0;
                          final double gapPrompt = remainingHeight > 0
                              ? (gapUnit * 1.5).clamp(12.0, 32.0)
                              : 12.0;
                          final double gapSpeaker = remainingHeight > 0
                              ? (gapUnit * 2).clamp(16.0, 48.0)
                              : 16.0;
                          final double gapBottom = remainingHeight > 0
                              ? (gapUnit * 1).clamp(12.0, 40.0)
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
                              physics:
                                  (!isFirstStagePassedNotifier.value &&
                                      remainingHeight >= 0)
                                  ? const NeverScrollableScrollPhysics()
                                  : const BouncingScrollPhysics(),
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
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SizedBox(height: gapTop),
                                                    ConnectedSpeechInstruction(
                                                      primaryColor:
                                                          theme.primaryColor,
                                                      instruction:
                                                          isFirstStagePassedNotifier
                                                              .value
                                                          ? "Great job! Now confirm by speaking the phrase."
                                                          : quest.instruction,
                                                      isCompact: isCompact,
                                                    ),
                                                    SizedBox(
                                                      height: gapInstruction,
                                                    ),

                                                    ConnectedSpeechPromptCard(
                                                      word: quest.word ?? "",
                                                      spokenForm:
                                                          quest.spokenForm,
                                                      phenomenonType:
                                                          quest.phenomenonType,
                                                      isAnswered:
                                                          isFirstStagePassedNotifier
                                                              .value ||
                                                          isAnsweredNotifier
                                                              .value,
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                      isCompact: isCompact,
                                                    ),
                                                    SizedBox(height: gapPrompt),

                                                    ConnectedSpeechPulseSpeaker(
                                                      text:
                                                          quest.textToSpeak ??
                                                          "",
                                                      color: theme.primaryColor,
                                                      onPlayTts: _playTts,
                                                    ),
                                                  ],
                                                ),
                                                Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SizedBox(
                                                      height: gapSpeaker,
                                                    ),
                                                    ConnectedSpeechLinkerCards(
                                                      key: ValueKey(quest.id),
                                                      options: options,
                                                      correctIndex:
                                                          _shuffledOptions
                                                              .isNotEmpty
                                                          ? _shuffledCorrectIndex
                                                          : (quest.correctAnswerIndex ??
                                                                0),
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                      isAnswered:
                                                          isAnsweredNotifier
                                                              .value ||
                                                          isFirstStagePassedNotifier
                                                              .value,
                                                      selectedIndex:
                                                          _selectedIndex.value,
                                                      onSubmitChoice:
                                                          _submitChoice,
                                                      isCompact: isCompact,
                                                    ),
                                                    SizedBox(height: gapBottom),
                                                  ],
                                                ),
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
                                          expectedText:
                                              quest.textToSpeak ??
                                              quest.word ??
                                              "",
                                          primaryColor: theme.primaryColor,
                                          isPositioned: false,
                                          onConfirmed: () {
                                            context.read<AccentBloc>().add(
                                              const AccentSpeakConfirmed(5),
                                            );
                                            _submitVerbalEvaluation(true);
                                          },
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
