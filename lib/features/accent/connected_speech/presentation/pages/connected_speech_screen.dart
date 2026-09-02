import 'dart:async';
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
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/layout/accent_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/connected_speech/presentation/widgets/connected_speech_instruction.dart';
import 'package:vowl/features/accent/connected_speech/presentation/widgets/connected_speech_prompt_card.dart';
import 'package:vowl/features/accent/connected_speech/presentation/widgets/connected_speech_pulse_speaker.dart';
import 'package:vowl/features/accent/connected_speech/presentation/widgets/connected_speech_linker_cards.dart';
import 'package:vowl/core/presentation/game_mechanics/shadow_playback_compare.dart';

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

class _ConnectedSpeechScreenState extends State<ConnectedSpeechScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  int _lastLives = 3;
  AccentQuest? _lastQuest;
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);

  List<String> _shuffledOptions = [];
  int _shuffledCorrectIndex = 0;

  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);
  Timer? _resetTimer;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    context.read<AccentBloc>().add(
      FetchAccentQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _selectedIndex.dispose();
    _isFirstStagePassed.dispose();
    _resetTimer?.cancel();
    super.dispose();
  }

  void _playTts(String text) {
    _hapticService.selection();
    _soundService.playTts(text);
  }

  void _submitChoice(int index, int correct) {
    if (_isAnswered.value || _isFirstStagePassed.value) return;
    _selectedIndex.value = index;

    final bool isCorrect = index == correct;

    if (isCorrect) {
      _hapticService.selection();
      _isFirstStagePassed.value = true;
      // Wait for Phase 2
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered.value) return;

    _isAnswered.value = true;
    _isCorrect.value = nailedIt;

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<AccentBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('accent', level: widget.level);

    return BlocConsumer<AccentBloc, AccentState>(
      listener: (context, state) {
        if (state is AccentLoaded) {
          _lastQuest = state.currentQuest;
          final livesChanged = (state.livesRemaining > _lastLives);
          if (state.currentIndex != _lastProcessedIndex ||
              livesChanged ||
              (!state.answerStatus.isAnswered && _isAnswered.value)) {
            _resetTimer?.cancel();

            final quest = state.currentQuest;
            final originalOptions = quest.options ?? [];
            final originalCorrectIndex = quest.correctAnswerIndex ?? 0;
            final originalCorrectAnswer =
                originalOptions.isNotEmpty &&
                    originalCorrectIndex < originalOptions.length
                ? originalOptions[originalCorrectIndex]
                : "";

            _shuffledOptions = List.from(originalOptions)..shuffle();
            _shuffledCorrectIndex = _shuffledOptions.indexOf(
              originalCorrectAnswer,
            );
            if (_shuffledCorrectIndex == -1) _shuffledCorrectIndex = 0;

            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;

            _selectedIndex.value = null;
            _isFirstStagePassed.value = false;
            // Proactively auto-play sound on question load
            if (quest.textToSpeak != null) {
              Future.delayed(500.milliseconds, () {
                if (mounted) {
                  _soundService.playTts(quest.textToSpeak!);
                }
              });
            }
          }
          _lastLives = state.livesRemaining;
        }
        if (state is AccentGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'FLUENCY FLOW!',
            enableDoubleUp: true,
          );
        }
      },
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
            listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _selectedIndex, _isFirstStagePassed]),
            builder: (context, _) {
              return AccentBaseLayout(
            gameType: widget.gameType,
            level: widget.level,
            isAnswered: _isAnswered.value,
            isCorrect: _isCorrect.value,
            showConfetti: _showConfetti.value,
            onContinue: () =>
                context.read<AccentBloc>().add(NextQuestion()),
            onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
            useScrolling: false,
            child: quest == null
                ? const SizedBox()
                : Stack(
                        children: [
                          LayoutBuilder(
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
                            thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                            radius: Radius.circular(8.r),
                            thickness: 4.w,
                            child: CustomScrollView(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              slivers: [
                                SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: Column(
                                    children: [
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 24.w,
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(height: gapTop),
                                                ConnectedSpeechInstruction(
                                                  primaryColor: theme.primaryColor,
                                                  instruction: _isFirstStagePassed.value
                                                      ? "Great job! Now confirm by speaking the phrase."
                                                      : context.tr(
                                                          'games.connected_speech_instruction',
                                                          fallback:
                                                              "SELECT THE CORRECT SOUND CHANGE",
                                                        ),
                                                  isCompact: isCompact,
                                                ),
                                                SizedBox(height: gapInstruction),

                                                ConnectedSpeechPromptCard(
                                                  word: quest.word ?? "",
                                                  spokenForm: quest.spokenForm,
                                                  phenomenonType: quest.phenomenonType,
                                                  isAnswered: _isFirstStagePassed.value || _isAnswered.value,
                                                  color: theme.primaryColor,
                                                  isDark: isDark,
                                                  isCompact: isCompact,
                                                ),
                                                SizedBox(height: gapPrompt),

                                                ConnectedSpeechPulseSpeaker(
                                                  text: quest.textToSpeak ?? "",
                                                  color: theme.primaryColor,
                                                  onPlayTts: _playTts,
                                                ),
                                              ],
                                            ),
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(height: gapSpeaker),
                                                ConnectedSpeechLinkerCards(
                                                  key: ValueKey(quest.id),
                                                  options: options,
                                                  correctIndex:
                                                      _shuffledOptions.isNotEmpty
                                                      ? _shuffledCorrectIndex
                                                      : (quest.correctAnswerIndex ??
                                                            0),
                                                  color: theme.primaryColor,
                                                  isDark: isDark,
                                                  isAnswered:
                                                      _isAnswered.value ||
                                                      _isFirstStagePassed.value,
                                                  selectedIndex: _selectedIndex.value,
                                                  onSubmitChoice: _submitChoice,
                                                  isCompact: isCompact,
                                                ),
                                                SizedBox(height: gapBottom),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: (_isFirstStagePassed.value && !_isAnswered.value) ? 380.h : 160.h),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          );
                        },
                      ),
                          if (_isFirstStagePassed.value && !_isAnswered.value)
                            ShadowPlaybackCompare(
                              expectedText: quest.textToSpeak ?? quest.word ?? "",
                              primaryColor: theme.primaryColor,
                              isPositioned: true,
                              onConfirmed: () {
                                context.read<AccentBloc>().add(
                                  const AccentSpeakConfirmed(5),
                                );
                                _submitVerbalEvaluation(true);
                              },
                              onSkipped: () => _submitVerbalEvaluation(
                                false,
                              ),
                            ),
                        ],
                      );
              );
            },
          ),
        );
      },
    );
  }
}
