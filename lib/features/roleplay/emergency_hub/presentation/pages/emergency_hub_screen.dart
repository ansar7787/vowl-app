import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/widgets/roleplay_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';

// Heavy industrial hazard spoke and warning dial painter
class EmergencyValvePainter extends CustomPainter {
  final double rotationValue;
  final bool isCodeCorrect;
  final double animationTime;

  EmergencyValvePainter({
    required this.rotationValue,
    required this.isCodeCorrect,
    required this.animationTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);

    // Hazard yellow/black warning outer stripes track
    final Paint hazardPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.w;

    final int numStripes = 24;
    for (int i = 0; i < numStripes; i++) {
      final double angleStart = (i * 2 * math.pi / numStripes);
      final double sweep = math.pi / numStripes;

      hazardPaint.color = (i % 2 == 0)
          ? Colors.amberAccent
          : Colors.black87;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 8.w),
        angleStart + (animationTime * 0.5),
        sweep,
        false,
        hazardPaint,
      );
    }

    // Outer thick pressure steel track
    final Paint steelTrackPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 4.w
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 16.w, steelTrackPaint);

    // Indicator sectors (AWAITING / ALIGNED)
    final Paint sectorPaint = Paint()
      ..color = isCodeCorrect ? Colors.redAccent.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 20.w, sectorPaint);
  }

  @override
  bool shouldRepaint(covariant EmergencyValvePainter oldDelegate) {
    return oldDelegate.rotationValue != rotationValue ||
        oldDelegate.isCodeCorrect != isCodeCorrect ||
        oldDelegate.animationTime != animationTime;
  }
}

class EmergencyHubScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const EmergencyHubScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.emergencyHub,
  });

  @override
  State<EmergencyHubScreen> createState() => _EmergencyHubScreenState();
}

class _EmergencyHubScreenState extends State<EmergencyHubScreen> with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  late AnimationController _pulseController;
  late TextEditingController _codeController;
  
  int _lastProcessedIndex = -1;
  double _rotation = 0.0; // Valve rotation progress (0.0 to 1.0)
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _codeController = TextEditingController();
    
    context.read<RoleplayBloc>().add(FetchRoleplayQuests(gameType: widget.gameType, level: widget.level));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(RoleplayQuest quest) {
    _soundService.playTts(quest.instruction);
    if (quest.dispatcherQuestion != null) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) _soundService.playTts(quest.dispatcherQuestion!);
      });
    }
  }

  // Trigonometry-based circular dial update
  void _onValveDragged(DragUpdateDetails details, Offset localCenter) {
    if (_isAnswered) return;

    final Offset touchPos = details.localPosition;
    final double dx = touchPos.dx - localCenter.dx;
    final double dy = touchPos.dy - localCenter.dy;

    double angle = math.atan2(dy, dx);
    if (angle < 0) angle += 2 * math.pi;

    // Convert angle starting from top-center (-pi/2) to decimal (0.0 to 1.0)
    double progress = (angle + math.pi / 2) / (2 * math.pi);
    if (progress > 1.0) progress -= 1.0;

    _hapticService.selection();
    setState(() {
      _rotation = progress.clamp(0.0, 1.0);
    });
  }

  void _submitCode(String input, String correctAnswer) {
    if (_isAnswered) return;

    final String cleanInput = input.trim().replaceAll(' ', '').toLowerCase();
    final String cleanCorrect = correctAnswer.trim().replaceAll(' ', '').toLowerCase();

    // Check if code matches AND safety valve is rotated past 85% to pressurize the lock
    final bool codeMatches = cleanInput == cleanCorrect;
    final bool valveAligned = _rotation >= 0.85;

    final bool isCorrect = codeMatches && valveAligned;

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

    return BlocConsumer<RoleplayBloc, RoleplayState>(
      listener: (context, state) {
        if (state is RoleplayLoaded) {
          if (state.currentIndex != _lastProcessedIndex) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _rotation = 0.0;
              _codeController.clear();
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
            title: 'HERO DISPATCHER!',
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
                      _buildHeaderInstruction(),
                      SizedBox(height: 16.h),
                      
                      // Critical dispatcher prompt telex
                      _buildDispatcherTelex(quest.dispatcherQuestion ?? "AWAITING BROADCAST VECTOR DETAILS...", isDark),
                      SizedBox(height: 20.h),

                      // Retro terminal input text field
                      _buildTerminalInput(quest.correctAnswer ?? "", isDark),
                      SizedBox(height: 20.h),

                      // Mechanical safety valve chamber
                      _buildMechanicalValveChamber(quest.correctAnswer ?? "", isDark),
                      SizedBox(height: 24.h),

                      // Dispatch lock confirm trigger button
                      if (!_isAnswered && _codeController.text.isNotEmpty)
                        ScaleButton(
                          onTap: () => _submitCode(_codeController.text, quest.correctAnswer ?? ""),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 48.w, vertical: 14.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30.r),
                              gradient: const LinearGradient(
                                colors: [Colors.redAccent, Colors.deepOrangeAccent],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.redAccent.withValues(alpha: 0.45),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flash_on_rounded, color: Colors.white, size: 18.r),
                                SizedBox(width: 8.w),
                                Text(
                                  "LAUNCH EMERGENCY BEACON",
                                  style: GoogleFonts.shareTechMono(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(duration: 300.ms),

                      // Review details
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

  Widget _buildHeaderInstruction() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
          ),
          child: Text(
            "SECTOR DISPATCH STATION",
            style: GoogleFonts.outfit(
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: Colors.redAccent,
              letterSpacing: 2.5,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          "Authenticate terminal code and spin safety valve to route unit!",
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

  Widget _buildDispatcherTelex(String telex, bool isDark) {
    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withValues(alpha: 0.08),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20.r),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.15, 1.15),
                    duration: 1.2.seconds,
                    curve: Curves.easeInOut,
                  ),
              SizedBox(width: 10.w),
              Text(
                "CRITICAL INCOMING HAZARD ALERT",
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp,
                  color: Colors.redAccent,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            telex,
            style: GoogleFonts.fredoka(
              fontSize: 18.sp,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalInput(String correctAnswer, bool isDark) {
    final bool isCodeValid = _codeController.text.trim().replaceAll(' ', '').toLowerCase() ==
        correctAnswer.trim().replaceAll(' ', '').toLowerCase();

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF07070F) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(28.r),
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
                "DECRYPTION KEYBOARD SLATE",
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp,
                  color: isCodeValid ? Colors.greenAccent : Colors.amberAccent,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                isCodeValid ? Icons.vpn_key_rounded : Icons.keyboard_rounded,
                color: isCodeValid ? Colors.greenAccent : Colors.amberAccent,
                size: 16.r,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          TextField(
            controller: _codeController,
            onChanged: (text) => setState(() {}),
            style: GoogleFonts.shareTechMono(
              fontSize: 18.sp,
              color: isCodeValid ? Colors.greenAccent : Colors.redAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              hintText: "ENTER CODE (e.g. CODE RED 99)",
              hintStyle: GoogleFonts.shareTechMono(
                fontSize: 14.sp,
                color: isDark ? Colors.white24 : Colors.black26,
                letterSpacing: 1.5,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F0F1B) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: isCodeValid ? Colors.greenAccent.withValues(alpha: 0.4) : Colors.redAccent.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: isCodeValid ? Colors.greenAccent : Colors.redAccent,
                  width: 2,
                ),
              ),
              prefixIcon: Icon(
                Icons.terminal_rounded,
                color: isCodeValid ? Colors.greenAccent : Colors.redAccent,
                size: 20.r,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMechanicalValveChamber(String correctAnswer, bool isDark) {
    final double size = 200.r;
    final Offset center = Offset(size / 2, size / 2);
    
    final bool isCodeValid = _codeController.text.trim().replaceAll(' ', '').toLowerCase() ==
        correctAnswer.trim().replaceAll(' ', '').toLowerCase();
    
    final bool isValveAligned = _rotation >= 0.85;

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
          GestureDetector(
            onPanUpdate: (details) => _onValveDragged(details, center),
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Hazard stripes warning outer sweep ring
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: EmergencyValvePainter(
                            rotationValue: _rotation,
                            isCodeCorrect: isCodeValid,
                            animationTime: _pulseController.value,
                          ),
                        );
                      },
                    ),
                  ),

                  // Heavy metal wheel knob
                  Transform.rotate(
                    angle: _rotation * 2 * math.pi,
                    child: Container(
                      width: 120.r,
                      height: 120.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade900,
                        border: Border.all(
                          color: isValveAligned ? Colors.greenAccent : Colors.redAccent,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Spokes
                          for (int i = 0; i < 3; i++)
                            Transform.rotate(
                              angle: i * 2 * math.pi / 3,
                              child: Container(
                                width: 8.w,
                                height: 96.h,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          
                          // Centre locking warning lens
                          Container(
                            width: 50.r,
                            height: 50.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isValveAligned ? Colors.greenAccent : Colors.redAccent,
                              boxShadow: [
                                BoxShadow(
                                  color: (isValveAligned ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(
                              isValveAligned ? Icons.lock_open_rounded : Icons.lock_rounded,
                              color: Colors.white,
                              size: 24.r,
                            ),
                          ),

                          // Indicator needle notch
                          Positioned(
                            top: 6.r,
                            child: Icon(
                              Icons.arrow_drop_up_rounded,
                              color: isValveAligned ? Colors.greenAccent : Colors.white70,
                              size: 24.r,
                            ),
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

          // Valve status indicators text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "VALVE LEVEL: ",
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp,
                  color: Colors.grey,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                isValveAligned ? "ALIGNED (READY)" : "LOCK PENDING (TURN TO 90%)",
                style: GoogleFonts.shareTechMono(
                  fontSize: 11.sp,
                  color: isValveAligned ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold,
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
                (_isCorrect ?? false) ? "Emergency Dispatched!" : "Dispatch Vector Denied!",
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
            quest.explanation ?? "Correlating critical emergency commands with physical valve locks stimulates rapid verbal context memory retention.",
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
