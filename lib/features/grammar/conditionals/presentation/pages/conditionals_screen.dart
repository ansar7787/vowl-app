import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/conditionals/presentation/widgets/conditionals_instruction.dart';
import 'package:vowl/core/presentation/widgets/type_to_confirm_overlay.dart';
import 'package:vowl/features/grammar/conditionals/presentation/widgets/conditionals_chain_painter.dart';
import 'package:vowl/core/utils/locale_service.dart';

class ConditionalsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ConditionalsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.conditionals,
  });

  @override
  State<ConditionalsScreen> createState() => _ConditionalsScreenState();
}

class _ConditionalsScreenState extends State<ConditionalsScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  List<Offset> _chainPoints = [];
  int _targetIndex = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  bool _isFirstStagePassed = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(
      FetchGrammarQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onConnect(int nodeIndex, int correctIndex) {
    if (_isAnswered || _isFirstStagePassed) return;

    bool isCorrect = nodeIndex == correctIndex;

    if (isCorrect) {
      _hapticService.heavy();
      _soundService.playCorrect();
      setState(() {
        _isFirstStagePassed = true;
        _targetIndex = nodeIndex;
      });
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _targetIndex = nodeIndex;
      });
      context.read<GrammarBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered) return;
    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
    });
    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<GrammarBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<GrammarBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listener: (context, state) {
        if (state is GrammarLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered && !state.answerStatus.isAnswered;
          final livesRestored =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesRestored) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isFirstStagePassed = false;
            });
          } else if (state.answerStatus.isAnswered && !_isAnswered) {
            // FIX: was `state.lastAnswerCorrect != null` and `state.lastAnswerCorrect`
            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'LOGIC LORD!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final GrammarQuest? quest = (state is GrammarLoaded)
            ? state.currentQuest
            : null;
        final options = quest?.options ?? ["RESULT A", "RESULT B", "RESULT C"];

        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,
          onContinue: () => context.read<GrammarBloc>().add(NextQuestion()),
          onHint: () => context.read<GrammarBloc>().add(GrammarHintUsed()),
          child: quest == null
              ? const SizedBox()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final maxHeight = constraints.maxHeight;
                    final isCompact = maxHeight < 580;

                    final double estimatedContentHeight =
                        (isCompact ? 30.h : 40.h) +
                        (isCompact ? 70.h : 100.h) +
                        (_isAnswered ? (isCompact ? 50.h : 90.h) : 0) +
                        40.h;
                    final remainingHeight = maxHeight - estimatedContentHeight;

                    final double gapUnit = remainingHeight > 0
                        ? remainingHeight / 5
                        : 0;
                    final double gapTop = remainingHeight > 0
                        ? (gapUnit * 1).clamp(4.0, 15.0)
                        : 4.0;
                    final double gapMiddle = remainingHeight > 0
                        ? (gapUnit * 1.5).clamp(6.0, 20.0)
                        : 6.0;
                    final double gapBottom = remainingHeight > 0
                        ? (gapUnit * 2.5).clamp(10.0, 30.0)
                        : 10.0;

                    return Stack(
                      children: [
                        Column(
                          children: [
                            SizedBox(height: gapTop),
                            isCompact
                                ? SizedBox(
                                    height: 25.h,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: ConditionalsInstruction(
                                        primaryColor: theme.primaryColor,
                                      ),
                                    ),
                                  )
                                : ConditionalsInstruction(
                                    primaryColor: theme.primaryColor,
                                  ),
                            SizedBox(height: gapMiddle),

                            // Context Card
                            Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24.w,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.all(
                                      isCompact ? 12.r : 22.r,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.black.withValues(
                                              alpha: 0.03,
                                            ),
                                      borderRadius: BorderRadius.circular(24.r),
                                      border: Border.all(
                                        color: theme.primaryColor.withValues(
                                          alpha: 0.15,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          "IF CONDITION",
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: isCompact ? 8.sp : 10.sp,
                                            fontWeight: FontWeight.w900,
                                            color: theme.primaryColor,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                        SizedBox(
                                          height: isCompact ? 6.h : 12.h,
                                        ),
                                        Text(
                                          quest.question ?? "",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: isCompact ? 16.sp : 20.sp,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                            height: 1.4,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 600.ms)
                                .slideY(begin: 0.2, end: 0),

                            // Result
                            if (_isAnswered) ...[
                              SizedBox(height: gapMiddle),
                              _buildResult(
                                quest,
                                theme.primaryColor,
                                isDark,
                                isCompact,
                              ),
                            ],

                            // Chain Arena
                            Expanded(
                              child: _buildChainArena(
                                options,
                                quest.correctAnswerIndex ?? 0,
                                theme.primaryColor,
                                isDark,
                                isCompact,
                              ),
                            ),

                            SizedBox(height: gapBottom),
                          ],
                        ),
                        if (_isFirstStagePassed && !_isAnswered)
                          TypeToConfirmOverlay(
                            expectedText: options[_targetIndex],
                            primaryColor: theme.primaryColor,
                            onConfirmed: () => _submitVerbalEvaluation(true),
                            onSkipped: () => _submitVerbalEvaluation(false),
                          ),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildChainArena(
    List<String> options,
    int correctIndex,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final startPoint = Offset(
          constraints.maxWidth / 2,
          isCompact ? 10.h : 20.h,
        );
        final double verticalSpace =
            (constraints.maxHeight - (isCompact ? 60.h : 120.h)).clamp(
              50.0,
              450.0,
            );
        final nodePoints = List.generate(options.length, (i) {
          return Offset(
            constraints.maxWidth / 2,
            (isCompact ? 40.h : 80.h) +
                (i * verticalSpace / (options.length - 1)),
          );
        });

        return GestureDetector(
          onPanUpdate: (details) {
            if (_isAnswered || _isFirstStagePassed) return;
            setState(() {
              _chainPoints.add(details.localPosition);
              _hapticService.selection();
            });
            for (int i = 0; i < nodePoints.length; i++) {
              if ((details.localPosition - nodePoints[i]).distance <
                  (isCompact ? 40.r : 60.r)) {
                _onConnect(i, correctIndex);
              }
            }
          },
          onPanEnd: (_) => setState(() => _chainPoints = []),
          child: CustomPaint(
            size: Size.infinite,
            painter: ConditionalsChainPainter(
              points: _chainPoints,
              startPoint: startPoint,
              nodes: nodePoints,
              options: options,
              primaryColor: primaryColor,
              isAnswered: _isAnswered,
              isCorrect: _isCorrect,
              targetNode: _targetIndex,
              isDark: isDark,
            ),
          ),
        );
      },
    );
  }

  Widget _buildResult(
    GrammarQuest quest,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    final bool correct = _isCorrect == true;
    final displayColor = correct ? Colors.greenAccent : Colors.redAccent;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 10.r : 24.r),
        decoration: BoxDecoration(
          color: displayColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(isCompact ? 16.r : 24.r),
          border: Border.all(
            color: displayColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: displayColor,
              size: isCompact ? 24.r : 40.r,
            ),
            SizedBox(height: isCompact ? 4.h : 12.h),
            Text(
              correct
                  ? context
                        .tr('games.correct', fallback: 'Correct')
                        .toUpperCase()
                  : context.tr('games.incorrect_caps', fallback: 'INCORRECT'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: isCompact ? 12.sp : 16.sp,
                fontWeight: FontWeight.w900,
                color: displayColor,
                letterSpacing: 2,
              ),
            ),
            if (!isCompact && quest.explanation != null) ...[
              SizedBox(height: 12.h),
              Text(
                quest.explanation!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.sp,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().shimmer(duration: 2.seconds);
  }
}
