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
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex ||
              livesChanged ||
              (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _needleRotation = 0.0;
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
                    _buildInstruction(theme.primaryColor),
                    SizedBox(height: 32.h),
                    _buildSentenceDisplay(
                      quest.sentence ?? quest.question ?? "",
                      theme.primaryColor,
                      isDark,
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

  Widget _buildInstruction(Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.explore_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text(
            "STEER TO THE CORRECT RULE",
            style: GoogleFonts.outfit(
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: primaryColor,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentenceDisplay(String text, Color primaryColor, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.all(24.r),
      borderRadius: BorderRadius.circular(28.r),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.fredoka(
          fontSize: 20.sp,
          color: isDark ? Colors.white : Colors.black87,
          height: 1.4,
        ),
      ),
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
                  painter: _CompassTicksPainter(
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
        painter: _SentinelNeedlePainter(color: color, isGlass: isGlass),
      ),
    );
  }
}

class _SentinelNeedlePainter extends CustomPainter {
  final Color color;
  final bool isGlass;

  _SentinelNeedlePainter({required this.color, required this.isGlass});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    // 1. Shadow/Outer Frame Glow
    if (isGlass) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(_getOuterFramePath(size), glowPaint);
    }

    // 2. Main Segmented Frame
    final framePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: isGlass ? 0.8 : 0.4),
          color.withValues(alpha: isGlass ? 0.3 : 0.1),
          color.withValues(alpha: isGlass ? 0.6 : 0.2),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(_getOuterFramePath(size), framePaint);

    // 3. Crystalline Energy Core (The "Sentinel" Beam)
    if (isGlass) {
      final corePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            color.withValues(alpha: 0.9),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.3, 1.0],
        ).createShader(Rect.fromLTWH(centerX - 5.r, 0, 10.r, size.height * 0.8))
        ..style = PaintingStyle.fill;

      final corePath = Path()
        ..moveTo(centerX, size.height * 0.05)
        ..lineTo(centerX + 3.r, size.height * 0.4)
        ..lineTo(centerX + 1.r, size.height * 0.75)
        ..lineTo(centerX - 1.r, size.height * 0.75)
        ..lineTo(centerX - 3.r, size.height * 0.4)
        ..close();

      canvas.drawPath(corePath, corePaint);
    }

    // 4. Refractive Edge Highlights
    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: isGlass ? 0.4 : 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(_getOuterFramePath(size), edgePaint);

    // 5. Precision Micro-Ticks (The "Instrument" Look)
    if (isGlass) {
      final tickPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..strokeWidth = 1;

      for (int i = 1; i <= 5; i++) {
        final y = size.height * (0.3 + (i * 0.08));
        final tickWidth = (i == 3) ? 6.r : 3.r;
        canvas.drawLine(
          Offset(centerX - tickWidth, y),
          Offset(centerX + tickWidth, y),
          tickPaint,
        );
      }
    }
  }

  Path _getOuterFramePath(Size size) {
    final centerX = size.width / 2;
    return Path()
      ..moveTo(centerX, 0) // Tip
      ..lineTo(size.width, size.height * 0.35) // Flare
      ..lineTo(centerX + 6.r, size.height * 0.45) // Neck In
      ..lineTo(centerX + 8.r, size.height * 0.8) // Base Flare
      ..lineTo(centerX - 8.r, size.height * 0.8) // Base Flare
      ..lineTo(centerX - 6.r, size.height * 0.45) // Neck In
      ..lineTo(0, size.height * 0.35) // Flare
      ..close();
  }

  @override
  bool shouldRepaint(covariant _SentinelNeedlePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isGlass != isGlass;
  }
}

class _CompassTicksPainter extends CustomPainter {
  final Color color;
  _CompassTicksPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.r
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (var i = 0; i < 36; i++) {
      final angle = (i * 10) * (math.pi / 180);
      final isMajor = i % 9 == 0;
      final start = Offset(
        center.dx + (radius - (isMajor ? 15.r : 8.r)) * math.cos(angle),
        center.dy + (radius - (isMajor ? 15.r : 8.r)) * math.sin(angle),
      );
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CompassTicksPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
