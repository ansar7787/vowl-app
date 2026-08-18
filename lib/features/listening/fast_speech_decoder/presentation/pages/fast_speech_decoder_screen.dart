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
import 'package:vowl/features/listening/fast_speech_decoder/presentation/widgets/fast_speech_decoder_instruction.dart';
import 'package:vowl/features/listening/fast_speech_decoder/presentation/widgets/fast_speech_decoder_gauges.dart';
import 'package:vowl/features/listening/fast_speech_decoder/presentation/widgets/fast_speech_decoder_core.dart';
import 'package:vowl/features/listening/fast_speech_decoder/presentation/widgets/fast_speech_decoder_steam_vents.dart';

class FastSpeechDecoderScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const FastSpeechDecoderScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.fastSpeechDecoder,
  });

  @override
  State<FastSpeechDecoderScreen> createState() =>
      _FastSpeechDecoderScreenState();
}

class _FastSpeechDecoderScreenState extends State<FastSpeechDecoderScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<double> _dialRotation = ValueNotifier(
    0.33,
  ); // 0.0 to 1.0 mapping to 0.5x - 2.0x
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    context.read<ListeningBloc>().add(
      FetchListeningQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _dialRotation.dispose();
    super.dispose();
  }

  void _onRotate(double delta) {
    if (_isAnswered) return;
    double oldVal = _dialRotation.value;
    _dialRotation.value = (_dialRotation.value + delta / 300).clamp(0.0, 1.0);

    // Haptic tick for every 0.1x change
    if ((oldVal * 10).floor() != (_dialRotation.value * 10).floor()) {
      _hapticService.light();
    }
  }

  void _submitAnswer(int index, int correct) {
    if (_isAnswered) return;
    setState(() => _selectedIndex = index);
    bool isCorrect = index == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });
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
              _selectedIndex = null;
              _dialRotation.value = 0.33;
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
            title: 'NUANCE DECODER!',
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
              : CustomScrollView(
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
                              FastSpeechDecoderInstruction(
                                color: theme.primaryColor,
                                instruction: quest.instruction,
                              ),
                              SizedBox(height: 24.h),
                              ValueListenableBuilder<double>(
                                valueListenable: _dialRotation,
                                builder: (context, rotation, _) {
                                  double speed = 0.3 + (rotation * 0.6);
                                  return Column(
                                    children: [
                                      FastSpeechDecoderGauges(
                                        speed: speed * 2,
                                        color: theme.primaryColor,
                                      ),
                                      SizedBox(height: 20.h),
                                      FastSpeechDecoderCore(
                                        textToSpeak: quest.textToSpeak ?? "",
                                        speed: speed,
                                        color: theme.primaryColor,
                                        rotation: rotation,
                                        onRotate: _onRotate,
                                        onTapTts: () {
                                          _soundService.playTts(
                                            quest.textToSpeak ?? "",
                                            speed: speed,
                                          );
                                          _hapticService.selection();
                                        },
                                        emoji: quest.emoji,
                                        isCorrectState: _isCorrect,
                                      ),
                                    ],
                                  );
                                },
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
                              FastSpeechDecoderSteamVents(
                                options: quest.options ?? [],
                                correctAnswerIndex:
                                    quest.correctAnswerIndex ?? 0,
                                color: theme.primaryColor,
                                isAnswered: _isAnswered,
                                isCorrectState: _isCorrect,
                                selectedIndex: _selectedIndex,
                                onSubmitAnswer: (index) => _submitAnswer(
                                  index,
                                  quest.correctAnswerIndex ?? 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
        );
      },
    );
  }
}
