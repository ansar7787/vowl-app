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

// Spinning Holographic Reactor Ring representing professionalism score
class ProfessionalismFusionPainter extends CustomPainter {
  final double animationValue;
  final double professionalismLevel;
  final Color themeColor;

  ProfessionalismFusionPainter({
    required this.animationValue,
    required this.professionalismLevel,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);

    Color fusionColor = themeColor;
    if (professionalismLevel > 0.6) {
      fusionColor = Colors.greenAccent;
    } else if (professionalismLevel < 0.3) {
      fusionColor = Colors.redAccent;
    }

    // Draw background dim tracker circle
    final Paint trackPaint = Paint()
      ..color = fusionColor.withValues(alpha: 0.1)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 6, trackPaint);

    // Draw glowing professional level arc
    final Paint arcPaint = Paint()
      ..color = fusionColor
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final double sweepAngle = 2 * math.pi * professionalismLevel;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );

    // Draw three revolving telemetry sparks inside the ring
    final Paint sparkPaint = Paint()
      ..color = fusionColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      double sparkAngle = (animationValue * 2 * math.pi) + (i * 2 * math.pi / 3);
      double sx = center.dx + (radius - 6) * math.cos(sparkAngle);
      double sy = center.dy + (radius - 6) * math.sin(sparkAngle);
      canvas.drawCircle(Offset(sx, sy), 3.r, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ProfessionalismFusionPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.professionalismLevel != professionalismLevel ||
        oldDelegate.themeColor != themeColor;
  }
}

class JobInterviewScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const JobInterviewScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.jobInterview,
  });

  @override
  State<JobInterviewScreen> createState() => _JobInterviewScreenState();
}

class _JobInterviewScreenState extends State<JobInterviewScreen> with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  late AnimationController _reactorController;
  
  int _lastProcessedIndex = -1;
  int? _selectedIndex;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  
  // Track professionalism thermometer score (default start at 0.5)
  double _mercuryLevel = 0.5;

  @override
  void initState() {
    super.initState();
    _reactorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    context.read<RoleplayBloc>().add(FetchRoleplayQuests(gameType: widget.gameType, level: widget.level));
  }

  @override
  void dispose() {
    _reactorController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(RoleplayQuest quest) {
    _soundService.playTts(quest.instruction);
    if (quest.interviewerQuestion != null) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) _soundService.playTts(quest.interviewerQuestion!);
      });
    }
  }

  void _onOptionSelected(int index, int correctIndex) {
    if (_isAnswered) return;

    final bool isCorrect = index == correctIndex;

    setState(() {
      _selectedIndex = index;
      _isAnswered = true;
      _isCorrect = isCorrect;
      
      // Update professionalism mercury meter dynamically
      if (isCorrect) {
        _mercuryLevel = (_mercuryLevel + 0.25).clamp(0.0, 1.0);
      } else {
        _mercuryLevel = (_mercuryLevel - 0.2).clamp(0.0, 1.0);
      }
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
              _selectedIndex = null;
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
            title: 'CORPORATE LEADER!',
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
        final options = quest?.options ?? [];

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

                      // Professionalism telemetry reactor bar
                      _buildTelemetryDashboard(theme.primaryColor, isDark),
                      SizedBox(height: 24.h),

                      // Holographic Interviewer Dialog Bubble
                      _buildInterviewerPanel(quest.interviewerQuestion ?? "", theme.primaryColor, isDark),
                      SizedBox(height: 24.h),

                      // Option response cards
                      _buildResponseConsole(options, quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
                      SizedBox(height: 20.h),

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
            "BOARDROOM INTERVIEW SIMULATOR",
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
          "Select the answer that maximizes your Professionalism Rating",
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

  Widget _buildTelemetryDashboard(Color color, bool isDark) {
    Color ringColor = color;
    if (_mercuryLevel > 0.6) {
      ringColor = Colors.greenAccent;
    } else if (_mercuryLevel < 0.3) {
      ringColor = Colors.redAccent;
    }

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // Circular Fusion Reactor
          SizedBox(
            width: 72.r,
            height: 72.r,
            child: AnimatedBuilder(
              animation: _reactorController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ProfessionalismFusionPainter(
                    animationValue: _reactorController.value,
                    professionalismLevel: _mercuryLevel,
                    themeColor: color,
                  ),
                );
              },
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PROFESSIONAL HARMONICS:",
                  style: GoogleFonts.shareTechMono(
                    fontSize: 9.sp,
                    color: ringColor,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "${(_mercuryLevel * 100).toInt()}% COMPATIBLE",
                  style: GoogleFonts.outfit(
                    fontSize: 18.sp,
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6.h),
                // Horizontal tracking bar indicator
                Container(
                  height: 6.h,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _mercuryLevel,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: ringColor,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterviewerPanel(String text, Color color, bool isDark) {
    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF07070F) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.business_center_rounded, color: color, size: 20.r),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CHIEF EXECUTIVE V-407",
                    style: GoogleFonts.shareTechMono(
                      fontSize: 10.sp,
                      color: color,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    "ACTIVE BIO-TRANSCEIVER",
                    style: GoogleFonts.shareTechMono(
                      fontSize: 7.sp,
                      color: color.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: color.withValues(alpha: 0.05)),
            ),
            child: Text(
              text,
              style: GoogleFonts.fredoka(
                fontSize: 18.sp,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildResponseConsole(List<String> options, int correctIndex, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(
        options.length,
        (i) => _buildResponseStone(i, options[i], correctIndex, color, isDark),
      ),
    );
  }

  Widget _buildResponseStone(int index, String text, int correctIndex, Color color, bool isDark) {
    final bool isSelected = _selectedIndex == index;

    Color stoneColor = color;
    if (_isAnswered) {
      if (isSelected) {
        stoneColor = (_isCorrect ?? false) ? Colors.greenAccent : Colors.redAccent;
      } else if (index == correctIndex) {
        stoneColor = Colors.greenAccent; // Highlight correct answer if incorrect chosen
      }
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: ScaleButton(
        onTap: () => _onOptionSelected(index, correctIndex),
        child: Container(
          padding: EdgeInsets.all(18.r),
          decoration: BoxDecoration(
            color: isSelected
                ? stoneColor
                : (isDark ? const Color(0xFF0F0F1B) : Colors.white),
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: isSelected
                  ? Colors.white
                  : (_isAnswered && index == correctIndex)
                      ? Colors.greenAccent
                      : color.withValues(alpha: 0.35),
              width: (isSelected || (_isAnswered && index == correctIndex)) ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isSelected ? stoneColor : color).withValues(alpha: isSelected ? 0.35 : 0.06),
                blurRadius: isSelected ? 12 : 6,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSelected
                      ? ((_isCorrect ?? false) ? Icons.verified_rounded : Icons.cancel_rounded)
                      : Icons.diamond_rounded,
                  color: isSelected ? Colors.white : color,
                  size: 16.r,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : (_isAnswered && index == correctIndex)
                            ? (isDark ? Colors.greenAccent : Colors.green)
                            : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(
      target: isSelected ? 1.0 : 0.0,
    ).scale(
      begin: const Offset(1, 1),
      end: const Offset(1.02, 1.02),
      duration: 150.ms,
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
                (_isCorrect ?? false) ? "Corporate Match OK!" : "Response Evaluation Rejected!",
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
            quest.explanation ?? "Syntactic professional choices reinforce active corporate communication skills and real-world executive fluency.",
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
