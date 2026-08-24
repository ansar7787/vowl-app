import 'dart:math';
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
import 'package:vowl/features/grammar/pronoun_resolution/presentation/widgets/pronoun_resolution_instruction.dart';
import 'package:vowl/features/grammar/pronoun_resolution/presentation/widgets/pronoun_resolution_gravity_painter.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/game_mechanics/type_to_confirm_overlay.dart';

class PronounResolutionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const PronounResolutionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.pronounResolution,
  });

  @override
  State<PronounResolutionScreen> createState() =>
      _PronounResolutionScreenState();
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
  bool _pendingJigsaw = false;

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(
      FetchGrammarQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onFire(int nodeIndex, int correctIndex) {
    if (_isAnswered || _pendingJigsaw) return;

    bool isCorrect = nodeIndex == correctIndex;

    if (isCorrect) {
      _hapticService.heavy();
      _soundService.playCorrect();
      setState(() {
        _targetIndex = nodeIndex;
        _pendingJigsaw = true;
      });
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _targetIndex = nodeIndex;
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
              _targetIndex = -1;
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
            title: 'REFERENT EXPERT!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final GrammarQuest? quest = (state is GrammarLoaded)
            ? state.currentQuest
            : null;
        final options = quest?.options ?? ["NOUN A", "NOUN B", "NOUN C"];

        String cleanTargetSentence = "";
        if (quest != null) {
          final sentence = quest.correctAnswer ?? quest.sentence ?? "";
          if (sentence.isNotEmpty) {
            cleanTargetSentence = sentence
                .replaceAll('[', '')
                .replaceAll(']', '');
          } else if (_targetIndex != -1) {
            cleanTargetSentence = options[_targetIndex];
          }
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
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                      builder: (context, constraints) {
                        final maxHeight = constraints.maxHeight;
                        final isCompact = maxHeight < 580;

                        final double estimatedContentHeight =
                            (isCompact ? 30.h : 40.h) +
                            (isCompact ? 50.h : 80.h) +
                            (isCompact ? 160.h : 260.h) +
                            40.h;
                        final remainingHeight =
                            maxHeight - estimatedContentHeight;

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
                                      child: PronounResolutionInstruction(
                                        primaryColor: theme.primaryColor,
                                      ),
                                    ),
                                  )
                                : PronounResolutionInstruction(
                                    primaryColor: theme.primaryColor,
                                  ),
                            SizedBox(height: gapMiddle),

                            if (quest.referentHighlight != null) ...[
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      "REFERENT: ${quest.referentHighlight!.toUpperCase()}",
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 12.sp,
                                        color: theme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text("Pronoun", style: TextStyle(fontSize: 10.sp, color: theme.primaryColor.withValues(alpha: 0.7))),
                                        Icon(Icons.arrow_forward_rounded, color: theme.primaryColor, size: 16.sp),
                                        Text("Referent Noun", style: TextStyle(fontSize: 10.sp, color: theme.primaryColor, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(duration: 400.ms),
                              SizedBox(height: isCompact ? 12.h : 20.h),
                            ],

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
                                      quest.sentence ??
                                          "The antecedent is missing from the gravity field.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: isCompact ? 14.sp : 18.sp,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                        height: 1.4,
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
                              child: _buildGravityWell(
                                options,
                                quest.correctAnswerIndex ?? 0,
                                quest.targetWord ?? "it",
                                theme.primaryColor,
                                isDark,
                                isCompact,
                              ),
                            ),

                            SizedBox(height: gapBottom),
                          ],
                        );
                      },
                    ),
                    ),
                    if (_pendingJigsaw &&
                        !_isAnswered &&
                        cleanTargetSentence.isNotEmpty)
                      TypeToConfirmOverlay(
                        expectedText: cleanTargetSentence,
                        primaryColor: theme.primaryColor,
                        onConfirmed: () => _submitFinalAnswer(true),
                        onSkipped: () => _submitFinalAnswer(false),
                        isPositioned: false,
                        displayText: "Type the resolved sentence to lock it in",
                      ),
                    SizedBox(height: (_isAnswered || _pendingJigsaw) ? 160.h : 60.h),
                  ],
                ),
                ),
              ],
            );
                  },
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
    bool isCompact,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final centerPoint = Offset(
          constraints.maxWidth / 2,
          constraints.maxHeight / 2 + (isCompact ? 10.h : 20.h),
        );
        final nodeCount = options.length;
        final double orbitRadius = isCompact ? 80.r : 130.r;

        final nodePoints = List.generate(nodeCount, (i) {
          final angle = (i * (2 * pi / nodeCount)) - (pi / 2);
          return Offset(
            centerPoint.dx + cos(angle) * orbitRadius,
            centerPoint.dy + sin(angle) * orbitRadius,
          );
        });

        return GestureDetector(
          onPanUpdate: (details) {
            if (_isAnswered || _pendingJigsaw) return;
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
              isAnswered: _isAnswered || _pendingJigsaw,
              isCorrect: _isCorrect ?? false,
              targetNode: _targetIndex,
              pronoun: pronoun,
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
