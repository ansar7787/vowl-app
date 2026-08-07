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
import 'package:vowl/features/listening/audio_multiple_choice/presentation/widgets/audio_multiple_choice_instruction.dart';
import 'package:vowl/features/listening/audio_multiple_choice/presentation/widgets/audio_multiple_choice_question.dart';
import 'package:vowl/core/presentation/widgets/blind_dictation_wrapper.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AudioMultipleChoiceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const AudioMultipleChoiceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.audioMultipleChoice,
  });

  @override
  State<AudioMultipleChoiceScreen> createState() =>
      _AudioMultipleChoiceScreenState();
}

class _AudioMultipleChoiceScreenState extends State<AudioMultipleChoiceScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<ListeningBloc>().add(
      FetchListeningQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _submitFinalAnswer(bool nailedIt) {
    if (_isAnswered) return;

    if (nailedIt) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              _isAnswered = false;
              _isCorrect = null;
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
            title: 'SONIC RADAR!',
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
                            50.h +
                            (isCompact ? 150.h : 200.h) +
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
                        final double gapQuestion = remainingHeight > 0
                            ? (gapUnit * 1.5).clamp(10.0, 24.0)
                            : 10.0;
                        final double gapBottom = remainingHeight > 0
                            ? (gapUnit * 2).clamp(12.0, 100.0)
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
                                              child:
                                                  AudioMultipleChoiceInstruction(
                                                    color: theme.primaryColor,
                                                    instruction:
                                                        quest.instruction,
                                                  ),
                                            ),
                                          )
                                        : AudioMultipleChoiceInstruction(
                                            color: theme.primaryColor,
                                            instruction: quest.instruction,
                                          ),
                                    SizedBox(height: gapInstruction),
                                    isCompact
                                        ? SizedBox(
                                            height: 40.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child:
                                                  AudioMultipleChoiceQuestion(
                                                    text: quest.question ?? "",
                                                    isDark: isDark,
                                                  ),
                                            ),
                                          )
                                        : AudioMultipleChoiceQuestion(
                                            text: quest.question ?? "",
                                            isDark: isDark,
                                          ),
                                  ],
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: gapQuestion),
                                    Center(
                                      child: GestureDetector(
                                        onTap: () {
                                          _soundService.playTts(
                                            quest.textToSpeak ?? "",
                                          );
                                          _hapticService.selection();
                                        },
                                        child:
                                            Container(
                                                  width: isCompact
                                                      ? 100.r
                                                      : 140.r,
                                                  height: isCompact
                                                      ? 100.r
                                                      : 140.r,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: theme.primaryColor
                                                        .withValues(alpha: 0.1),
                                                    border: Border.all(
                                                      color: theme.primaryColor,
                                                      width: 2,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: theme
                                                            .primaryColor
                                                            .withValues(
                                                              alpha: 0.2,
                                                            ),
                                                        blurRadius: 20,
                                                        spreadRadius: 5,
                                                      ),
                                                    ],
                                                  ),
                                                  child: Icon(
                                                    Icons.volume_up_rounded,
                                                    size: isCompact
                                                        ? 50.r
                                                        : 70.r,
                                                    color: theme.primaryColor,
                                                  ),
                                                )
                                                .animate(
                                                  onPlay: (c) =>
                                                      c.repeat(reverse: true),
                                                )
                                                .scale(
                                                  begin: const Offset(
                                                    0.95,
                                                    0.95,
                                                  ),
                                                  end: const Offset(1.05, 1.05),
                                                  duration: 2.seconds,
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
                    if (!_isAnswered || _isCorrect == null)
                      BlindDictationWrapper(
                        expectedText:
                            (quest.options != null && quest.options!.isNotEmpty)
                            ? quest.options![quest.correctAnswerIndex ?? 0]
                            : "",
                        primaryColor: theme.primaryColor,
                        onConfirmed: () => _submitFinalAnswer(true),
                        onSkipped: () => _submitFinalAnswer(false),
                      ),
                  ],
                ),
        );
      },
    );
  }
}
