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
import 'package:confetti/confetti.dart';

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
  final ValueNotifier<int> _stage = ValueNotifier(0);
  final FlutterTts _tts = FlutterTts();
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  );
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
    _tts.stop();
    _confettiController.dispose();
    _stage.dispose();
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      // FIX (H3): Use user's locale for TTS instead of hardcoded en-US.
      final locale = sl<LocaleService>().currentLocale;
      final ttsLang = _mapLocaleToTtsLanguage(locale.languageCode);
      await _tts.setLanguage(ttsLang);
      await _tts.setPitch(1.2);
      await _tts.setSpeechRate(0.5);

      _tts.setStartHandler(() {});
      _tts.setCompletionHandler(() {});
      _tts.setErrorHandler((_) {});
    } catch (e) {
      debugPrint('HatchingPage: TTS initialization failed: $e');
    }
  }

  /// Maps a locale language code to a TTS-compatible language tag.
  /// Falls back to en-US for unsupported languages.
  String _mapLocaleToTtsLanguage(String languageCode) {
    const map = {
      'en': 'en-US',
      'hi': 'hi-IN',
      'es': 'es-ES',
      'pt': 'pt-BR',
      'ar': 'ar-SA',
      'fr': 'fr-FR',
      'ru': 'ru-RU',
      'zh': 'zh-CN',
      'ko': 'ko-KR',
      'ja': 'ja-JP',
      'de': 'de-DE',
      'ml': 'ml-IN',
      'kn': 'kn-IN',
      'ta': 'ta-IN',
      'te': 'te-IN',
      'mr': 'mr-IN',
      'bn': 'bn-IN',
      'gu': 'gu-IN',
    };
    return map[languageCode] ?? 'en-US';
  }

  void _onTapEgg() {
    if (_stage.value == 0) {
      sl<HapticService>().selection();
      _stage.value = 1;

      _hatchTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          sl<HapticService>().success();
          _stage.value = 2;
          _confettiController.play();
          _speakIntroduction();
        }
      });
    } else if (_stage.value == 2) {
      _stage.value = 3;
    }
  }

  /// FIX (H2): Intro message is now localized via context.tr().
  String _getIntroMessage(BuildContext context) => context.tr(
    'hatching.intro_message',
    fallback:
        "Hoot! I'm Owly, your AI companion. Welcome to Vowl, {0}! We're not just here to beat levels—we're here to master English together. Let's embrace the journey and start your adventure!",
    args: [widget.userName],
  );

  Future<void> _speakIntroduction() async {
    if (!mounted) return;
    try {
      await _tts.speak(_getIntroMessage(context));
    } catch (e) {
      debugPrint('HatchingPage: TTS speak failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // FIX (H1): System UI adapts to theme instead of forcing light.
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF8FAFC),
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF8FAFC),
        body: ValueListenableBuilder<int>(
          valueListenable: _stage,
          builder: (context, currentStage, child) {
            return Stack(
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
                                    _buildMascotStage(context, currentStage),
                                    SizedBox(height: 48.h),
                                    _buildStatusText(context, currentStage),
                                  ],
                                ),
                                // Bottom CTA — pre-allocated height prevents CLS
                                Padding(
                                  padding: EdgeInsets.only(bottom: 16.h),
                                  child: AnimatedSize(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    child: currentStage >= 2
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
                Align(
                  alignment: Alignment.center,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [
                      Colors.green,
                      Colors.blue,
                      Colors.pink,
                      Colors.orange,
                      Colors.purple,
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMascotStage(BuildContext context, int currentStage) {
    return GestureDetector(
      onTap: _onTapEgg,
      child: Semantics(
        // FIX (HIGH-2): Semantics label now goes through the l10n system.
        label: currentStage < 2
            ? context.tr(
                'hatching.egg_semantics',
                fallback: 'A mysterious glowing egg',
              )
            : context.tr(
                'hatching.mascot_semantics',
                fallback: 'Your new learning companion',
              ),
        button: currentStage < 2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (currentStage < 2)
              _buildEgg(currentStage)
            else
              // FIX (H10): Responsive mascot sizing with .r
              VowlMascot(
                state: VowlMascotState.happy,
                size: 70.r.clamp(50, 120).toDouble(),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          ],
        ),
      ),
    );
  }

  Widget _buildEgg(int currentStage) {
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
              if (currentStage == 1)
                Positioned.fill(child: CustomPaint(painter: EggCrackPainter())),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -10, end: 10, duration: 2000.ms, curve: Curves.easeInOut)
        // FIX (H8): Pulsing glow as tap affordance when egg is untapped (stage 0)
        .shimmer(
          color: currentStage == 0
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.transparent,
          duration: 2500.ms,
        )
        .shake(hz: currentStage == 1 ? 10 : 0, duration: 1500.ms);
  }

  Widget _buildStatusText(BuildContext context, int currentStage) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // FIX (H4): Text color adapts to theme
    final textColor = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : const Color(0xFF334155);
    final subtleColor = isDark ? Colors.white60 : Colors.blueGrey;

    if (currentStage >= 2) {
      final introMessage = _getIntroMessage(context);
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: TweenAnimationBuilder<int>(
          key: ValueKey('hatching_status_$currentStage'),
          tween: IntTween(begin: 0, end: introMessage.length),
          duration: Duration(milliseconds: introMessage.length * 40),
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
                        color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                        size: 24.r,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "Owly",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6366F1),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    introMessage.substring(
                      0,
                      value.clamp(0, introMessage.length),
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    final String text = currentStage == 0
        ? context.tr('hatching.tap_to_begin', fallback: 'Tap to begin')
        : context.tr(
            'hatching.something_happening',
            fallback: 'Something is happening...',
          );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: subtleColor,
        ),
      ),
    ).animate(key: ValueKey('hatching_status_$currentStage')).fadeIn();
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
            color: const Color(0xFF6366F1),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
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
      // FIX (H6): Reduced delay from 2s to 600ms — less user impatience.
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0);
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
