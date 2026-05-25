import 'dart:ui' as ui;
import 'dart:math' as math;
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
import 'package:vowl/features/grammar/grammar_quest/presentation/widgets/grammar_quest_instruction.dart';
import 'package:vowl/features/grammar/grammar_quest/presentation/widgets/grammar_quest_sentence.dart';
import 'package:vowl/features/grammar/grammar_quest/presentation/widgets/grammar_quest_sentinel_needle_painter.dart';
import 'package:vowl/features/grammar/grammar_quest/presentation/widgets/grammar_quest_compass_ticks_painter.dart';

class GrammarQuestScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const GrammarQuestScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.grammarQuest,
  });

  @override
  State<GrammarQuestScreen> createState() => _GrammarQuestScreenState();
}

class _GrammarQuestScreenState extends State<GrammarQuestScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgRotationController;
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  double _needleRotation = 0.0; // In radians
  bool _isDragging = false;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    _bgRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    context.read<GrammarBloc>().add(
      FetchGrammarQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _bgRotationController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details, Offset center) {
    if (_isAnswered) return;

    final localPosition = details.localPosition;
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    setState(() {
      _needleRotation = math.atan2(dy, dx) + (math.pi / 2);
      _isDragging = true;
    });

    // Subtle tick when passing near quadrants
    final normalizedAngle =
        (_needleRotation % (2 * math.pi) + (2 * math.pi)) % (2 * math.pi);
    final nearestQuadrant = (normalizedAngle / (math.pi / 2)).round() % 4;
    final quadrantAngle = nearestQuadrant * (math.pi / 2);
    if ((normalizedAngle - quadrantAngle).abs() < 0.1 &&
        nearestQuadrant != _lastProcessedIndex) {
      _hapticService.light();
    }
  }

  void _handleDragEnd(int correctIndex) {
    if (_isAnswered) return;

    setState(() => _isDragging = false);

    // Normalize rotation and find nearest quadrant
    final normalizedAngle =
        (_needleRotation % (2 * math.pi) + (2 * math.pi)) % (2 * math.pi);
    final index = (normalizedAngle / (math.pi / 2)).round() % 4;

    _onQuadrantSelect(index, correctIndex);
  }

  void _onQuadrantSelect(int index, int correctIndex) {
    if (_isAnswered) return;

    // Snap needle to quadrant center
    setState(() {
      _needleRotation = (index * (math.pi * 2) / 4);
    });

    _hapticService.selection();

    bool isCorrect = index == correctIndex;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });
      context.read<GrammarBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
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
          final isRetry = _isAnswered && state.lastAnswerCorrect == null;
          final livesChanged = _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _needleRotation = 0.0;
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
            title: 'SENTINEL!',
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
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final options =
            quest?.options ??
            ["Subject", "Verb", "Object", "Tense"]; // Fallback options

        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,
          useScrolling: true,
          onContinue: () => context.read<GrammarBloc>().add(NextQuestion()),
          onHint: () => context.read<GrammarBloc>().add(GrammarHintUsed()),
          child: quest == null
              ? const SizedBox()
              : Column(
                  children: [
                    SizedBox(height: 20.h),
                    GrammarQuestInstruction(primaryColor: theme.primaryColor),
                    SizedBox(height: 32.h),
                    GrammarQuestSentence(
                      text: quest.sentence ?? quest.question ?? "",
                      isDark: isDark,
                    ),
                    SizedBox(height: 60.h),
                    _buildQuestCompass(
                      options,
                      quest.correctAnswerIndex ?? 0,
                      theme.primaryColor,
                      isDark,
                    ),
                    SizedBox(height: 40.h),
                  ],
                ),
        );
      },
    );
  }



  Widget _buildQuestCompass(
    List<String> options,
    int correctIndex,
    Color primaryColor,
    bool isDark,
  ) {
    final size = 280.r;
    final center = Offset(size / 2, size / 2);

    return GestureDetector(
      onPanUpdate: (details) => _handleDragUpdate(details, center),
      onPanEnd: (_) => _handleDragEnd(correctIndex),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.1),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Outer Rotating Holographic Ring
            RotationTransition(
              turns: _bgRotationController,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.1),
                    width: 1.r,
                  ),
                ),
                child: CustomPaint(
                  painter: CompassTicksPainter(
                    primaryColor.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
            // Inner Static Dial
            Container(
              width: size * 0.9,
              height: size * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.15),
                  width: 2.r,
                ),
              ),
            ),
            // Quadrants and Selection Beams
            ...List.generate(4, (index) {
              final angle = index * (math.pi * 2) / 4;
              final optionText = index < options.length ? options[index] : "";
              final isSelected =
                  _isAnswered &&
                  (index ==
                      ((_needleRotation % (2 * math.pi) + 2 * math.pi) %
                                  (2 * math.pi) /
                                  (math.pi / 2))
                              .round() %
                          4);

              return Transform.rotate(
                angle: angle,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Selection Beam
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: isSelected ? 1.0 : 0.0,
                      child: Container(
                        width: 40.w,
                        height: size * 0.45,
                        margin: EdgeInsets.only(bottom: size * 0.45),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              primaryColor.withValues(alpha: 0.0),
                              primaryColor.withValues(alpha: 0.2),
                              primaryColor.withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Option Text (Glass-Morphic Tag - Interior Placement)
                    Positioned(
                      top: size * 0.1, // Positioning inside the dial
                      child: Transform.rotate(
                        angle: -angle,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 300),
                          scale: isSelected ? 1.1 : 1.0,
                          child: Container(
                            constraints: BoxConstraints(maxWidth: size * 0.35),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(
                                  sigmaX: 8,
                                  sigmaY: 8,
                                ),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 6.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryColor.withValues(alpha: 0.3)
                                        : (isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.12,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.06,
                                                )),
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white
                                          : primaryColor.withValues(alpha: 0.3),
                                      width: 1.5.r,
                                    ),
                                  ),
                                  child: Text(
                                    optionText,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.visible,
                                    style: GoogleFonts.outfit(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w900,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                                ? Colors.white
                                                : Colors.black87),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            // The Tapered Photon Needle
            TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: _isDragging ? 50 : 600),
              curve: _isDragging ? Curves.linear : Curves.elasticOut,
              tween: Tween<double>(begin: 0, end: _needleRotation),
              builder: (context, value, child) {
                return Transform.rotate(angle: value, child: child);
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Needle Shadow
                  Transform.translate(
                    offset: const Offset(3, 3),
                    child: _buildNeedleShape(
                      Colors.black.withValues(alpha: 0.2),
                      170.h,
                    ),
                  ),
                  // Asymmetric HUD Vector Needle
                  _buildNeedleShape(primaryColor, 170.h, isGlass: true),
                  // Pointer Emitter (Top)
                  Positioned(
                    top: 5.h,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulsing Halo (Visual Feedback)
                        RepaintBoundary(
                          child:
                              Container(
                                    width: 24.r,
                                    height: 24.r,
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                  .animate(onPlay: (c) => c.repeat())
                                  .scale(
                                    begin: const Offset(0.8, 0.8),
                                    end: const Offset(1.2, 1.2),
                                    duration: 1.seconds,
                                  )
                                  .fadeOut(),
                        ),
                        // Emitter Core
                        RepaintBoundary(
                          child: Container(
                            width: 12.r,
                            height: 12.r,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor,
                                  blurRadius: 15,
                                  spreadRadius: 4,
                                ),
                                const BoxShadow(
                                  color: Colors.white,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 4.r,
                                height: 4.r,
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Counter-weight (Bottom Orbital - Minimalist)
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 16.r,
                      height: 16.r,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: Center(
                        child: Container(
                          width: 6.r,
                          height: 6.r,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Central Hub (Refractive Glass)
            Container(
              width: 60.r,
              height: 60.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.2),
                  width: 1.5.r,
                ),
              ),
              child: Center(
                child: Container(
                  width: 10.r,
                  height: 10.r,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeedleShape(Color color, double height, {bool isGlass = false}) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(32.r, height),
        painter: SentinelNeedlePainter(color: color, isGlass: isGlass),
      ),
    );
  }
}
