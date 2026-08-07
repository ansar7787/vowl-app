import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_event.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';
import 'package:vowl/features/listening/presentation/layout/listening_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/widgets/audio_true_false_instruction.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/widgets/audio_true_false_tuner.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/widgets/audio_true_false_screen_display.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/widgets/audio_true_false_polarized_filters.dart';
import 'package:vowl/core/presentation/widgets/speak_to_confirm_overlay.dart';

class AudioTrueFalseScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const AudioTrueFalseScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.audioTrueFalse,
  });

  @override
  State<AudioTrueFalseScreen> createState() => _AudioTrueFalseScreenState();
}

class _AudioTrueFalseScreenState extends State<AudioTrueFalseScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  double _tuningValue = 0.5;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool? _selectedVerdict;

  @override
  void initState() {
    super.initState();
    context.read<ListeningBloc>().add(
      FetchListeningQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _submitFinalAnswer(bool nailedSpeaking, String correct) {
    if (_isAnswered) return;

    if (!nailedSpeaking) {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<ListeningBloc>().add(SubmitAnswer(false));
      return;
    }

    bool isCorrect =
        _selectedVerdict.toString().toLowerCase() ==
        correct.trim().toLowerCase();

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });
      context.read<ListeningBloc>().add(const ListeningSpeakConfirmed(5));
      context.read<ListeningBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<ListeningBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('listening', level: widget.level);

    return BlocConsumer<ListeningBloc, ListeningState>(
      listener: (context, state) {
        if (state is ListeningLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered && state.lastAnswerCorrect == null;
          final livesChanged =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _tuningValue = 0.5;
              _selectedVerdict = null;
            });
          } else if (state.lastAnswerCorrect != null && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.lastAnswerCorrect;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ListeningGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'FACT VERDICTOR!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is ListeningLoaded) ? state.currentQuest : null;

        return ListeningBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          useScrolling: false,
          onContinue: () => context.read<ListeningBloc>().add(NextQuestion()),
          onHint: () => context.read<ListeningBloc>().add(ListeningHintUsed()),
          child: quest == null
              ? const SizedBox()
              : Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final maxHeight = constraints.maxHeight;
                        final isCompact = maxHeight < 580;

                        final double estimatedContentHeight =
                            20.h +
                            40.h +
                            (isCompact ? 70.h : 90.h) +
                            (isCompact ? 130.h : 180.h) +
                            120.h +
                            20.h;
                        final remainingHeight =
                            maxHeight - estimatedContentHeight;

                        final double gapUnit = remainingHeight > 0
                            ? remainingHeight / 7
                            : 0;
                        final double gapTop = remainingHeight > 0
                            ? (gapUnit * 1).clamp(6.0, 16.0)
                            : 6.0;
                        final double gapInstruction = remainingHeight > 0
                            ? (gapUnit * 1.5).clamp(10.0, 24.0)
                            : 10.0;
                        final double gapTuner = remainingHeight > 0
                            ? (gapUnit * 1.5).clamp(10.0, 24.0)
                            : 10.0;
                        final double gapDisplay = remainingHeight > 0
                            ? (gapUnit * 1.5).clamp(10.0, 24.0)
                            : 10.0;
                        final double gapBottom = remainingHeight > 0
                            ? (gapUnit * 1.5).clamp(12.0, 30.0)
                            : 12.0;

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: maxHeight),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: gapTop),
                                    isCompact
                                        ? SizedBox(
                                            height: 35.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: AudioTrueFalseInstruction(
                                                color: theme.primaryColor,
                                                instruction: quest.instruction,
                                              ),
                                            ),
                                          )
                                        : AudioTrueFalseInstruction(
                                            color: theme.primaryColor,
                                            instruction: quest.instruction,
                                          ),
                                    SizedBox(height: gapInstruction),
                                    isCompact
                                        ? SizedBox(
                                            height: 70.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: AudioTrueFalseTuner(
                                                onTap: () {
                                                  _soundService.playTts(
                                                    quest.textToSpeak ?? "",
                                                  );
                                                  _hapticService.selection();
                                                },
                                                color: theme.primaryColor,
                                                emoji: quest.emoji,
                                                isCorrectState: _isCorrect,
                                              ),
                                            ),
                                          )
                                        : AudioTrueFalseTuner(
                                            onTap: () {
                                              _soundService.playTts(
                                                quest.textToSpeak ?? "",
                                              );
                                              _hapticService.selection();
                                            },
                                            color: theme.primaryColor,
                                            emoji: quest.emoji,
                                            isCorrectState: _isCorrect,
                                          ),
                                  ],
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: gapTuner),
                                    SizedBox(
                                      height: isCompact ? 130.h : 180.h,
                                      child: AudioTrueFalseScreenDisplay(
                                        statement: quest.statement ?? "",
                                        color: theme.primaryColor,
                                        tuningValue: _tuningValue,
                                      ),
                                    ),
                                    SizedBox(height: gapDisplay),
                                    isCompact
                                        ? SizedBox(
                                            height: 100.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: SizedBox(
                                                width: constraints.maxWidth,
                                                child: AudioTrueFalsePolarizedFilters(
                                                  tuningValue: _tuningValue,
                                                  isAnswered: _isAnswered,
                                                  isCorrectState: _isCorrect,
                                                  color: theme.primaryColor,
                                                  onChanged: (v) {
                                                    setState(
                                                      () => _tuningValue = v,
                                                    );
                                                    _hapticService.selection();
                                                  },
                                                  onChangeEnd: (v) {
                                                    if (_isAnswered ||
                                                        _selectedVerdict !=
                                                            null)
                                                      return;
                                                    if (v > 0.9) {
                                                      setState(
                                                        () => _selectedVerdict =
                                                            true,
                                                      );
                                                    }
                                                    if (v < 0.1) {
                                                      setState(
                                                        () => _selectedVerdict =
                                                            false,
                                                      );
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                          )
                                        : AudioTrueFalsePolarizedFilters(
                                            tuningValue: _tuningValue,
                                            isAnswered: _isAnswered,
                                            isCorrectState: _isCorrect,
                                            color: theme.primaryColor,
                                            onChanged: (v) {
                                              setState(() => _tuningValue = v);
                                              _hapticService.selection();
                                            },
                                            onChangeEnd: (v) {
                                              if (_isAnswered ||
                                                  _selectedVerdict != null)
                                                return;
                                              if (v > 0.9) {
                                                setState(
                                                  () => _selectedVerdict = true,
                                                );
                                              }
                                              if (v < 0.1) {
                                                setState(
                                                  () =>
                                                      _selectedVerdict = false,
                                                );
                                              }
                                            },
                                          ),
                                    SizedBox(height: gapBottom),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    if (_selectedVerdict != null && !_isAnswered)
                      SpeakToConfirmOverlay(
                        expectedText: quest.statement ?? "",
                        primaryColor: theme.primaryColor,
                        onConfirmed: () =>
                            _submitFinalAnswer(true, quest.correctAnswer ?? ""),
                        onSkipped: () => _submitFinalAnswer(
                          false,
                          quest.correctAnswer ?? "",
                        ),
                        allowSkip: true,
                      ),
                  ],
                ),
        );
      },
    );
  }
}
