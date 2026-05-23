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
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_base_layout.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/accent/dialect_drill/presentation/widgets/dialect_feedback_panel.dart';

// Hologram Radar Custom Painter
class HologramRadarPainter extends CustomPainter {
  final double sweepAngle;
  final Color themeColor;
  final bool isDark;

  HologramRadarPainter({
    required this.sweepAngle,
    required this.themeColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.45;

    // Grid lines paint
    final gridPaint = Paint()
      ..color = themeColor.withValues(alpha: isDark ? 0.08 : 0.04)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Concentric grid circles
    for (double i = 0.2; i <= 1.0; i += 0.2) {
      canvas.drawCircle(center, maxRadius * i, gridPaint);
    }

    // Grid crosshairs
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), gridPaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), gridPaint);

    // Diagonal auxiliary lines
    canvas.drawLine(
      Offset(center.dx - maxRadius * 0.707, center.dy - maxRadius * 0.707),
      Offset(center.dx + maxRadius * 0.707, center.dy + maxRadius * 0.707),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx - maxRadius * 0.707, center.dy + maxRadius * 0.707),
      Offset(center.dx + maxRadius * 0.707, center.dy - maxRadius * 0.707),
      gridPaint,
    );

    // Sweep cone paint (glowing scanning effect)
    final sweepPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          themeColor.withValues(alpha: 0.15),
          themeColor.withValues(alpha: 0.03),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: maxRadius),
        sweepAngle - 0.4,
        0.4,
        false,
      )
      ..close();

    canvas.drawPath(path, sweepPaint);

    // Dynamic scanning edge ray
    final edgePaint = Paint()
      ..color = themeColor.withValues(alpha: 0.4)
      ..strokeWidth = 1.5;
    
    final edgeX = center.dx + maxRadius * math.cos(sweepAngle);
    final edgeY = center.dy + math.sin(sweepAngle) * maxRadius;
    canvas.drawLine(center, Offset(edgeX, edgeY), edgePaint);
  }

  @override
  bool shouldRepaint(covariant HologramRadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.themeColor != themeColor ||
        oldDelegate.isDark != isDark;
  }
}

class DialectDrillScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const DialectDrillScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.dialectDrill,
  });

  @override
  State<DialectDrillScreen> createState() => _DialectDrillScreenState();
}

class _DialectDrillScreenState extends State<DialectDrillScreen> with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  late AnimationController _radarController;
  int _lastProcessedIndex = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  
  // Responsive layout state values
  bool _isPinInitialized = false;
  double _pinX = 0;
  double _pinY = 0;
  int? _hoveredTowerIndex;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    context.read<AccentBloc>().add(FetchAccentQuests(gameType: widget.gameType, level: widget.level));
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(AccentQuest quest) {
    // Determine target pronunciation voice locale
    final instruction = quest.instruction;
    final String targetLocale = instruction.contains("British") ? "en-GB" : "en-US";
    _soundService.playTts(quest.word ?? "", locale: targetLocale);
  }

  void _onPinDragUpdate(DragUpdateDetails details, double maxWidth) {
    if (_isAnswered) return;
    setState(() {
      _pinX += details.delta.dx;
      _pinY += details.delta.dy;
      
      // Clamp boundaries inside coordinates zone
      _pinX = _pinX.clamp(20.w, maxWidth - 20.w);
      _pinY = _pinY.clamp(40.h, 380.h);
    });
    
    // Check tower proximity
    _checkTowerHover(maxWidth);
  }

  void _checkTowerHover(double maxWidth) {
    double leftTargetX = (maxWidth / 2) - 90.w;
    double rightTargetX = (maxWidth / 2) + 90.w;
    double targetY = 170.h;

    double distanceToLeft = math.sqrt(math.pow(_pinX - leftTargetX, 2) + math.pow(_pinY - targetY, 2));
    double distanceToRight = math.sqrt(math.pow(_pinX - rightTargetX, 2) + math.pow(_pinY - targetY, 2));

    if (distanceToLeft < 60.r) {
      if (_hoveredTowerIndex != 0) {
        _hapticService.selection();
        setState(() => _hoveredTowerIndex = 0);
      }
    } else if (distanceToRight < 60.r) {
      if (_hoveredTowerIndex != 1) {
        _hapticService.selection();
        setState(() => _hoveredTowerIndex = 1);
      }
    } else {
      if (_hoveredTowerIndex != null) {
        setState(() => _hoveredTowerIndex = null);
      }
    }
  }

  void _onPinDragEnd(double maxWidth, int correctIndex) {
    if (_isAnswered) return;

    if (_hoveredTowerIndex == null) {
      // Return pin to starting position
      setState(() {
        _pinX = maxWidth / 2;
        _pinY = 320.h;
      });
      return;
    }

    _submitAnswer(_hoveredTowerIndex!, correctIndex, maxWidth);
  }

  void _submitAnswer(int index, int correct, double maxWidth) {
    if (_isAnswered) return;
    bool isCorrect = index == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
        // Lock pin to exact target location
        _pinX = (maxWidth / 2) + (index == 0 ? -90.w : 90.w);
        _pinY = 170.h;
      });
      context.read<AccentBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        // Lock pin to exact target location
        _pinX = (maxWidth / 2) + (index == 0 ? -90.w : 90.w);
        _pinY = 170.h;
      });
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('accent', level: widget.level);

    return BlocConsumer<AccentBloc, AccentState>(
      listener: (context, state) {
        if (state is AccentLoaded) {
          if (state.currentIndex != _lastProcessedIndex) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isPinInitialized = false;
              _hoveredTowerIndex = null;
            });
            // Auto play correct pronunciation context
            Future.delayed(const Duration(milliseconds: 350), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          }
        }
        if (state is AccentGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'DIALECT EXPERT!',
            enableDoubleUp: true,
          );
        } else if (state is AccentGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<AccentBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final quest = (state is AccentLoaded) ? state.currentQuest : null;

        // Parse British vs American pronunciations for comparison board
        String brPr = "";
        String amPr = "";
        if (quest != null && quest.options != null) {
          for (var opt in quest.options!) {
            if (opt.contains('(British)')) {
              brPr = opt.replaceAll(' (British)', '');
            } else if (opt.contains('(American)')) {
              amPr = opt.replaceAll(' (American)', '');
            }
          }
        }

        return AccentBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<AccentBloc>().add(NextQuestion()),
          onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
          child: quest == null
              ? const SizedBox()
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  child: Column(
                    children: [
                      _buildHeaderInstruction(quest, theme.primaryColor),
                      SizedBox(height: 16.h),
                      _buildHologramGridConsole(quest, theme.primaryColor, isDark),
                      SizedBox(height: 20.h),
                      
                      // Secondary Console Status display or Feedback comparison panel
                      AnimatedCrossFade(
                        firstChild: _buildConsoleStatusTele(theme.primaryColor, isDark),
                        secondChild: DialectFeedbackPanel(
                          isCorrect: _isCorrect ?? false,
                          word: quest.word ?? "",
                          britishPronunciation: brPr.isEmpty ? (quest.word ?? "") : brPr,
                          americanPronunciation: amPr.isEmpty ? (quest.word ?? "") : amPr,
                          hint: quest.hint ?? "Dialect variants represent rich cultural history.",
                          isDark: isDark,
                          isMidnight: false,
                          onPlayAudio: (text, locale) {
                            _soundService.playTts(text, locale: locale);
                          },
                        ),
                        crossFadeState: _isAnswered
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 400),
                      ),
                      SizedBox(height: 80.h), // Safe spacing for navigation buttons
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeaderInstruction(AccentQuest quest, Color accentColor) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: accentColor.withValues(alpha: 0.2)),
          ),
          child: Text(
            "RADAR FREQUENCY DIALECT SWITCH",
            style: GoogleFonts.outfit(
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: accentColor,
              letterSpacing: 2.5,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          quest.instruction,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHologramGridConsole(AccentQuest quest, Color color, bool isDark) {
    final Color outerGlow = color.withValues(alpha: 0.3);

    return Container(
      width: 1.sw,
      height: 380.h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1B) : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(36.r),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: outerGlow,
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36.r),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Initializing Pin location in the LayoutBuilder dynamically
            if (!_isPinInitialized) {
              _pinX = constraints.maxWidth / 2;
              _pinY = 320.h;
              _isPinInitialized = true;
            }

            return Stack(
              children: [
                // Radar sweep background animation
                AnimatedBuilder(
                  animation: _radarController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: HologramRadarPainter(
                        sweepAngle: _radarController.value * 2 * math.pi,
                        themeColor: color,
                        isDark: isDark,
                      ),
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                    );
                  },
                ),

                // Center Target Word Orb
                Center(
                  child: Transform.translate(
                    offset: Offset(0, -90.h),
                    child: ScaleButton(
                      onTap: () => _triggerAutoPlay(quest),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: color.withValues(alpha: 0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.2),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.volume_up_rounded, color: color, size: 24.r),
                            SizedBox(width: 8.w),
                            Text(
                              quest.word ?? "",
                              style: GoogleFonts.outfit(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w900,
                                color: color,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Regional Transmission Towers
                _buildTransmissionTower(0, quest.options != null && quest.options!.isNotEmpty ? quest.options![0] : "TRANS 01", constraints.maxWidth, color, isDark),
                _buildTransmissionTower(1, quest.options != null && quest.options!.length > 1 ? quest.options![1] : "TRANS 02", constraints.maxWidth, color, isDark),

                // Dragging Probe Pin
                _buildDataProbePin(color, quest.correctAnswerIndex ?? 0, constraints.maxWidth),
              ],
            );
          },
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildTransmissionTower(int index, String label, double maxWidth, Color color, bool isDark) {
    final isLeft = index == 0;
    final double targetX = (maxWidth / 2) + (isLeft ? -90.w : 90.w);
    final double targetY = 170.h;
    final bool isHovered = _hoveredTowerIndex == index;
    
    // Choose neon accent based on correct selection locking state
    Color towerColor = color;
    if (_isAnswered && _hoveredTowerIndex == index) {
      towerColor = (_isCorrect ?? false) ? Colors.greenAccent : Colors.redAccent;
    } else if (isHovered) {
      towerColor = color;
    } else {
      towerColor = color.withValues(alpha: 0.35);
    }

    // Strip out (British) or (American) tag for cleaner button telemetry
    String cleanLabel = label;
    if (label.contains(' (British)')) {
      cleanLabel = "[BRITISH] ${label.replaceAll(' (British)', '')}";
    } else if (label.contains(' (American)')) {
      cleanLabel = "[AMERICAN] ${label.replaceAll(' (American)', '')}";
    }

    return Positioned(
      left: targetX - 60.w,
      top: targetY - 70.h,
      child: SizedBox(
        width: 120.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Pulse waves animation for active telemetry
                if (isHovered || (_isAnswered && _hoveredTowerIndex == index))
                  Container(
                    width: 72.r,
                    height: 72.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: towerColor.withValues(alpha: 0.3), width: 2),
                    ),
                  ).animate(onPlay: (c) => c.repeat()).scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.5, 1.5),
                    duration: 1.2.seconds,
                  ).fadeOut(),

                // Glowing background plate
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black38 : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isHovered
                          ? towerColor
                          : towerColor.withValues(alpha: 0.2),
                      width: isHovered ? 2.0 : 1.0,
                    ),
                    boxShadow: [
                      if (isHovered)
                        BoxShadow(
                          color: towerColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                        ),
                    ],
                  ),
                  child: Icon(
                    Icons.settings_input_antenna_rounded,
                    size: 32.r,
                    color: towerColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            
            // Neon data tags
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: isHovered
                    ? towerColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: isHovered
                      ? towerColor.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              child: Text(
                cleanLabel,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: isHovered ? towerColor : towerColor.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataProbePin(Color color, int correctIndex, double maxWidth) {
    final bool hasTargetGlow = _hoveredTowerIndex != null;
    Color pinColor = color;
    if (_isAnswered) {
      pinColor = (_isCorrect ?? false) ? Colors.greenAccent : Colors.redAccent;
    }

    return Positioned(
      left: _pinX - 25.w,
      top: _pinY - 25.h,
      child: GestureDetector(
        onPanUpdate: (details) => _onPinDragUpdate(details, maxWidth),
        onPanEnd: (_) => _onPinDragEnd(maxWidth, correctIndex),
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Lock on particle rings
              if (hasTargetGlow && !_isAnswered)
                Container(
                  width: 58.r,
                  height: 58.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.greenAccent.withValues(alpha: 0.6),
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.2, 1.2),
                  duration: 600.ms,
                ),

              Container(
                width: 50.r,
                height: 50.r,
                decoration: BoxDecoration(
                  color: pinColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: pinColor, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: pinColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _isAnswered
                      ? ((_isCorrect ?? false) ? Icons.verified_rounded : Icons.warning_amber_rounded)
                      : Icons.gps_fixed_rounded,
                  size: 24.r,
                  color: pinColor,
                ).animate(
                  onPlay: (c) => c.repeat(reverse: true),
                ).scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.1, 1.1),
                  duration: 800.ms,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsoleStatusTele(Color color, bool isDark) {
    return Container(
      width: 1.sw,
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.radar_rounded, color: color.withValues(alpha: 0.7), size: 18.r)
              .animate(onPlay: (c) => c.repeat())
              .rotate(duration: 3.seconds),
          SizedBox(width: 10.w),
          Text(
            "TELEMETRY PROBE READY FOR REGIONAL ASSIGNMENT",
            style: GoogleFonts.shareTechMono(
              fontSize: 10.sp,
              color: isDark ? Colors.white60 : Colors.black54,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
