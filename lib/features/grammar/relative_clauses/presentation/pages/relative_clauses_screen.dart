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
import 'package:vowl/features/grammar/relative_clauses/presentation/widgets/relative_clauses_instruction.dart';
import 'package:vowl/features/grammar/relative_clauses/presentation/widgets/relative_clauses_quantum_painter.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/dynamic_jigsaw_wrapper.dart';

class RelativeClausesScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const RelativeClausesScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.relativeClauses,
  });

  @override
  State<RelativeClausesScreen> createState() => _RelativeClausesScreenState();
}

class _RelativeClausesScreenState extends State<RelativeClausesScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  Offset? _hookPoint;
  int _targetFish = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _pendingJigsaw = false;

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(
      FetchGrammarQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onCatch(int fishIndex, int correctIndex) {
    if (_isAnswered || _pendingJigsaw) return;

    bool isCorrect = fishIndex == correctIndex;

    if (isCorrect) {
      _hapticService.heavy();
      _soundService.playCorrect();
      setState(() {
        _targetFish = fishIndex;
        _pendingJigsaw = true;
      });
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _targetFish = fishIndex;
      });
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  void _submitFinalAnswer(bool correct) {
    setState(() => _pendingJigsaw = false);
    setState(() {
      _isAnswered = true;
      _isCorrect = correct;
    });

    if (correct) {
      _hapticService.heavy();
      _soundService.playCorrect();
      context.read<GrammarBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
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
              _targetFish = -1;
              _pendingJigsaw = false;
            });
          } else if (state.answerStatus.isAnswered && !_isAnswered) {
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
            title: 'CLAUSE CATCHER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final GrammarQuest? quest = (state is GrammarLoaded)
            ? state.currentQuest
            : null;
        final fishOptions =
            quest?.options ?? ["WHO IS SMART", "WHICH IS RED", "THAT I LIKE"];

        String cleanTargetSentence = "";
        if (quest != null) {
          final sentence = quest.question ?? "";
          String fullSentence = sentence;
          if (sentence.contains("___") && _targetFish != -1) {
            fullSentence = sentence.replaceFirst(
              RegExp(r'_{3,}'),
              fishOptions[_targetFish],
            );
          }
          cleanTargetSentence = fullSentence
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
        }

        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,
          useScrolling: false, // Stack needs finite space to anchor to bottom
          onContinue: () =>
              context.read<GrammarBloc>().add(const NextQuestion()),
          onHint: () =>
              context.read<GrammarBloc>().add(const GrammarHintUsed()),
          child: quest == null
              ? const SizedBox()
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxHeight < 580;

                        return Column(
                          children: [
                            SizedBox(height: isCompact ? 4.h : 10.h),
                            isCompact
                                ? SizedBox(
                                    height: 25.h,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: RelativeClausesInstruction(
                                        primaryColor: theme.primaryColor,
                                      ),
                                    ),
                                  )
                                : RelativeClausesInstruction(
                                    primaryColor: theme.primaryColor,
                                  ),
                            SizedBox(height: isCompact ? 8.h : 20.h),

                            // Context Card
                            Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24.w,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(
                                      isCompact ? 14.r : 22.r,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.black.withValues(
                                              alpha: 0.03,
                                            ),
                                      borderRadius: BorderRadius.circular(
                                        isCompact ? 18.r : 28.r,
                                      ),
                                      border: Border.all(
                                        color: theme.primaryColor.withValues(
                                          alpha: 0.15,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      quest.question?.replaceAll(
                                            '___',
                                            (_isAnswered || _pendingJigsaw) &&
                                                    _targetFish != -1
                                                ? fishOptions[_targetFish]
                                                : '_____',
                                          ) ??
                                          "The data ____",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: isCompact ? 15.sp : 20.sp,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                        height: 1.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 600.ms)
                                .slideY(begin: 0.2, end: 0),

                            // Result
                            if (_isAnswered) ...[
                              SizedBox(height: isCompact ? 8.h : 20.h),
                              _buildResult(
                                quest,
                                theme.primaryColor,
                                isDark,
                                isCompact,
                              ),
                            ],

                            // Game Arena
                            Expanded(
                              child: _buildQuantumArena(
                                fishOptions,
                                quest.correctAnswerIndex ?? 0,
                                theme.primaryColor,
                                isDark,
                                isCompact,
                              ),
                            ),

                            SizedBox(height: isCompact ? 12.h : 40.h),
                          ],
                        );
                      },
                    ),
                    ),
                    if (_pendingJigsaw &&
                        !_isAnswered &&
                        cleanTargetSentence.isNotEmpty)
                      DynamicJigsawWrapper(
                        expectedText: cleanTargetSentence,
                        primaryColor: theme.primaryColor,
                        onConfirmed: () => _submitFinalAnswer(true),
                        onSkipped: () => _submitFinalAnswer(false),
                        isPositioned: false,
                      ),
                    SizedBox(height: (_isAnswered || _pendingJigsaw) ? 160.h : 60.h),
                  ],
                ),
                ),
              ],
            ),
        );
      },
    );
  }

  Widget _buildQuantumArena(
    List<String> nodes,
    int correctIndex,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final startPoint = Offset(
          constraints.maxWidth / 2,
          isCompact ? 20.h : 40.h,
        );
        final nodeY = constraints.maxHeight - (isCompact ? 80.h : 140.h);
        final nodePoints = List.generate(nodes.length, (i) {
          return Offset(
            50.w + (i * (constraints.maxWidth - 100.w) / (nodes.length - 1)),
            nodeY,
          );
        });
        final hitRadius = isCompact ? 40.r : 55.r;

        return GestureDetector(
          onPanUpdate: (details) {
            if (_isAnswered || _pendingJigsaw) return;
            setState(() {
              _hookPoint = details.localPosition;
              if (details.localPosition.dy.toInt() % 10 == 0) {
                _hapticService.selection();
              }
            });
            for (int i = 0; i < nodePoints.length; i++) {
              if ((details.localPosition - nodePoints[i]).distance <
                  hitRadius) {
                _onCatch(i, correctIndex);
              }
            }
          },
          onPanEnd: (_) => setState(() => _hookPoint = null),
          child: CustomPaint(
            size: Size.infinite,
            painter: RelativeClausesQuantumPainter(
              hookPoint: _hookPoint,
              startPoint: startPoint,
              nodePoints: nodePoints,
              nodeLabels: nodes,
              primaryColor: primaryColor,
              isAnswered: _isAnswered || _pendingJigsaw,
              isCorrect: _isCorrect,
              targetNode: _targetFish,
              isDark: isDark,
              isCompact: isCompact,
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
        padding: EdgeInsets.all(isCompact ? 12.r : 24.r),
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
