import 'dart:math';
import 'dart:ui' as ui;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:voxai_quest/core/utils/ad_service.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';

class DailyMysterySpinOverlay extends StatefulWidget {
  const DailyMysterySpinOverlay({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<DailyMysterySpinOverlay> createState() =>
      _DailyMysterySpinOverlayState();
}

class _DailyMysterySpinOverlayState extends State<DailyMysterySpinOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  late ConfettiController _confettiController;

  bool _isSpinning = false;
  bool _spinFinished = false;
  int _rewardAmount = 0;
  double _currentRotation = 0.0;
  bool _isAdSpin = false;

  final List<int> _rewards = [10, 25, 50, 100, 15, 30, 200, 20];
  final List<Color> _sectionColors = [
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF10B981), // Green
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEF4444), // Red
    const Color(0xFFEC4899), // Pink
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFFF97316), // Orange
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _spinController.addListener(() {
      setState(() {
        _currentRotation =
            _spinController.value * 2 * pi * 5; // 5 full rotations + offset
      });
    });

    _spinController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onSpinComplete();
      }
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _startSpin({required bool isAd}) {
    if (_isSpinning || _spinFinished) return;

    if (isAd) {
      final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;
      Haptics.vibrate(HapticsType.medium);
      di.sl<AdService>().showRewardedAd(
        isPremium: isPremium,
        onDismissed: () {},
        onUserEarnedReward: (_) {
          _executeSpin(isAd: true);
        },
      );
    } else {
      Haptics.vibrate(HapticsType.medium);
      _executeSpin(isAd: false);
    }
  }

  void _executeSpin({required bool isAd}) {
    setState(() {
      _isSpinning = true;
      _isAdSpin = isAd;
    });

    final random = Random();
    final targetIndex = random.nextInt(_rewards.length);
    _rewardAmount = _rewards[targetIndex];

    // Calculate rotation to stop at target index
    // Note: wheel spins clockwise, pointer is at top (0 radians)
    // We want the section's center to align with the pointer.
    // Add offset for the top pointer position (1.5 pi is conceptually top, but here 0 is top if properly drawn)

    // Animate to a target value. We'll set the controller's upper bound dynamically
    // or just animate with a chained tween so we can control easing.
    final extraSpins = 5.0; // 5 full rotations
    final normalizedTargetDeviation = targetIndex / _rewards.length;
    // targetRotation calculates the total rotation required
    final targetRotation = extraSpins + (1.0 - normalizedTargetDeviation);

    _spinController.animateTo(targetRotation, curve: Curves.easeOutCirc);
  }

  void _onSpinComplete() {
    Haptics.vibrate(HapticsType.heavy);
    setState(() {
      _isSpinning = false;
      _spinFinished = true;
    });
    _confettiController.play();

    // Dispatch Event
    context.read<AuthBloc>().add(
      AuthClaimDailySpinRequested(_rewardAmount, isAdSpin: _isAdSpin),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    if (user == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final lastFreeSpin = user.lastFreeSpinDate;
    bool hasFreeSpin = true;
    if (lastFreeSpin != null) {
      hasFreeSpin =
          !(now.year == lastFreeSpin.year &&
              now.month == lastFreeSpin.month &&
              now.day == lastFreeSpin.day);
    }

    // Limit to 3 ad spins per day
    int currentAdSpinsUsed = user.adSpinsUsedToday;
    if (user.lastAdSpinDate != null &&
        !(now.year == user.lastAdSpinDate!.year &&
            now.month == user.lastAdSpinDate!.month &&
            now.day == user.lastAdSpinDate!.day)) {
      currentAdSpinsUsed = 0;
    }

    final maxAdSpins = 3;
    final adSpinsAvailable = maxAdSpins - currentAdSpinsUsed;
    final canAdSpin = !hasFreeSpin && adSpinsAvailable > 0;

    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: Colors.black.withValues(alpha: 0.8)),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.amber,
                  Colors.orange,
                  Colors.yellow,
                  Colors.white,
                  Colors.pink,
                  Colors.cyan,
                ],
                numberOfParticles: 30,
              ),

              Text(
                _spinFinished ? 'VICTORY!' : 'FORTUNE WHEEL',
                style: GoogleFonts.outfit(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: Colors.amber.withValues(alpha: 0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.5, duration: 600.ms),

              SizedBox(height: 8.h),

              Text(
                _spinFinished
                    ? 'YOU WON BIG'
                    : hasFreeSpin
                    ? 'YOUR DAILY FREE SPIN IS READY'
                    : canAdSpin
                    ? 'WATCH AN AD TO SPIN ($adSpinsAvailable left)'
                    : 'COME BACK TOMORROW',
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: 2,
                ),
              ).animate().fadeIn(delay: 300.ms),

              SizedBox(height: 50.h),

              Stack(
                alignment: Alignment.center,
                children: [
                  // Glow Effect Behind Wheel
                  Container(
                        width: 350.r,
                        height: 350.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.amber.withValues(alpha: 0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1.1, 1.1),
                        duration: 2.seconds,
                      ),

                  // The Custom Drawn Fortune Wheel
                  Transform.rotate(
                    angle: _currentRotation,
                    child: SizedBox(
                      width: 280.r,
                      height: 280.r,
                      child: CustomPaint(
                        painter: _WheelPainter(
                          rewards: _rewards,
                          colors: _sectionColors,
                        ),
                      ),
                    ),
                  ),

                  // Center Knob
                  Container(
                    width: 40.r,
                    height: 40.r,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),

                  // Top Pointer
                  Positioned(
                    top: -15.r,
                    child: Icon(
                      Icons.arrow_drop_down_circle,
                      color: Colors.white,
                      size: 40.r,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 50.h),

              if (_spinFinished) ...[
                // Reward Banner
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 40.w,
                    vertical: 20.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.monetization_on_rounded,
                        color: Colors.amber,
                        size: 36.r,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        '+$_rewardAmount COINS',
                        style: GoogleFonts.outfit(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(curve: Curves.easeOutBack, duration: 600.ms),

                SizedBox(height: 40.h),

                ScaleButton(
                  onTap: widget.onClose,
                  child: Container(
                    width: 200.w,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'COLLECT',
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms),
              ] else if (!_isSpinning) ...[
                // Action Buttons
                if (hasFreeSpin)
                  ScaleButton(
                    onTap: () => _startSpin(isAd: false),
                    child: Container(
                      width: 240.w,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'SPIN NOW',
                        style: GoogleFonts.outfit(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  )
                else if (canAdSpin)
                  ScaleButton(
                    onTap: () => _startSpin(isAd: true),
                    child: Container(
                      width: 260.w,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.5),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_circle_fill_rounded,
                            color: Colors.amber,
                            size: 24.r,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'SPIN WITH AD',
                            style: GoogleFonts.outfit(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.amber,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Text(
                    'COME BACK TOMORROW FOR MORE',
                    style: GoogleFonts.outfit(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white54,
                    ),
                  ),

                SizedBox(height: 30.h),
                ScaleButton(
                  onTap: widget.onClose,
                  child: Text(
                    'MAYBE LATER',
                    style: GoogleFonts.outfit(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<int> rewards;
  final List<Color> colors;

  _WheelPainter({required this.rewards, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    final sectionAngle = 2 * pi / rewards.length;

    for (int i = 0; i < rewards.length; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;

      // Draw Arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2 + (i * sectionAngle), // Start at top
        sectionAngle,
        true,
        paint,
      );

      // Draw Separator Lines
      final linePaint = Paint()
        ..color = Colors.white24
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * cos(-pi / 2 + (i * sectionAngle)),
          center.dy + radius * sin(-pi / 2 + (i * sectionAngle)),
        ),
        linePaint,
      );

      // Draw Text aligned with middle of section
      canvas.save();
      canvas.translate(center.dx, center.dy);
      // Rotate to middle of section
      canvas.rotate(-pi / 2 + (i * sectionAngle) + (sectionAngle / 2));

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${rewards[i]}',
          style: GoogleFonts.outfit(
            fontSize: 24.sp,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [
              const Shadow(
                color: Colors.black54,
                blurRadius: 4,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      // Draw text shifted outwards from center
      textPainter.paint(
        canvas,
        Offset(
          radius * 0.5 - (textPainter.width / 2),
          -(textPainter.height / 2),
        ),
      );

      canvas.restore();
    }

    // Outer border
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
