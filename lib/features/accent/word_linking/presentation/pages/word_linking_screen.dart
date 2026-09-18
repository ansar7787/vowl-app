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
import 'package:vowl/features/accent/word_linking/presentation/widgets/word_linking_instruction.dart';
import 'package:vowl/features/accent/word_linking/presentation/widgets/word_linking_pulse_speaker.dart';
import 'package:vowl/features/accent/word_linking/presentation/widgets/word_linking_sentence_field.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/shadow_playback_compare.dart';

class WordLinkingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const WordLinkingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.wordLinking,
  });

  @override
  State<WordLinkingScreen> createState() => _WordLinkingScreenState();
}

class _WordLinkingScreenState extends State<WordLinkingScreen> with AccentGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ScrollController _scrollController = ScrollController();
        final ValueNotifier<int?> _selectedNodeIndex = ValueNotifier(null);
    AccentQuest? _lastQuest;

  @override
  void dispose() {
    _scrollController.dispose();
                _selectedNodeIndex.dispose();
        disposeAccentGame();
    disposeAccentGame();
    disposeAccentGame();
    super.dispose();
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

    initAccentGame();
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

  void _onNodeTap(int index, String correctPair, List<String> words) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;

    _selectedNodeIndex.value = index;

    String selectedPair = "${words[index]} ${words[index + 1]}";
    bool isCorrect =
        selectedPair.toLowerCase().trim() == correctPair.toLowerCase().trim();

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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('accent', level: widget.level);

    return BlocConsumer<AccentBloc, AccentState>(
      listenWhen: accentListenWhen,
      listener: onAccentStateChanged,
      builder: (context, state) {
        final AccentQuest? quest = (state is AccentLoaded)
            ? state.currentQuest as AccentQuest?
            : _lastQuest;
        final words = quest?.words ?? [];
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
              _selectedNodeIndex,
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
                    : RawScrollbar(
                        controller: _scrollController,
                        thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                        radius: Radius.circular(8.r),
                        thickness: 4.w,
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: IgnorePointer(
                                ignoring: isFirstStagePassedNotifier.value,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24.w,
                                    vertical: 16.h,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      WordLinkingInstruction(
                                        color: theme.primaryColor,
                                        instruction: isFirstStagePassedNotifier.value
                                            ? "Great job! Now record yourself saying the phrase."
                                            : quest.instruction,
                                      ),
                                      SizedBox(height: 32.h),
                                      WordLinkingPulseSpeaker(
                                        text: quest.textToSpeak ?? "",
                                        color: theme.primaryColor,
                                        onPlayTts: _playTts,
                                      ),
                                      SizedBox(height: 48.h),
                                      WordLinkingSentenceField(
                                        words: words,
                                        correctPair: quest.correctAnswer ?? "",
                                        linkingType: quest.linkingType,
                                        color: theme.primaryColor,
                                        isDark: isDark,
                                        isAnswered:
                                            isAnsweredNotifier.value ||
                                            isFirstStagePassedNotifier.value,
                                        selectedNodeIndex:
                                            _selectedNodeIndex.value,
                                        onNodeTap: _onNodeTap,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (isFirstStagePassedNotifier.value && !isAnsweredNotifier.value)
                              SliverToBoxAdapter(
                                child: Column(
                                  children: [
                                    ShadowPlaybackCompare(
                                      expectedText: quest.textToSpeak ?? "",
                                      displayText: quest.textToSpeak ?? "",
                                      primaryColor: theme.primaryColor,
                                      isPositioned: false,
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
                      ),
              );
            },
          ),
        );
      },
    );
  }
}

