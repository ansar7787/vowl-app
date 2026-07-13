import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// HatchingPage: introductory onboarding companion hatching animation.
/// Guides the user through hatching their Vowl companion using a stylised egg.
class HatchingPage extends StatefulWidget {
  final String userName;
  const HatchingPage({super.key, required this.userName});

  @override
  State<HatchingPage> createState() => _HatchingPageState();
}

class _HatchingPageState extends State<HatchingPage> {
  /// 0: Egg shown | 1: Cracking | 2: Hatched | 3: Introduction
  int _stage = 0;
  final FlutterTts _tts = FlutterTts();
  Timer? _hatchTimer;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  @override
  void dispose() {
    _hatchTimer?.cancel();
    // FIX (MEDIUM-3): Always stop TTS unconditionally in dispose().
    // Previously, stop() was only called if _isTtsSpeaking == true,
    // meaning a pending speak() call after _isTtsSpeaking was set false
    // could still deliver audio after the widget was unmounted.
    _tts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setPitch(1.2);
      await _tts.setSpeechRate(0.5);

      _tts.setStartHandler(() {});
      _tts.setCompletionHandler(() {});
      _tts.setErrorHandler((_) {});
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

  String get _introMessage =>
      "Hoot! I'm Owly, your AI companion. Welcome to Vowl, ${widget.userName}! We're not just here to beat levels—we're here to master English together. Let's embrace the journey and start your adventure!";

  Future<void> _speakIntroduction() async {
    if (!mounted) return;
    try {
      await _tts.speak(_introMessage);
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
                        minWidth: constraints.maxWidth,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 24.h,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox.shrink(),
                            // Main focus: egg / mascot + status text
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildMascotStage(context),
                                SizedBox(height: 48.h),
                                _buildStatusText(context),
                              ],
                            ),
                            // Bottom CTA — pre-allocated height prevents CLS
                            Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: _stage >= 2
                                    ? _buildGetStartedButton(context)
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

  Widget _buildMascotStage(BuildContext context) {
    return GestureDetector(
      onTap: _onTapEgg,
      child: Semantics(
        // FIX (HIGH-2): Semantics label now goes through the l10n system.
        label: _stage < 2
            ? context.tr('hatching.egg_semantics', fallback: 'A mysterious glowing egg')
            : context.tr('hatching.mascot_semantics', fallback: 'Your new learning companion'),
        button: _stage < 2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_stage < 2)
              _buildEgg()
            else
              const VowlMascot(
                state: VowlMascotState.happy,
                size: 70,
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          ],
        ),
      ),
    );
  }

  Widget _buildEgg() {
    // FIX (RESPONSIVENESS): Use LayoutBuilder-aware sizing instead of pure
    // .r values. On a 320px-wide phone, 180.r is fine, but capping at
    // 200px wide and 270px tall prevents overflow on unusual aspect ratios.
    final eggW = (180.r).clamp(0.0, MediaQuery.of(context).size.width * 0.50);
    final eggH = eggW * (240 / 180);

    return Container(
          width: eggW,
          height: eggH,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.elliptical(eggW / 2, eggH * 0.583),
              topRight: Radius.elliptical(eggW / 2, eggH * 0.583),
              bottomLeft: Radius.elliptical(eggW / 2, eggH * 0.417),
              bottomRight: Radius.elliptical(eggW / 2, eggH * 0.417),
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
                Positioned.fill(child: CustomPaint(painter: EggCrackPainter())),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -10, end: 10, duration: 2000.ms, curve: Curves.easeInOut)
        .shake(hz: _stage == 1 ? 10 : 0, duration: 1500.ms);
  }

  Widget _buildStatusText(BuildContext context) {
    if (_stage >= 2) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: TweenAnimationBuilder<int>(
          key: ValueKey('hatching_status_$_stage'),
          tween: IntTween(begin: 0, end: _introMessage.length),
          duration: Duration(milliseconds: _introMessage.length * 40),
          builder: (context, value, child) {
            return GlassTile(
              padding: EdgeInsets.all(20.r),
              borderRadius: BorderRadius.circular(24.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        color: const Color(0xFF2563EB).withValues(alpha: 0.5),
                        size: 24.r,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "Owly",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    _introMessage.substring(
                      0,
                      value.clamp(0, _introMessage.length),
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    final String text = _stage == 0
        ? context.tr('hatching.tap_to_begin', fallback: 'Tap to begin')
        : context.tr('hatching.something_happening', fallback: 'Something is happening...');

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

  Widget _buildGetStartedButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: ScaleButton(
        onTap: () {
          _tts.stop();
          context.go('/home');
        },
        child: Container(
          height: 60.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            // FIX (HIGH-2): Localised CTA button text.
            context.tr('hatching.enter_world', fallback: 'Enter World'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 2.seconds).slideY(begin: 0.2, end: 0);
  }
}

/// Draws the glowing crack lines when the egg is in the cracking stage.
class EggCrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFBBF24)
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

    for (final p in [path, path2, path3]) {
      canvas.drawPath(p, glowPaint);
      canvas.drawPath(p, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
