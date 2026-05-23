import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/widgets/roleplay_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';

// Holographic audio wave equalizer spectrum painter
class EqualizerArcPainter extends CustomPainter {
  final double rotationValue; // Selected dial level (0.0 to 1.0)
  final double targetValue;   // Empathy target level (0.0 to 1.0)
  final double timeAnimation; // Wave time tick
  final Color themeColor;

  EqualizerArcPainter({
    required this.rotationValue,
    required this.targetValue,
    required this.timeAnimation,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final bool isMatched = (rotationValue - targetValue).abs() < 0.12;

    // Draw background track ring
    final Paint trackPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 12, trackPaint);

    // Draw Gold Target Zone marker
    final Paint targetPaint = Paint()
      ..color = isMatched ? Colors.greenAccent : Colors.orangeAccent
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    // Convert target empathy decimal value to radians arc
    final double targetAngleStart = -math.pi + (targetValue * 2 * math.pi) - 0.18;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 12),
      targetAngleStart,
      0.36,
      false,
      targetPaint,
    );

    // Draw selected value sweep indicator
    final Paint progressPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.8)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final double sweepAngle = rotationValue * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 20),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Paint jagged audio equalizer spectrum lines around the outer dial ring
    final Paint spectrumPaint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final int numSpokes = 64;
    for (int i = 0; i < numSpokes; i++) {
      final double angle = (i * 2 * math.pi / numSpokes) - math.pi / 2;
      
      // Jagged dynamic oscillation height based on current selected level
      double frequencySpeed = 5.0 + (rotationValue * 25.0);
      double phase = (timeAnimation * 2 * math.pi) + (i * frequencySpeed * 0.15);
      double waveHeight = math.sin(phase) * (4.r + (rotationValue * 14.r));

      final double startR = radius - 6.r;
      final double endR = radius + 2.r + waveHeight;

      final Offset startPt = Offset(center.dx + startR * math.cos(angle), center.dy + startR * math.sin(angle));
      final Offset endPt = Offset(center.dx + endR * math.cos(angle), center.dy + endR * math.sin(angle));

      // Color fades from deep blue (soft) to red (aggressive) based on spoke index
      Color spokeColor = Color.lerp(Colors.cyanAccent, Colors.redAccent, rotationValue) ?? themeColor;
      if (isMatched) spokeColor = Colors.greenAccent;

      spectrumPaint.color = spokeColor.withValues(alpha: 0.35 + (0.6 * math.sin(phase).abs()));
      canvas.drawLine(startPt, endPt, spectrumPaint);
    }
  }

  @override
  bool shouldRepaint(covariant EqualizerArcPainter oldDelegate) {
    return oldDelegate.rotationValue != rotationValue ||
        oldDelegate.targetValue != targetValue ||
        oldDelegate.timeAnimation != timeAnimation ||
        oldDelegate.themeColor != themeColor;
  }
}

class ConflictResolverScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ConflictResolverScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.conflictResolver,
  });

  @override
  State<ConflictResolverScreen> createState() => _ConflictResolverScreenState();
}

class _ConflictResolverScreenState extends State<ConflictResolverScreen> with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  late AnimationController _waveController;
  late AnimationController _pulseController;
  
  int _lastProcessedIndex = -1;
  double _rotation = 0.0; // Slider score level (0.0 to 1.0)
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    context.read<RoleplayBloc>().add(FetchRoleplayQuests(gameType: widget.gameType, level: widget.level));
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(RoleplayQuest quest) {
    _soundService.playTts(quest.instruction);
    if (quest.scene != null) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) _soundService.playTts(quest.scene!);
      });
    }
  }

  // Realistic Physical dial rotation updater utilizing trigonometry
  void _onDialDragged(DragUpdateDetails details, Offset localDialCenter) {
    if (_isAnswered) return;

    final Offset touchPos = details.localPosition;
    final double dx = touchPos.dx - localDialCenter.dx;
    final double dy = touchPos.dy - localDialCenter.dy;

    // Calculate angle in radians (-pi to pi)
    double angle = math.atan2(dy, dx);
    
    // Normalize to 0 to 2pi
    if (angle < 0) {
      angle += 2 * math.pi;
    }

    // Convert angle to progress scale (0.0 to 1.0)
    // -pi/2 (top center) is 0.0
    double progress = (angle + math.pi / 2) / (2 * math.pi);
    if (progress > 1.0) progress -= 1.0;

    _hapticService.selection();
    setState(() {
      _rotation = progress.clamp(0.0, 1.0);
    });
  }

  void _submitAnswer(double target) {
    if (_isAnswered) return;

    // 0.12 empathy tolerance proximity check
    bool isCorrect = (_rotation - target).abs() < 0.12;

    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
    });

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<RoleplayBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<RoleplayBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('roleplay', level: widget.level);

    return BlocConsumer<RoleplayBloc, RoleplayState>(
      listener: (context, state) {
        if (state is RoleplayLoaded) {
          if (state.currentIndex != _lastProcessedIndex) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _rotation = 0.0;
            });
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          }
        }
        if (state is RoleplayGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'PEACE RESOLVER!',
            enableDoubleUp: true,
          );
        } else if (state is RoleplayGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<RoleplayBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;
        final double empathyTarget = quest?.empathyScore ?? 0.75;

        return RoleplayBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<RoleplayBloc>().add(NextQuestion()),
          onHint: () => context.read<RoleplayBloc>().add(RoleplayHintUsed()),
          child: quest == null
              ? const SizedBox()
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  child: Column(
                    children: [
                      _buildHeaderInstruction(theme.primaryColor),
                      SizedBox(height: 16.h),
                      _buildConflictCard(quest.scene ?? "", theme.primaryColor, isDark),
                      SizedBox(height: 24.h),

                      // Circular audio dials
                      _buildDialConsole(empathyTarget, theme.primaryColor, isDark),
                      SizedBox(height: 28.h),

                      // Submit control button
                      if (!_isAnswered)
                        ScaleButton(
                          onTap: () => _submitAnswer(empathyTarget),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 48.w, vertical: 14.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30.r),
                              gradient: LinearGradient(
                                colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.8)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.primaryColor.withValues(alpha: 0.35),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.security_rounded, color: Colors.white, size: 18.r),
                                SizedBox(width: 8.w),
                                Text(
                                  "LOCK HARMONIC FREQUENCY",
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(duration: 300.ms),

                      // Post-answer review cards
                      AnimatedCrossFade(
                        firstChild: const SizedBox(),
                        secondChild: _buildExplanationCard(quest, isDark),
                        crossFadeState: _isAnswered
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 400),
                      ),
                      SizedBox(height: 80.h),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeaderInstruction(Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Text(
            "EMPATHY DIAL SPECTRUM",
            style: GoogleFonts.outfit(
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 2.5,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          "Tune the console to balance the argument frequency",
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildConflictCard(String scene, Color color, bool isDark) {
    Color emotionalColor = Color.lerp(Colors.cyanAccent, Colors.redAccent, _rotation) ?? color;
    if ((_rotation - 0.75).abs() < 0.12) {
      emotionalColor = Colors.greenAccent;
    }

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: emotionalColor.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: emotionalColor.withValues(alpha: 0.08),
            blurRadius: 15,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: emotionalColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.forum_rounded, color: emotionalColor, size: 24.r),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.15, 1.15),
                duration: 1.5.seconds,
                curve: Curves.easeInOut,
              ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CONFLICT SCENARIO DETECTED:",
                  style: GoogleFonts.shareTechMono(
                    fontSize: 10.sp,
                    color: emotionalColor,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  scene,
                  style: GoogleFonts.fredoka(
                    fontSize: 17.sp,
                    color: isDark ? Colors.white : Colors.black87,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialConsole(double targetValue, Color color, bool isDark) {
    final double dialDiameter = 220.r;
    final Offset dialCenter = Offset(dialDiameter / 2, dialDiameter / 2);
    final bool isMatched = (_rotation - targetValue).abs() < 0.12;

    return Container(
      width: 1.sw,
      padding: EdgeInsets.symmetric(vertical: 24.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF07070F) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(36.r),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Column(
        children: [
          // Holographic Dial Board
          GestureDetector(
            onPanUpdate: (details) => _onDialDragged(details, dialCenter),
            child: Container(
              width: dialDiameter,
              height: dialDiameter,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Spinning audio spectrum equalizer lines
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: EqualizerArcPainter(
                            rotationValue: _rotation,
                            targetValue: targetValue,
                            timeAnimation: _waveController.value,
                            themeColor: color,
                          ),
                        );
                      },
                    ),
                  ),

                  // Metallic rotatable core knob
                  Transform.rotate(
                    angle: _rotation * 2 * math.pi,
                    child: Container(
                      width: 130.r,
                      height: 130.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [const Color(0xFF2A2A3E), const Color(0xFF131326)]
                              : [Colors.white, Colors.grey.shade300],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(3, 3),
                          ),
                        ],
                        border: Border.all(
                          color: isMatched
                              ? Colors.greenAccent
                              : color.withValues(alpha: 0.3),
                          width: 3,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Rotary position notch marker
                          Positioned(
                            top: 8.r,
                            child: Container(
                              width: 6.r,
                              height: 16.r,
                              decoration: BoxDecoration(
                                color: isMatched ? Colors.greenAccent : color,
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                            ),
                          ),
                          Icon(
                            isMatched ? Icons.check_rounded : Icons.tune_rounded,
                            color: isMatched ? Colors.greenAccent : color.withValues(alpha: 0.7),
                            size: 32.r,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20.h),
          
          // Calibration level metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "DIAL LEVEL: ",
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp,
                  color: Colors.grey,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                "${(_rotation * 100).toInt()}% empathy",
                style: GoogleFonts.shareTechMono(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: isMatched
                      ? Colors.greenAccent
                      : Color.lerp(Colors.cyanAccent, Colors.redAccent, _rotation),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard(RoleplayQuest quest, bool isDark) {
    final Color cardColor = (_isCorrect ?? false) ? Colors.greenAccent : Colors.orangeAccent;

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131326) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: cardColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.15),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                (_isCorrect ?? false) ? Icons.verified_rounded : Icons.info_rounded,
                color: cardColor,
                size: 24.r,
              ),
              SizedBox(width: 8.w),
              Text(
                (_isCorrect ?? false) ? "Frequency Calibrated!" : "Frequency Distortion!",
                style: GoogleFonts.outfit(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            quest.explanation ?? "Calibrating voice frequency teaches strong crisis control and empathic context listening patterns.",
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.35,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }
}
