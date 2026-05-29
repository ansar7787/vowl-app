import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/widgets/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/relative_clauses/presentation/widgets/relative_clauses_instruction.dart';
import 'package:vowl/features/grammar/relative_clauses/presentation/widgets/relative_clauses_quantum_painter.dart';

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

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(
      FetchGrammarQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onCatch(int fishIndex, int correctIndex) {
    if (_isAnswered) return;

    bool isCorrect = fishIndex == correctIndex;

    if (isCorrect) {
      _hapticService.heavy();
      _soundService.playCorrect();
    } else {
      _hapticService.error();
      _soundService.playWrong();
    }

    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
      _targetFish = fishIndex;
    });
    context.read<GrammarBloc>().add(SubmitAnswer(isCorrect));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listener: (context, state) {
        if (state is GrammarLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered && state.lastAnswerCorrect == null;
          final livesChanged = _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _hookPoint = null;
              _targetFish = -1;
            });
          } else if (state.lastAnswerCorrect != null && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.lastAnswerCorrect;
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
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<GrammarBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final GrammarQuest? quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final fishOptions = quest?.options ?? ["WHO IS SMART", "WHICH IS RED", "THAT I LIKE"];

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
              : Column(
                  children: [
                    SizedBox(height: 10.h),
                    RelativeClausesInstruction(primaryColor: theme.primaryColor),
                    SizedBox(height: 20.h),

                    // Context Card
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(22.r),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(28.r),
                          border: Border.all(
                            color: theme.primaryColor.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          quest.question?.replaceAll('___', '_____') ?? "The data ____",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontSize: 20.sp,
                            color: isDark ? Colors.white : Colors.black87,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),

                    // Result
                    if (_isAnswered) ...[
                      SizedBox(height: 20.h),
                      _buildResult(quest, theme.primaryColor, isDark),
                    ],

                    // Game Arena
                    Expanded(
                      child: _buildQuantumArena(
                        fishOptions,
                        quest.correctAnswerIndex ?? 0,
                        theme.primaryColor,
                        isDark,
                      ),
                    ),

                    SizedBox(height: 40.h),
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
  ) {
    return LayoutBuilder(builder: (context, constraints) {
      final startPoint = Offset(constraints.maxWidth / 2, 40.h);
      final nodePoints = List.generate(nodes.length, (i) {
        return Offset(
          50.w + (i * (constraints.maxWidth - 100.w) / (nodes.length - 1)),
          constraints.maxHeight - 140.h,
        );
      });

      return GestureDetector(
        onPanUpdate: (details) {
          if (_isAnswered) return;
          setState(() {
            _hookPoint = details.localPosition;
            if (details.localPosition.dy.toInt() % 10 == 0) {
              _hapticService.selection();
            }
          });
          for (int i = 0; i < nodePoints.length; i++) {
            if ((details.localPosition - nodePoints[i]).distance < 55.r) {
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
            isAnswered: _isAnswered,
            isCorrect: _isCorrect,
            targetNode: _targetFish,
            isDark: isDark,
          ),
        ),
      );
    });
  }

  Widget _buildResult(GrammarQuest quest, Color primaryColor, bool isDark) {
    final bool correct = _isCorrect == true;
    final displayColor = correct ? Colors.greenAccent : Colors.redAccent;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: displayColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24.r),
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
              size: 40.r,
            ),
            SizedBox(height: 12.h),
            Text(
              correct ? "CORRECT!" : "INCORRECT",
              style: GoogleFonts.outfit(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: displayColor,
                letterSpacing: 2,
              ),
            ),
            if (quest.explanation != null) ...[
              SizedBox(height: 12.h),
              Text(
                quest.explanation!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
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
