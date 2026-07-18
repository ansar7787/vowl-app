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
import 'package:vowl/features/listening/emotion_recognition/presentation/widgets/emotion_recognition_instruction.dart';
import 'package:vowl/features/listening/emotion_recognition/presentation/widgets/emotion_recognition_emitter.dart';
import 'package:vowl/features/listening/emotion_recognition/presentation/widgets/emotion_recognition_neural_field.dart';

class EmotionRecognitionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const EmotionRecognitionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.emotionRecognition,
  });

  @override
  State<EmotionRecognitionScreen> createState() =>
      _EmotionRecognitionScreenState();
}

class _EmotionRecognitionScreenState extends State<EmotionRecognitionScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<Offset> _coreOffset = ValueNotifier(Offset.zero);
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
    _coreOffset.dispose();
    super.dispose();
  }

  void _onCoreMove(Offset delta, BoxConstraints constraints) {
    if (_isAnswered) return;
    double nextX = (_coreOffset.value.dx + delta.dx).clamp(
      -constraints.maxWidth / 2 + 40.r,
      constraints.maxWidth / 2 - 40.r,
    );
    double nextY = (_coreOffset.value.dy + delta.dy).clamp(
      -constraints.maxHeight / 2 + 40.r,
      constraints.maxHeight / 2 - 40.r,
    );
    _coreOffset.value = Offset(nextX, nextY);
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
          final isRetry = _isAnswered && state.lastAnswerCorrect == null;
          final livesChanged =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedIndex = null;
              _coreOffset.value = Offset.zero;
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
            title: 'SENTIMENT PROBER!',
            enableDoubleUp: true,
          );
        } else 
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
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final maxHeight = constraints.maxHeight;
                    final isCompact = maxHeight < 580;

                    final double estimatedContentHeight =
                        16.h +
                        40.h +
                        (isCompact ? 60.h : 80.h) +
                        (isCompact ? 220.h : 320.h) +
                        20.h;
                    final remainingHeight = maxHeight - estimatedContentHeight;

                    final double gapUnit = remainingHeight > 0
                        ? remainingHeight / 7
                        : 0;
                    final double gapTop = remainingHeight > 0
                        ? (gapUnit * 1).clamp(6.0, 16.0)
                        : 6.0;
                    final double gapInstruction = remainingHeight > 0
                        ? (gapUnit * 1.5).clamp(8.0, 20.0)
                        : 8.0;
                    final double gapEmitter = remainingHeight > 0
                        ? (gapUnit * 1.5).clamp(8.0, 20.0)
                        : 8.0;
                    final double gapBottom = remainingHeight > 0
                        ? (gapUnit * 2).clamp(10.0, 24.0)
                        : 10.0;

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
                                          child: EmotionRecognitionInstruction(
                                            isAnswered: _isAnswered,
                                            color: theme.primaryColor,
                                            instruction: quest.instruction,
                                          ),
                                        ),
                                      )
                                    : EmotionRecognitionInstruction(
                                        isAnswered: _isAnswered,
                                        color: theme.primaryColor,
                                        instruction: quest.instruction,
                                      ),
                                SizedBox(height: gapInstruction),
                                isCompact
                                    ? SizedBox(
                                        height: 60.h,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: EmotionRecognitionEmitter(
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
                                    : EmotionRecognitionEmitter(
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
                                SizedBox(height: gapEmitter),
                                SizedBox(
                                  height: isCompact ? 220.h : 320.h,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: SizedBox(
                                      width: constraints.maxWidth,
                                      height: 350.h,
                                      child: EmotionRecognitionNeuralField(
                                        options: quest.options ?? [],
                                        correctAnswerIndex:
                                            quest.correctAnswerIndex ?? 0,
                                        color: theme.primaryColor,
                                        isAnswered: _isAnswered,
                                        isCorrectState: _isCorrect,
                                        selectedIndex: _selectedIndex,
                                        coreOffset: _coreOffset,
                                        onCoreMove: _onCoreMove,
                                        onSubmitAnswer: (index) =>
                                            _submitAnswer(
                                              index,
                                              quest.correctAnswerIndex ?? 0,
                                            ),
                                      ),
                                    ),
                                  ),
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
        );
      },
    );
  }
}
