import 'dart:math';
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
import 'package:vowl/features/grammar/pronoun_resolution/presentation/widgets/pronoun_resolution_instruction.dart';
import 'package:vowl/features/grammar/pronoun_resolution/presentation/widgets/pronoun_resolution_gravity_painter.dart';

class PronounResolutionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const PronounResolutionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.pronounResolution,
  });

  @override
  State<PronounResolutionScreen> createState() => _PronounResolutionScreenState();
}

class _PronounResolutionScreenState extends State<PronounResolutionScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  double _rotation = 0.0;
  int _targetIndex = -1;
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

  void _onFire(int nodeIndex, int correctIndex) {
    if (_isAnswered) return;

    bool isCorrect = nodeIndex == correctIndex;

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
      _targetIndex = nodeIndex;
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
              _rotation = 0.0;
              _targetIndex = -1;
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
            title: 'REFERENT EXPERT!',
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
        final options = quest?.options ?? ["NOUN A", "NOUN B", "NOUN C"];

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
                    PronounResolutionInstruction(primaryColor: theme.primaryColor),
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
                          quest.sentence ?? "The antecedent is missing from the gravity field.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontSize: 18.sp,
                            color: isDark ? Colors.white70 : Colors.black87,
                            height: 1.4,
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
                      child: _buildGravityWell(
                        options,
                        quest.correctAnswerIndex ?? 0,
                        quest.targetWord ?? "it",
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

  Widget _buildGravityWell(
    List<String> options,
    int correctIndex,
    String pronoun,
    Color primaryColor,
    bool isDark,
  ) {
    return LayoutBuilder(builder: (context, constraints) {
      final centerPoint = Offset(
        constraints.maxWidth / 2,
        constraints.maxHeight / 2 + 20.h,
      );
      final nodeCount = options.length;

      final nodePoints = List.generate(nodeCount, (i) {
        final angle = (i * (2 * pi / nodeCount)) - (pi / 2);
        return Offset(
          centerPoint.dx + cos(angle) * 130.r,
          centerPoint.dy + sin(angle) * 130.r,
        );
      });

      return GestureDetector(
        onPanUpdate: (details) {
          if (_isAnswered) return;
          final localPos = details.localPosition;
          setState(() {
            _rotation = atan2(
              localPos.dy - centerPoint.dy,
              localPos.dx - centerPoint.dx,
            );
          });
          for (int i = 0; i < nodePoints.length; i++) {
            final nodeAngle = atan2(
              nodePoints[i].dy - centerPoint.dy,
              nodePoints[i].dx - centerPoint.dx,
            );
            if ((_rotation - nodeAngle).abs() < 0.15) {
              _onFire(i, correctIndex);
            }
          }
        },
        child: CustomPaint(
          size: Size.infinite,
          painter: PronounResolutionGravityPainter(
            rotation: _rotation,
            centerPoint: centerPoint,
            nodes: nodePoints,
            options: options,
            primaryColor: primaryColor,
            isAnswered: _isAnswered,
            isCorrect: _isCorrect ?? false,
            targetNode: _targetIndex,
            pronoun: pronoun,
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
