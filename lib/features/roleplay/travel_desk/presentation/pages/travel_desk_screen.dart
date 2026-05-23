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
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';

// Visual particle ink slam ripple effect
class StampRipplePainter extends CustomPainter {
  final Offset impactOffset;
  final double animationValue;
  final Color themeColor;

  StampRipplePainter({
    required this.impactOffset,
    required this.animationValue,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (animationValue == 0 || animationValue == 1) return;

    final Paint ringPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.8 * (1.0 - animationValue))
      ..strokeWidth = 3.0 * (1.0 - animationValue)
      ..style = PaintingStyle.stroke;

    final Paint auraPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.25 * (1.0 - animationValue))
      ..style = PaintingStyle.fill;

    double radius = 40.r * animationValue;
    
    // Draw expanding shockwave ring
    canvas.drawCircle(impactOffset, radius, ringPaint);
    canvas.drawCircle(impactOffset, radius * 0.7, auraPaint);

    // Draw little flying ink particles
    final Paint sparkPaint = Paint()
      ..color = themeColor.withValues(alpha: 1.0 - animationValue)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      double angle = i * math.pi / 4;
      double dist = radius * 1.2;
      double px = impactOffset.dx + dist * math.cos(angle);
      double py = impactOffset.dy + dist * math.sin(angle);
      canvas.drawCircle(Offset(px, py), 2.5.r * (1.0 - animationValue), sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant StampRipplePainter oldDelegate) {
    return oldDelegate.impactOffset != impactOffset ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.themeColor != themeColor;
  }
}

class TravelDeskScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const TravelDeskScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.travelDesk,
  });

  @override
  State<TravelDeskScreen> createState() => _TravelDeskScreenState();
}

class _TravelDeskScreenState extends State<TravelDeskScreen> with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  late AnimationController _rippleController;
  late AnimationController _pulseController;
  
  int _lastProcessedIndex = -1;
  int? _selectedIndex;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  
  // Custom drag feedback coordinates
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    context.read<RoleplayBloc>().add(FetchRoleplayQuests(gameType: widget.gameType, level: widget.level));
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(RoleplayQuest quest) {
    _soundService.playTts(quest.instruction);
    if (quest.prompt != null) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) _soundService.playTts(quest.prompt!);
      });
    }
  }

  void _submitStamp(int index, int correctIndex) {
    if (_isAnswered) return;

    setState(() {
      _selectedIndex = index;
      _isAnswered = true;
      _isCorrect = index == correctIndex;
    });

    _rippleController.forward(from: 0.0);

    if (index == correctIndex) {
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
              _hoveredIndex = null;
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
            title: 'GLOBAL TRAVELER!',
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
                      _buildCustomsTerminal(quest.prompt ?? "", theme.primaryColor, isDark),
                      SizedBox(height: 24.h),
                      
                      // Biometric Passport Book
                      _buildPassportBook(options, theme.primaryColor, quest.correctAnswerIndex ?? 0, isDark),
                      SizedBox(height: 32.h),

                      // Stamp slammed terminal console
                      if (!_isAnswered)
                        _buildStampSlamStation(theme.primaryColor, isDark)
                      else
                        _buildExplanationCard(quest, isDark),
                      
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
            "CUSTOMS BIOMETRIC OFFICE",
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
          "Drag the mechanical visa stamp onto the matching destination page",
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

  Widget _buildCustomsTerminal(String prompt, Color color, bool isDark) {
    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
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
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.flight_takeoff_rounded, color: color, size: 24.r),
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
                  "TRAVELER DECLARED REQUEST:",
                  style: GoogleFonts.shareTechMono(
                    fontSize: 10.sp,
                    color: color,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  "\"$prompt\"",
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

  Widget _buildPassportBook(List<String> options, Color color, int correctIndex, bool isDark) {
    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF06060E) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "BIOMETRIC PASSPORT BOOKLET",
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp,
                  color: color.withValues(alpha: 0.7),
                  letterSpacing: 1.5,
                ),
              ),
              Icon(Icons.menu_book_rounded, color: color.withValues(alpha: 0.5), size: 16.r),
            ],
          ),
          SizedBox(height: 16.h),

          // Horizontal scroll layout matching booklet pages without overflow crash
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                options.length,
                (i) => _buildDragTargetPage(i, options[i], color, correctIndex, isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragTargetPage(int index, String text, Color color, int correctIndex, bool isDark) {
    final bool isSelected = _selectedIndex == index;
    final bool isHovered = _hoveredIndex == index;

    Color borderColor = color.withValues(alpha: 0.15);
    if (isHovered && !_isAnswered) {
      borderColor = color;
    } else if (isSelected) {
      borderColor = (_isCorrect ?? false) ? Colors.greenAccent : Colors.redAccent;
    }

    return DragTarget<int>(
      onWillAcceptWithDetails: (data) => !_isAnswered,
      onAcceptWithDetails: (details) {
        _submitStamp(index, correctIndex);
      },
      onMove: (details) {
        if (_hoveredIndex != index) {
          _hapticService.selection();
          setState(() => _hoveredIndex = index);
        }
      },
      onLeave: (data) {
        setState(() => _hoveredIndex = null);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 110.w,
          height: 165.h,
          margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: borderColor,
              width: (isSelected || isHovered) ? 3.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isSelected || isHovered)
                    ? (isSelected
                        ? ((_isCorrect ?? false) ? Colors.greenAccent : Colors.redAccent)
                        : color).withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: (isSelected || isHovered) ? 14 : 6,
                spreadRadius: (isSelected || isHovered) ? 1 : 0,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Retro grid lines inside passport book
              Positioned.fill(
                child: CustomPaint(
                  painter: _PassportBackgroundGrid(color: color.withValues(alpha: 0.04)),
                ),
              ),

              // Page contents
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 14.h),
                child: Column(
                  children: [
                    Icon(
                      Icons.public_rounded,
                      color: color.withValues(alpha: isHovered ? 0.35 : 0.12),
                      size: 28.r,
                    ),
                    const Spacer(),
                    Text(
                      text.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.shareTechMono(
                        fontSize: 12.sp,
                        color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "PAGE 0${index + 1}",
                      style: GoogleFonts.shareTechMono(
                        fontSize: 8.sp,
                        color: color.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),

              // Glowing stamp thud ink ripple overlay
              if (isSelected)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _rippleController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: StampRipplePainter(
                          impactOffset: Offset(55.w, 82.h),
                          animationValue: _rippleController.value,
                          themeColor: (_isCorrect ?? false) ? Colors.greenAccent : Colors.redAccent,
                        ),
                      );
                    },
                  ),
                ),

              // Stamp mark locked on page
              if (isSelected)
                Center(
                  child: Transform.rotate(
                    angle: -0.22,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: (_isCorrect ?? false) ? Colors.greenAccent : Colors.redAccent,
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                        color: Colors.black.withValues(alpha: 0.1),
                      ),
                      child: Text(
                        (_isCorrect ?? false) ? "APPROVED" : "DENIED",
                        style: GoogleFonts.shareTechMono(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w900,
                          color: (_isCorrect ?? false) ? Colors.greenAccent : Colors.redAccent,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ).animate().scale(
                        duration: 200.ms,
                        curve: Curves.elasticOut,
                        begin: const Offset(3.5, 3.5),
                        end: const Offset(1, 1),
                      ),
                ),
            ],
          ),
        ).animate(
          target: isHovered ? 1.0 : 0.0,
        ).scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 150.ms,
        );
      },
    );
  }

  Widget _buildStampSlamStation(Color color, bool isDark) {
    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_rounded, color: color, size: 16.r),
              SizedBox(width: 8.w),
              Text(
                "STAMP SLAM TERMINAL",
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp,
                  color: color,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),

          // Metallic mechanical stamp draggable
          Draggable<int>(
            data: 99, // Dummy pay payload
            onDragStarted: () {
              _hapticService.selection();
              _soundService.playHint(); // Play synth note
            },
            onDragEnd: (details) {
              setState(() => _hoveredIndex = null);
            },
            feedback: _buildStampCore(color, isGlowing: true),
            childWhenDragging: Opacity(
              opacity: 0.25,
              child: _buildStampCore(color, isGlowing: false),
            ),
            child: _buildStampCore(color, isGlowing: false),
          ),

          SizedBox(height: 14.h),
          Text(
            "DRAG STAMP UPWARDS TO SLAM ON TARGET",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildStampCore(Color color, {required bool isGlowing}) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72.r,
            height: 80.r,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16.r),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color,
                  color.withValues(alpha: 0.75),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: isGlowing ? 0.65 : 0.35),
                  blurRadius: isGlowing ? 20 : 12,
                  offset: const Offset(0, 4),
                  spreadRadius: isGlowing ? 2 : 0,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.approval_rounded,
                color: Colors.white,
                size: 32.r,
              ),
            ),
          ).animate(
            onPlay: (c) => c.repeat(reverse: true),
          ).scale(
            begin: const Offset(1, 1),
            end: const Offset(1.05, 1.05),
            duration: 2.seconds,
            curve: Curves.easeInOut,
          ),
          SizedBox(height: 4.h),
          Container(
            width: 86.w,
            height: 10.h,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(5.r),
            ),
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
                (_isCorrect ?? false) ? "Customs Check OK" : "Visa Clearance Rejected",
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
            quest.explanation ?? "Matching customer intents with the correct travel destination builds vocabulary and listening comprehension.",
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

// Background Grid custom painter for authentic passport passport book
class _PassportBackgroundGrid extends CustomPainter {
  final Color color;
  _PassportBackgroundGrid({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    double spacing = 12.r;

    // Draw vertical lines
    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Draw horizontal lines
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PassportBackgroundGrid oldDelegate) {
    return oldDelegate.color != color;
  }
}
