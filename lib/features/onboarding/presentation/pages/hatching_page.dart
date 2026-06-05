import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// HatchingPage handles the introductory onboarding companion hatching animation,
/// guiding the user through hatching their Vowl companion using a high-fidelity 3D egg.
class HatchingPage extends StatefulWidget {
  final String userName;
  const HatchingPage({super.key, required this.userName});

  @override
  State<HatchingPage> createState() => _HatchingPageState();
}

class _HatchingPageState extends State<HatchingPage> {
  int _stage = 0; // 0: Egg, 1: Cracking, 2: Hatched, 3: Introduction
  final FlutterTts _tts = FlutterTts();
  Timer? _hatchTimer;
  bool _isTtsSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  @override
  void dispose() {
    _hatchTimer?.cancel();
    if (_isTtsSpeaking) {
      _tts.stop();
    }
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage("en-US");
      await _tts.setPitch(1.2); // Friendly voice pitch for Owly
      await _tts.setSpeechRate(0.5);
      
      _tts.setStartHandler(() {
        if (mounted) setState(() => _isTtsSpeaking = true);
      });
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _isTtsSpeaking = false);
      });
      _tts.setErrorHandler((_) {
        if (mounted) setState(() => _isTtsSpeaking = false);
      });
    } catch (e) {
      debugPrint('HatchingPage: TTS initialization failed: $e');
    }
  }

  void _onTapEgg() {
    if (_stage == 0) {
      sl<HapticService>().selection();
      setState(() => _stage = 1);

      _hatchTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          sl<HapticService>().success();
          setState(() => _stage = 2);
          _speakIntroduction();
        }
      });
    } else if (_stage == 2) {
      setState(() => _stage = 3);
    }
  }

  Future<void> _speakIntroduction() async {
    try {
      final message =
          "Hoot hoot! I am Owly. I have been waiting for a brave traveler like you, ${widget.userName}, to help me unlock the secrets of English. Let's begin our quest!";
      await _tts.speak(message);
    } catch (e) {
      debugPrint('HatchingPage: TTS speak failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFF8FAFC),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            const MeshGradientBackground(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox.shrink(), // Spacing anchor for spaceBetween alignment

                            // Centered Focus Area (Mascot Egg/State + Status text)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildMascotStage(),
                                SizedBox(height: 48.h),
                                _buildStatusText(),
                              ],
                            ),

                            // Bottom Navigation area - preallocated height to avoid layout shift (CLS)
                            Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: _stage >= 2
                                    ? _buildGetStartedButton()
                                    : SizedBox(height: 60.h),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMascotStage() {
    return GestureDetector(
      onTap: _onTapEgg,
      child: Semantics(
        label: _stage < 2
            ? 'Mysterious egg. Tap to hatch your Vowl companion.'
            : 'Hatched Vowl companion mascot.',
        button: _stage < 2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_stage < 2)
              _buildEgg()
            else
              const VowlMascot(
                state: VowlMascotState.happy,
                size: 200,
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          ],
        ),
      ),
    );
  }

  Widget _buildEgg() {
    return Container(
      width: 180.r,
      height: 240.r,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.elliptical(90.r, 140.r),
          topRight: Radius.elliptical(90.r, 140.r),
          bottomLeft: Radius.elliptical(90.r, 100.r),
          bottomRight: Radius.elliptical(90.r, 100.r),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 0.85,
          colors: [
            Colors.white.withValues(alpha: 0.7),
            const Color(0xFF93C5FD).withValues(alpha: 0.4),
            const Color(0xFF1D4ED8).withValues(alpha: 0.5),
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFF60A5FA).withValues(alpha: 0.15),
            blurRadius: 10,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white.withValues(alpha: 0.7),
              size: 44.r,
            ),
          ),
          if (_stage == 1)
            Positioned.fill(
              child: CustomPaint(
                painter: EggCrackPainter(),
              ),
            ),
        ],
      ),
    )
    .animate(onPlay: (c) => c.repeat(reverse: true))
    .moveY(begin: -10, end: 10, duration: 2000.ms, curve: Curves.easeInOut)
    .shake(hz: _stage == 1 ? 10 : 0, duration: 1500.ms);
  }

  Widget _buildStatusText() {
    String text = "Tap the egg to begin your adventure";
    if (_stage == 1) text = "Something is happening...";
    if (_stage >= 2) text = "You hatched a Vowl companion!";

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: Colors.blueGrey,
        ),
      ),
    ).animate(key: ValueKey('hatching_status_$_stage')).fadeIn();
  }

  Widget _buildGetStartedButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: ElevatedButton(
        onPressed: () => context.go('/'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 60.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
        ),
        child: Text(
          "Enter the World of Vowl",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 2.seconds).slideY(begin: 0.2, end: 0);
  }
}

class EggCrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFBBF24) // Glowing Amber/Gold
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = const Color(0xFFFBBF24).withValues(alpha: 0.4)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.3)
      ..lineTo(size.width * 0.45, size.height * 0.45)
      ..lineTo(size.width * 0.55, size.height * 0.58)
      ..lineTo(size.width * 0.48, size.height * 0.72);

    final path2 = Path()
      ..moveTo(size.width * 0.45, size.height * 0.45)
      ..lineTo(size.width * 0.3, size.height * 0.48)
      ..lineTo(size.width * 0.22, size.height * 0.52);

    final path3 = Path()
      ..moveTo(size.width * 0.55, size.height * 0.58)
      ..lineTo(size.width * 0.72, size.height * 0.56)
      ..lineTo(size.width * 0.8, size.height * 0.62);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path2, glowPaint);
    canvas.drawPath(path3, glowPaint);

    canvas.drawPath(path, paint);
    canvas.drawPath(path2, paint);
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
