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
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/layout/accent_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/connected_speech/presentation/widgets/connected_speech_instruction.dart';
import 'package:vowl/features/accent/connected_speech/presentation/widgets/connected_speech_prompt_card.dart';
import 'package:vowl/features/accent/connected_speech/presentation/widgets/connected_speech_pulse_speaker.dart';
import 'package:vowl/features/accent/connected_speech/presentation/widgets/connected_speech_linker_cards.dart';
import 'package:vowl/features/accent/connected_speech/presentation/widgets/connected_speech_explanation_card.dart';

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
  int? _lastLives;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;

  int? _selectedIndex;
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(
      FetchAccentQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _playTts(String text) {
    _hapticService.selection();
    _soundService.playTts(text);
  }

  void _submitChoice(int index, int correct) {
    if (_isAnswered) return;
    setState(() {
      _selectedIndex = index;
    });

    final bool isCorrect = index == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });
      context.read<AccentBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
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
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex ||
              livesChanged ||
              (state.lastAnswerCorrect == null && _isAnswered)) {
            _resetTimer?.cancel();
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;

              _selectedIndex = null;
            });
            // Proactively auto-play sound on question load
            final quest = state.currentQuest as AccentQuest?;
            if (quest != null && quest.textToSpeak != null) {
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
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'FLUENCY FLOW!',
            enableDoubleUp: true,
          );
        } else if (state is AccentGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<AccentBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final AccentQuest? quest = (state is AccentLoaded)
            ? state.currentQuest as AccentQuest?
            : null;
        final options = quest?.options ?? ["A", "B"];
        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: AccentBaseLayout(
            gameType: widget.gameType,
            level: widget.level,
            isAnswered: _isAnswered,
            isCorrect: _isCorrect,
            showConfetti: _showConfetti,
            onContinue: () => context.read<AccentBloc>().add(NextQuestion()),
            onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
            child: quest == null
                ? const SizedBox()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final maxHeight = constraints.maxHeight;
                      final bool isCompact = maxHeight < 580;

                      // Estimated content height in ScreenUtil units
                      final double estimatedContentHeight =
                          24.h +
                          (isCompact ? 90.h : 120.h) +
                          100.h +
                          (isCompact ? 130.h : 172.h) +
                          (_isAnswered ? (isCompact ? 110.h : 160.h) : 0);
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
                      final double gapSlider = remainingHeight > 0
                          ? (gapUnit * 1.5).clamp(12.0, 40.0)
                          : 12.0;
                      final double gapBottom = remainingHeight > 0
                          ? (gapUnit * 1).clamp(12.0, 40.0)
                          : 12.0;

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: maxHeight),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: gapTop),
                                    ConnectedSpeechInstruction(
                                      primaryColor: theme.primaryColor,
                                      instruction: quest.instruction,
                                      isCompact: isCompact,
                                    ),
                                    SizedBox(height: gapInstruction),

                                    ConnectedSpeechPromptCard(
                                      word: quest.word ?? "",
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
                                          quest.correctAnswerIndex ?? 0,
                                      color: theme.primaryColor,
                                      isDark: isDark,
                                      isAnswered: _isAnswered,
                                      selectedIndex: _selectedIndex,
                                      onSubmitChoice: _submitChoice,
                                      isCompact: isCompact,
                                    ),
                                    if (_isAnswered) ...[
                                      SizedBox(height: gapSlider),
                                      ConnectedSpeechExplanationCard(
                                        quest: quest,
                                        color: theme.primaryColor,
                                        isDark: isDark,
                                        isCorrect: _isCorrect,
                                        isCompact: isCompact,
                                      ),
                                    ],
                                    SizedBox(height: gapBottom),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
