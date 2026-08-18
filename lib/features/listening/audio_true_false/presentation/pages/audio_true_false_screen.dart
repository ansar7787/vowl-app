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
          final isRetry = _isAnswered && !state.answerStatus.isAnswered;
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
          } else if (state.answerStatus.isAnswered && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
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
                    CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: 6.h),
                                AudioTrueFalseInstruction(
                                  color: theme.primaryColor,
                                  instruction: quest.instruction,
                                ),
                                SizedBox(height: 24.h),
                                AudioTrueFalseTuner(
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
                                SizedBox(height: 32.h),
                                SizedBox(
                                  height: 180.h,
                                  child: AudioTrueFalseScreenDisplay(
                                    statement: quest.statement ?? "",
                                    color: theme.primaryColor,
                                    tuningValue: _tuningValue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 16.h,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                AudioTrueFalsePolarizedFilters(
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
                                        _selectedVerdict != null) {
                                      return;
                                    }
                                    if (v > 0.9) {
                                      setState(
                                        () => _selectedVerdict = true,
                                      );
                                    }
                                    if (v < 0.1) {
                                      setState(
                                        () => _selectedVerdict = false,
                                      );
                                    }
                                  },
                                ),
                                SizedBox(height: 100.h), // Spacing for SpeakToConfirmOverlay
                              ],
                            ),
                          ),
                        ),
                      ],
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
