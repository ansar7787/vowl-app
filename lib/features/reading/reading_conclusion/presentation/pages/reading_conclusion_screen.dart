import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/layout/reading_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/reading_conclusion/presentation/widgets/reading_conclusion_instruction.dart';
import 'package:vowl/features/reading/reading_conclusion/presentation/widgets/reading_conclusion_passage.dart';
import 'package:vowl/features/reading/reading_conclusion/presentation/widgets/reading_conclusion_terminals.dart';
import 'package:vowl/features/reading/reading_conclusion/presentation/widgets/reading_conclusion_result.dart';
import 'package:vowl/features/reading/reading_conclusion/presentation/widgets/reading_conclusion_bridge_painter.dart';

class ReadingConclusionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ReadingConclusionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.readingConclusion,
  });

  @override
  State<ReadingConclusionScreen> createState() =>
      _ReadingConclusionScreenState();
}

class _ReadingConclusionScreenState extends State<ReadingConclusionScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  Offset? _dragStart;
  Offset? _dragCurrent;
  int? _selectedIndex;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(
      FetchReadingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onBridgeStart(Offset globalPosition) {
    if (_isAnswered) return;
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final localPos = renderBox.globalToLocal(globalPosition);
      setState(() {
        _dragStart = localPos;
        _dragCurrent = localPos;
        _hapticService.selection();
      });
    }
  }

  void _onBridgeUpdate(Offset globalPosition) {
    if (_isAnswered || _dragStart == null) return;
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      setState(() {
        _dragCurrent = renderBox.globalToLocal(globalPosition);
      });
    }
  }

  void _onBridgeEnd(int index, String selected, String correct) {
    if (_isAnswered) return;
    _submitAnswer(index, selected, correct);
  }

  void _submitAnswer(int index, String selected, String correct) {
    setState(() => _selectedIndex = index);
    bool isCorrect =
        selected.trim().toLowerCase() == correct.trim().toLowerCase();

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });
      context.read<ReadingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<ReadingBloc>().add(SubmitAnswer(false));
      Future.delayed(1.seconds, () {
        if (mounted) {
          setState(() {
            _dragStart = null;
            _dragCurrent = null;
            _selectedIndex = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);

    return BlocConsumer<ReadingBloc, ReadingState>(
      listener: (context, state) {
        if (state is ReadingLoaded) {
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
              _dragStart = null;
              _dragCurrent = null;
            });
          } else if (state.lastAnswerCorrect != null && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.lastAnswerCorrect;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ReadingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'FINAL VERDICT DELIVERED!',
            enableDoubleUp: true,
          );
        } else if (state is ReadingGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<ReadingBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final ReadingQuest? quest = (state is ReadingLoaded)
            ? state.currentQuest as ReadingQuest?
            : null;

        return ReadingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<ReadingBloc>().add(NextQuestion()),
          onHint: () => context.read<ReadingBloc>().add(ReadingHintUsed()),
          child: quest == null
              ? const SizedBox()
              : Stack(
                  children: [
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          children: [
                            SizedBox(height: 16.h),
                            ReadingConclusionInstruction(
                              primaryColor: theme.primaryColor,
                            ),
                            SizedBox(height: 32.h),

                            ReadingConclusionPassage(
                              passage: quest.passage ?? "",
                              color: theme.primaryColor,
                              isDark: isDark,
                              onDragStart: _onBridgeStart,
                              onDragUpdate: _onBridgeUpdate,
                            ),
                            SizedBox(height: 32.h),

                            ReadingConclusionTerminals(
                              options: quest.options ?? [],
                              correct: quest.correctAnswer ?? "",
                              color: theme.primaryColor,
                              isDark: isDark,
                              selectedIndex: _selectedIndex,
                              isAnswered: _isAnswered,
                              onBridgeEnd: (idx, opt) => _onBridgeEnd(
                                idx,
                                opt,
                                quest.correctAnswer ?? "",
                              ),
                              onSubmitTap: (idx, opt) => _submitAnswer(
                                idx,
                                opt,
                                quest.correctAnswer ?? "",
                              ),
                            ),

                            if (_isAnswered) ...[
                              SizedBox(height: 30.h),
                              ReadingConclusionResult(
                                quest: quest,
                                isCorrect: _isCorrect == true,
                                isDark: isDark,
                              ),
                            ],
                            SizedBox(height: 60.h),
                          ],
                        ),
                      ),
                    ),
                    if (_dragStart != null && _dragCurrent != null)
                      IgnorePointer(
                        child: CustomPaint(
                          painter: BridgePainter(
                            start: _dragStart!,
                            end: _dragCurrent!,
                            color: theme.primaryColor,
                          ),
                          size: Size.infinite,
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}
