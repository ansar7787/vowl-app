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
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/features/listening/audio_sentence_order/presentation/widgets/audio_sentence_order_instruction.dart';
import 'package:vowl/features/listening/audio_sentence_order/presentation/widgets/audio_sentence_order_oscilloscope.dart';
import 'package:vowl/features/listening/audio_sentence_order/presentation/widgets/audio_sentence_order_timeline.dart';
import 'package:vowl/features/listening/audio_sentence_order/presentation/widgets/audio_sentence_order_segments.dart';

class AudioSentenceOrderScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const AudioSentenceOrderScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.audioSentenceOrder,
  });

  @override
  State<AudioSentenceOrderScreen> createState() =>
      _AudioSentenceOrderScreenState();
}

class _AudioSentenceOrderScreenState extends State<AudioSentenceOrderScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  List<String> _slots = [];
  List<String> _segments = [];
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

  void _onSnap(String segment, int slotIndex) {
    if (_isAnswered) return;
    setState(() {
      _slots[slotIndex] = segment;
      _segments.remove(segment);
      _hapticService.selection();
    });
  }

  void _onUnsnap(int slotIndex) {
    if (_isAnswered) return;
    setState(() {
      String segment = _slots[slotIndex];
      if (segment.isNotEmpty) {
        _segments.add(segment);
        _slots[slotIndex] = "";
        _hapticService.selection();
      }
    });
  }

  void _submitAnswer(String correctFull) {
    if (_isAnswered) return;

    if (_segments.isNotEmpty) {
      CustomSnackBar.show(
        context: context,
        message: "Please place all segments in the timeline!",
        type: CustomSnackBarType.warning,
      );
      _hapticService.selection();
      return;
    }

    String current = _slots
        .join(" ")
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
    String target = correctFull
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
    bool isCorrect = current == target;

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
              _segments = List.from(state.currentQuest.shuffledSentences ?? []);
              _slots = List.generate(_segments.length, (_) => "");
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
            title: 'SEQUENCE MASTER!',
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
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final maxHeight = constraints.maxHeight;
                    final isCompact = maxHeight < 580;

                    final double estimatedContentHeight =
                        20.h +
                        40.h +
                        (isCompact ? 80.h : 110.h) +
                        (isCompact ? 130.h : 180.h) +
                        (isCompact ? 130.h : 180.h) +
                        (_isAnswered ? 0.h : 60.h) +
                        20.h;
                    final remainingHeight = maxHeight - estimatedContentHeight;

                    final double gapUnit = remainingHeight > 0
                        ? remainingHeight / 8
                        : 0;
                    final double gapTop = remainingHeight > 0
                        ? (gapUnit * 1).clamp(6.0, 16.0)
                        : 6.0;
                    final double gapInstruction = remainingHeight > 0
                        ? (gapUnit * 1.5).clamp(8.0, 20.0)
                        : 8.0;
                    final double gapOscilloscope = remainingHeight > 0
                        ? (gapUnit * 1.5).clamp(8.0, 20.0)
                        : 8.0;
                    final double gapTimeline = remainingHeight > 0
                        ? (gapUnit * 1.5).clamp(8.0, 20.0)
                        : 8.0;
                    final double gapSegments = remainingHeight > 0
                        ? (gapUnit * 1.5).clamp(8.0, 20.0)
                        : 8.0;
                    final double gapBottom = remainingHeight > 0
                        ? (gapUnit * 1).clamp(8.0, 24.0)
                        : 8.0;

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
                                          child: AudioSentenceOrderInstruction(
                                            color: theme.primaryColor,
                                            instruction: quest.instruction,
                                          ),
                                        ),
                                      )
                                    : AudioSentenceOrderInstruction(
                                        color: theme.primaryColor,
                                        instruction: quest.instruction,
                                      ),
                                SizedBox(height: gapInstruction),
                                isCompact
                                    ? SizedBox(
                                        height: 80.h,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: AudioSentenceOrderOscilloscope(
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
                                    : AudioSentenceOrderOscilloscope(
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
                                SizedBox(height: gapOscilloscope),
                                SizedBox(
                                  height: isCompact ? 130.h : 180.h,
                                  child: SingleChildScrollView(
                                    clipBehavior: Clip.none,
                                    physics: const BouncingScrollPhysics(),
                                    child: AudioSentenceOrderTimeline(
                                      slots: _slots,
                                      color: theme.primaryColor,
                                      onSnap: _onSnap,
                                      onUnsnap: _onUnsnap,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: gapTimeline),
                                SizedBox(
                                  height: isCompact ? 130.h : 180.h,
                                  child: SingleChildScrollView(
                                    clipBehavior: Clip.none,
                                    physics: const BouncingScrollPhysics(),
                                    child: AudioSentenceOrderSegments(
                                      segments: _segments,
                                      slots: _slots,
                                      color: theme.primaryColor,
                                      isAnswered: _isAnswered,
                                      onSnap: _onSnap,
                                    ),
                                  ),
                                ),
                                SizedBox(height: gapSegments),
                                if (!_isAnswered)
                                  ScaleButton(
                                    onTap: () =>
                                        _submitAnswer(quest.textToSpeak ?? ""),
                                    child: Container(
                                      width: double.infinity,
                                      height: isCompact ? 50.h : 65.h,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          20.r,
                                        ),
                                        color: theme.primaryColor,
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.primaryColor
                                                .withValues(alpha: 0.3),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          "CALIBRATE SIGNAL",
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 2,
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
