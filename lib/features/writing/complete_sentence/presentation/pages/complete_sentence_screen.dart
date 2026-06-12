import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/writing/complete_sentence/presentation/widgets/complete_sentence_instruction.dart';
import 'package:vowl/features/writing/complete_sentence/presentation/widgets/complete_sentence_target_wall.dart';
import 'package:vowl/features/writing/complete_sentence/presentation/widgets/complete_sentence_ballista_ammo.dart';
import 'package:vowl/features/writing/complete_sentence/presentation/widgets/complete_sentence_explanation_card.dart';
import 'package:vowl/features/writing/complete_sentence/presentation/widgets/complete_sentence_trajectory_painter.dart';

class CompleteSentenceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const CompleteSentenceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.completeSentence,
  });

  @override
  State<CompleteSentenceScreen> createState() => _CompleteSentenceScreenState();
}

class _CompleteSentenceScreenState extends State<CompleteSentenceScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  Offset? _dragStart;
  Offset? _dragCurrent;
  String? _selectedProjectile;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(
      FetchWritingQuests(gameType: widget.gameType, level: widget.level),
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

  void _onFire(String selected, String correct) {
    if (_isAnswered) return;
    bool isCorrect =
        selected.trim().toLowerCase() == correct.trim().toLowerCase();

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
        _selectedProjectile = selected;
      });
      context.read<WritingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<WritingBloc>().add(SubmitAnswer(false));
      Future.delayed(1.seconds, () {
        if (mounted) {
          setState(() {
            _dragStart = null;
            _dragCurrent = null;
            _selectedProjectile = null;
            _isAnswered = false;
            _isCorrect = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('writing', level: widget.level);

    return BlocConsumer<WritingBloc, WritingState>(
      listener: (context, state) {
        if (state is WritingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex ||
              livesChanged ||
              (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedProjectile = null;
              _dragStart = null;
              _dragCurrent = null;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'COMPLETION MASTER!',
            enableDoubleUp: true,
          );
        } else if (state is WritingGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<WritingBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final quest = (state is WritingLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? [];

        return WritingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<WritingBloc>().add(NextQuestion()),
          onHint: () => context.read<WritingBloc>().add(WritingHintUsed()),
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
                            CompleteSentenceInstruction(
                              primaryColor: theme.primaryColor,
                            ),
                            SizedBox(height: 32.h),

                            CompleteSentenceTargetWall(
                              text: quest.partialSentence ?? "",
                              injected: _selectedProjectile,
                              color: theme.primaryColor,
                              isDark: isDark,
                              onFire: _onFire,
                            ),
                            SizedBox(height: 32.h),

                            CompleteSentenceBallistaAmmo(
                              options: options,
                              correct: quest.correctAnswer ?? "",
                              color: theme.primaryColor,
                              isDark: isDark,
                              onBridgeStart: _onBridgeStart,
                              onBridgeUpdate: _onBridgeUpdate,
                              onFire: _onFire,
                            ),

                            if (_isAnswered) ...[
                              SizedBox(height: 30.h),
                              CompleteSentenceExplanationCard(
                                quest: quest,
                                isCorrect: _isCorrect == true,
                                primaryColor: theme.primaryColor,
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
                          painter: CompleteSentenceTrajectoryPainter(
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
