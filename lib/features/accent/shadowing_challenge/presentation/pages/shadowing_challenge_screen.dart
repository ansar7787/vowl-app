import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/constants/accent_game_constants.dart';
import 'package:vowl/features/accent/presentation/layout/accent_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/widgets/shadowing_challenge_instruction.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/widgets/shadowing_challenge_prompt_card.dart';

import 'package:vowl/features/accent/shadowing_challenge/presentation/widgets/shadowing_challenge_pulse_speaker.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/widgets/shadowing_challenge_dialogue_list.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/widgets/shadowing_challenge_speed_slider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/game_mechanics/shadow_playback_compare.dart';

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

class _ShadowingChallengeScreenState extends State<ShadowingChallengeScreen> {
  final ScrollController _scrollController = ScrollController();
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  int _lastLives = AccentGameConstants.maxLives;
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);

  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);
  final ValueNotifier<double> _currentSpeed = ValueNotifier(1.0);

  @override
  void initState() {
    super.initState();
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
    _currentSpeed.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
    _hapticService.selection();
    // Assuming base speed is around 0.4. We'll adjust it by _currentSpeed.
    _soundService.playTts(text, speed: 0.4 * _currentSpeed.value);
  }

  void _submitChoice(int index, int correct) {
    if (_isAnswered.value || _isFirstStagePassed.value) return;
    _selectedIndex.value = index;

    bool isCorrect = index == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      _isFirstStagePassed.value = true;
      _scrollToBottom();
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
      context.read<AccentBloc>().add(const AccentSpeakConfirmed(5));
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
          final livesChanged = (state.livesRemaining > _lastLives);
          if (state.currentIndex != _lastProcessedIndex ||
              livesChanged ||
              (!state.answerStatus.isAnswered && _isAnswered.value)) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _isFirstStagePassed.value = false;
            _selectedIndex.value = null;
            // Proactively auto-play sound on question load
            final quest = state.currentQuest as AccentQuest?;
            if (quest != null) {
              _currentSpeed.value = quest.speedLevel ?? 1.0;
              if (quest.textToSpeak != null) {
                Future.delayed(500.milliseconds, () {
                  if (mounted) {
                    _playTts(quest.textToSpeak!);
                  }
                });
              }
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
            title: 'SHADOW GHOST!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final AccentQuest? quest = (state is AccentLoaded)
            ? state.currentQuest as AccentQuest?
            : null;
        final rawOptions = quest?.options ?? ["A", "B"];
        final options = List<String>.from(rawOptions)
          ..shuffle(Random(quest?.id.hashCode ?? 0));

        final correctIndex = quest?.correctAnswer != null
            ? options.indexOf(quest!.correctAnswer!)
            : (quest?.correctAnswerIndex ?? 0);
        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _selectedIndex, _isFirstStagePassed, _currentSpeed]),
            builder: (context, _) {
              return AccentBaseLayout(
            gameType: widget.gameType,
            level: widget.level,
            isAnswered: _isAnswered.value,
            isCorrect: _isCorrect.value,
            showConfetti: _showConfetti.value,
            onContinue: () => context.read<AccentBloc>().add(NextQuestion()),
            onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
            useScrolling: false,
            child: quest == null
                ? const SizedBox()
                : Stack(
                    children: [
                      LayoutBuilder(
                    builder: (context, constraints) {

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
                                      vertical: 24.h,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        ShadowingChallengeInstruction(
                                          color: theme.primaryColor,
                                          instruction: _isFirstStagePassed.value
                                              ? "Great job! Now record yourself saying the phrase."
                                              : context.tr(
                                                  'games.shadowing_challenge_instruction',
                                                  fallback: quest.instruction,
                                                ),
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
                                              _isAnswered.value || _isFirstStagePassed.value,
                                          selectedIndex: _selectedIndex.value,
                                          onSubmitChoice: _submitChoice,
                                        ),
                                        SizedBox(height: 24.h),
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
                          expectedText: quest.textToSpeak ?? "",
                          displayText: quest.textToSpeak ?? "",
                          primaryColor: theme.primaryColor,
                          isPositioned: true,
                          speedMultiplier: _currentSpeed.value,
                          onConfirmed: () => _submitVerbalEvaluation(true),
                          onSkipped: () => _submitVerbalEvaluation(false),
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
