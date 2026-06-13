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
import 'package:vowl/features/grammar/conjunctions/presentation/widgets/conjunctions_instruction.dart';
import 'package:vowl/features/grammar/conjunctions/presentation/widgets/conjunctions_brick_sheet.dart';
import 'package:vowl/core/utils/locale_service.dart';

class ConjunctionsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ConjunctionsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.conjunctions,
  });

  @override
  State<ConjunctionsScreen> createState() => _ConjunctionsScreenState();
}

class _ConjunctionsScreenState extends State<ConjunctionsScreen>
    with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  String? _placedBrick;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(
      FetchGrammarQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onBridge(String conj, int correctIndex, List<String> options) {
    if (_isAnswered) return;

    bool isCorrect = conj == options[correctIndex];

    if (isCorrect) {
      _hapticService.heavy();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
        _placedBrick = conj;
      });
      context.read<GrammarBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _placedBrick = conj;
      });
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
            title: 'SYNAPSE!',
            enableDoubleUp: true,
          );
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<GrammarBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final GrammarQuest? quest = (state is GrammarLoaded)
            ? state.currentQuest
            : null;
        final options = quest?.options ?? ["AND", "BUT", "OR"];
        final question = quest?.question ?? "I like apples... I like oranges.";
        final parts = question.contains("...")
            ? question.split("...")
            : question.split("___");

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
                        (isCompact ? 50.h : 80.h) * 2 +
                        (isCompact ? 50.h : 70.h) +
                        (isCompact ? 50.h : 80.h) +
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

                    return Column(
                      children: [
                        SizedBox(height: gapTop),
                        isCompact
                            ? SizedBox(
                                height: 25.h,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: ConjunctionsInstruction(
                                    primaryColor: theme.primaryColor,
                                  ),
                                ),
                              )
                            : ConjunctionsInstruction(
                                primaryColor: theme.primaryColor,
                              ),
                        SizedBox(height: gapMiddle),

                        // Magnetic Junction Bridge
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildIslandPiece(
                                  parts.first,
                                  isDark,
                                  theme.primaryColor,
                                  isCompact,
                                ),
                                SizedBox(height: isCompact ? 12.h : 24.h),
                                _buildMagneticJunction(
                                  options,
                                  quest.correctAnswerIndex ?? 0,
                                  theme.primaryColor,
                                  isDark,
                                  isCompact,
                                ),
                                SizedBox(height: isCompact ? 12.h : 24.h),
                                if (parts.length > 1 && parts.last.isNotEmpty)
                                  _buildIslandPiece(
                                    parts.last,
                                    isDark,
                                    theme.primaryColor,
                                    isCompact,
                                  ).animate().fadeIn(delay: 400.ms),
                                if (_isAnswered) ...[
                                  SizedBox(height: isCompact ? 10.h : 20.h),
                                  _buildCorrectResult(
                                    quest,
                                    theme.primaryColor,
                                    isDark,
                                    isCompact,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: gapMiddle),

                        ConjunctionsBrickSheet(
                          options: options,
                          placedBrick: _placedBrick,
                          primaryColor: theme.primaryColor,
                          isDark: isDark,
                          isCompact: isCompact,
                        ),
                        SizedBox(height: gapBottom),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildMagneticJunction(
    List<String> options,
    int correctIndex,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) =>
          _onBridge(details.data, correctIndex, options),
      builder: (context, candidateData, rejectedData) {
        final isHighlight = candidateData.isNotEmpty;
        final nodeColor = _placedBrick != null
            ? (_isCorrect == true ? Colors.greenAccent : Colors.redAccent)
            : (isHighlight
                  ? primaryColor
                  : primaryColor.withValues(alpha: 0.3));

        return Container(
          width: isCompact ? 140.w : 180.w,
          height: isCompact ? 48.h : 70.h,
          decoration: BoxDecoration(
            color: nodeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(isCompact ? 14.r : 20.r),
            border: Border.all(
              color: nodeColor.withValues(alpha: 0.4),
              width: 2,
              style: _placedBrick != null
                  ? BorderStyle.none
                  : BorderStyle.solid,
            ),
            boxShadow: [
              if (isHighlight || _placedBrick != null)
                BoxShadow(
                  color: nodeColor.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Center(
            child: _placedBrick != null
                ? Text(
                    _placedBrick!.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: isCompact ? 14.sp : 20.sp,
                      fontWeight: FontWeight.w900,
                      color: nodeColor,
                    ),
                  ).animate().scale(duration: 400.ms, curve: Curves.elasticOut)
                : (isHighlight
                      ? Icon(
                          Icons.bolt_rounded,
                          color: primaryColor,
                          size: isCompact ? 20.r : 28.r,
                        ).animate().scale().shimmer()
                      : Text(
                          "JUNCTION",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: isCompact ? 8.sp : 10.sp,
                            fontWeight: FontWeight.w900,
                            color: primaryColor.withValues(alpha: 0.4),
                            letterSpacing: 2,
                          ),
                        )),
          ),
        );
      },
    );
  }

  Widget _buildIslandPiece(
    String text,
    bool isDark,
    Color primaryColor,
    bool isCompact,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 12.r : 22.r),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(isCompact ? 14.r : 24.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Text(
        text.trim(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: isCompact ? 14.sp : 18.sp,
          color: isDark ? Colors.white : Colors.black87,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildCorrectResult(
    GrammarQuest quest,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    final bool correct = _isCorrect == true;
    final displayColor = correct ? Colors.greenAccent : Colors.redAccent;

    return Container(
      padding: EdgeInsets.all(isCompact ? 10.r : 20.r),
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
            size: isCompact ? 24.r : 36.r,
          ),
          SizedBox(height: isCompact ? 4.h : 10.h),
          Text(
            correct ? context.tr('games.correct').toUpperCase() : context.tr('games.incorrect_caps'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: isCompact ? 12.sp : 15.sp,
              fontWeight: FontWeight.w900,
              color: displayColor,
              letterSpacing: 2,
            ),
          ),
          if (!isCompact && quest.explanation != null) ...[
            SizedBox(height: 10.h),
            Text(
              quest.explanation!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ],
      ),
    ).animate().shimmer(duration: 2.seconds);
  }
}
