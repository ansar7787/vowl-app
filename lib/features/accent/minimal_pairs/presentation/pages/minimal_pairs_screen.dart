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
import 'package:vowl/features/accent/minimal_pairs/presentation/widgets/minimal_pairs_instruction.dart';
import 'package:vowl/features/accent/minimal_pairs/presentation/widgets/minimal_pairs_speaker_core.dart';
import 'package:vowl/features/accent/minimal_pairs/presentation/widgets/minimal_pairs_drone_option.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/shadow_playback_compare.dart';
import 'package:vowl/features/accent/minimal_pairs/presentation/widgets/minimal_pairs_mouth_diagram.dart';

class MinimalPairsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const MinimalPairsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.minimalPairs,
  });

  @override
  State<MinimalPairsScreen> createState() => _MinimalPairsScreenState();
}

class _MinimalPairsScreenState extends State<MinimalPairsScreen> with AccentGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';
  AccentQuest? _lastQuest;
        final ValueNotifier<int?> _selectedDroneIndex = ValueNotifier(null);

  
  String? _shuffledQuestId;
  List<Map<String, String>> _currentOptions = [];
  int _currentCorrectIndex = 0;

  void _ensureOptionsShuffled(AccentQuest quest) {
    if (_shuffledQuestId == quest.id) return;

    _shuffledQuestId = quest.id;

    final originalOptions = [
      {'word': quest.word1 ?? '', 'ipa': quest.ipa1 ?? ''},
      {'word': quest.word2 ?? '', 'ipa': quest.ipa2 ?? ''},
    ];

    final correctAnswerStr = quest.correctAnswer;

    _currentOptions = List.from(originalOptions)..shuffle();
    if (correctAnswerStr != null) {
      _currentCorrectIndex = _currentOptions.indexWhere(
        (opt) => opt['word'] == correctAnswerStr,
      );
    } else {
      _currentCorrectIndex = _currentOptions.indexWhere(
        (opt) =>
            opt['word'] ==
            originalOptions[quest.correctAnswerIndex ?? 0]['word'],
      );
    }
    if (_currentCorrectIndex == -1) _currentCorrectIndex = 0;
  }

  late final ScrollController _scrollController;

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

    _scrollController = ScrollController();
    initAccentGame();
  }

  @override
  void dispose() {
    _scrollController.dispose();
                _selectedDroneIndex.dispose();
        disposeAccentGame();
    disposeAccentGame();
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

  void _playTts(String text) {
    hapticService.selection();
    soundService.playTts(text);
  }

  void _onShoot(int index, int correctIndex) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;

    final bool correct = index == correctIndex;
    _selectedDroneIndex.value = index;

    if (correct) {
      hapticService.success();
      soundService.playCorrect();
      isFirstStagePassedNotifier.value = true;
      _scrollToBottom();
      // Do NOT submit yet! Wait for Phase 2.
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
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

        if (quest != null && !isAnsweredNotifier.value) {
          _ensureOptionsShuffled(quest);
        }

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
          ]),
          builder: (context, _) {
            return AccentBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
              onContinue: () => context.read<AccentBloc>().add(NextQuestion()),
              onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
              useScrolling: false,
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final maxHeight = constraints.maxHeight;
                        final maxWidth = constraints.maxWidth;
                        final bool isCompact = maxHeight < 580;

                        final double estimatedContentHeight =
                            24.h +
                            (isCompact ? 90.h : 120.h) +
                            100.h +
                            (isCompact ? 130.h : 172.h);
                        final remainingHeight =
                            maxHeight - estimatedContentHeight;

                        final double gapUnit = remainingHeight > 0
                            ? remainingHeight / 8
                            : 0;
                        final double gapTop = remainingHeight > 0
                            ? (gapUnit * 1).clamp(8.0, 24.0)
                            : 8.0;
                        final double gapInstruction = remainingHeight > 0
                            ? (gapUnit * 1.5).clamp(12.0, 32.0)
                            : 12.0;

                        final double gapSpeaker = remainingHeight > 0
                            ? (gapUnit * 2).clamp(16.0, 48.0)
                            : 16.0;

                        final double gapBottom = remainingHeight > 0
                            ? (gapUnit * 1).clamp(12.0, 40.0)
                            : 12.0;

                        return ListenableBuilder(
                          listenable: Listenable.merge([
                            _selectedDroneIndex,
                            isFirstStagePassedNotifier,
                          ]),
                          builder: (context, _) {
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
                                                      MinimalPairsInstruction(
                                                        color:
                                                            theme.primaryColor,
                                                        instruction:
                                                            isFirstStagePassedNotifier
                                                                .value
                                                            ? "Great job! Now confirm by speaking the word."
                                                            : quest.instruction,
                                                      ),
                                                      SizedBox(
                                                        height: gapInstruction,
                                                      ),
                                                    ],
                                                  ),
                                                  MinimalPairsSpeakerCore(
                                                    text:
                                                        quest.textToSpeak ?? "",
                                                    color: theme.primaryColor,
                                                    onPlayTts: _playTts,
                                                  ),
                                                  Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      SizedBox(
                                                        height: gapSpeaker,
                                                      ),
                                                      isCompact
                                                          ? SizedBox(
                                                              height: 110.h,
                                                              child: FittedBox(
                                                                fit: BoxFit
                                                                    .scaleDown,
                                                                child: SizedBox(
                                                                  width:
                                                                      maxWidth -
                                                                      48.w,
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceEvenly,
                                                                    children: [
                                                                      MinimalPairsDroneOption(
                                                                        index:
                                                                            0,
                                                                        word:
                                                                            _currentOptions.isNotEmpty
                                                                            ? _currentOptions[0]['word']!
                                                                            : quest.word1 ??
                                                                                  "",
                                                                        ipa:
                                                                            _currentOptions.isNotEmpty
                                                                            ? _currentOptions[0]['ipa']!
                                                                            : quest.ipa1 ??
                                                                                  "",
                                                                        correctIndex:
                                                                            _currentOptions.isNotEmpty
                                                                            ? _currentCorrectIndex
                                                                            : quest.correctAnswerIndex ??
                                                                                  0,
                                                                        color: theme
                                                                            .primaryColor,
                                                                        isDark:
                                                                            isDark,
                                                                        isAnswered:
                                                                            isAnsweredNotifier.value ||
                                                                            isFirstStagePassedNotifier.value,
                                                                        selectedDroneIndex:
                                                                            _selectedDroneIndex.value,
                                                                        onShoot:
                                                                            _onShoot,
                                                                      ),
                                                                      MinimalPairsDroneOption(
                                                                        index:
                                                                            1,
                                                                        word:
                                                                            _currentOptions.isNotEmpty
                                                                            ? _currentOptions[1]['word']!
                                                                            : quest.word2 ??
                                                                                  "",
                                                                        ipa:
                                                                            _currentOptions.isNotEmpty
                                                                            ? _currentOptions[1]['ipa']!
                                                                            : quest.ipa2 ??
                                                                                  "",
                                                                        correctIndex:
                                                                            _currentOptions.isNotEmpty
                                                                            ? _currentCorrectIndex
                                                                            : quest.correctAnswerIndex ??
                                                                                  0,
                                                                        color: theme
                                                                            .primaryColor,
                                                                        isDark:
                                                                            isDark,
                                                                        isAnswered:
                                                                            isAnsweredNotifier.value ||
                                                                            isFirstStagePassedNotifier.value,
                                                                        selectedDroneIndex:
                                                                            _selectedDroneIndex.value,
                                                                        onShoot:
                                                                            _onShoot,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            )
                                                          : Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceEvenly,
                                                              children: [
                                                                MinimalPairsDroneOption(
                                                                  index: 0,
                                                                  word:
                                                                      _currentOptions
                                                                          .isNotEmpty
                                                                      ? _currentOptions[0]['word']!
                                                                      : quest.word1 ??
                                                                            "",
                                                                  ipa:
                                                                      _currentOptions
                                                                          .isNotEmpty
                                                                      ? _currentOptions[0]['ipa']!
                                                                      : quest.ipa1 ??
                                                                            "",
                                                                  correctIndex:
                                                                      _currentOptions
                                                                          .isNotEmpty
                                                                      ? _currentCorrectIndex
                                                                      : quest.correctAnswerIndex ??
                                                                            0,
                                                                  color: theme
                                                                      .primaryColor,
                                                                  isDark:
                                                                      isDark,
                                                                  isAnswered:
                                                                      isAnsweredNotifier
                                                                          .value ||
                                                                      isFirstStagePassedNotifier
                                                                          .value,
                                                                  selectedDroneIndex:
                                                                      _selectedDroneIndex
                                                                          .value,
                                                                  onShoot:
                                                                      _onShoot,
                                                                ),
                                                                MinimalPairsDroneOption(
                                                                  index: 1,
                                                                  word:
                                                                      _currentOptions
                                                                          .isNotEmpty
                                                                      ? _currentOptions[1]['word']!
                                                                      : quest.word2 ??
                                                                            "",
                                                                  ipa:
                                                                      _currentOptions
                                                                          .isNotEmpty
                                                                      ? _currentOptions[1]['ipa']!
                                                                      : quest.ipa2 ??
                                                                            "",
                                                                  correctIndex:
                                                                      _currentOptions
                                                                          .isNotEmpty
                                                                      ? _currentCorrectIndex
                                                                      : quest.correctAnswerIndex ??
                                                                            0,
                                                                  color: theme
                                                                      .primaryColor,
                                                                  isDark:
                                                                      isDark,
                                                                  isAnswered:
                                                                      isAnsweredNotifier
                                                                          .value ||
                                                                      isFirstStagePassedNotifier
                                                                          .value,
                                                                  selectedDroneIndex:
                                                                      _selectedDroneIndex
                                                                          .value,
                                                                  onShoot:
                                                                      _onShoot,
                                                                ),
                                                              ],
                                                            ),

                                                      SizedBox(
                                                        height: isCompact
                                                            ? 16.h
                                                            : 24.h,
                                                      ),
                                                      SizedBox(
                                                        height: gapBottom,
                                                      ),
                                                    ],
                                                  ),
                                                  if (isFirstStagePassedNotifier
                                                          .value &&
                                                      quest.mouthPosition !=
                                                          null) ...[
                                                    MinimalPairsMouthDiagram(
                                                      mouthPosition:
                                                          quest.mouthPosition,
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                    ),
                                                    SizedBox(height: 16.h),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            SizedBox(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isFirstStagePassedNotifier.value)
                                    SliverToBoxAdapter(
                                      child: IgnorePointer(
                                        ignoring: isAnsweredNotifier.value,
                                        child: Column(
                                          children: [
                                            SizedBox(height: 32.h),
                                            ShadowPlaybackCompare(
                                              expectedText:
                                                  _currentOptions.isNotEmpty
                                                  ? _currentOptions[_currentCorrectIndex]['word']!
                                                  : (quest.correctAnswer ??
                                                        quest.word1 ??
                                                        ""),
                                              displayText:
                                                  _currentOptions.isNotEmpty
                                                  ? _currentOptions[_currentCorrectIndex]['word']!
                                                  : (quest.correctAnswer ??
                                                        quest.word1 ??
                                                        ""),
                                              primaryColor: theme.primaryColor,
                                              isPositioned: false,
                                              onConfirmed: () {
                                                context.read<AccentBloc>().add(
                                                  const AccentSpeakConfirmed(5),
                                                );
                                                _submitVerbalEvaluation(true);
                                              },
                                              onSkipped: () =>
                                                  _submitVerbalEvaluation(
                                                    false,
                                                  ),
                                            ),
                                            SizedBox(height: 60.h),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
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

