import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:lottie/lottie.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Celebration palette: luxury Green + Gold theme with bright highlights.
class _ChestPalette {
  _ChestPalette._();

  // ── Gold Tones ─────────────────────────────────────────────────────────
  static const Color goldBright = Color(0xFFFFD700);
  static const Color goldRich = Color(0xFFF59E0B);
  static const Color goldDeep = Color(0xFFD97706);
  static const Color goldChampagne = Color(0xFFFEF08A);
  static const Color goldLight = Color(0xFFFDE68A);

  // ── Emerald & Green Tones ──────────────────────────────────────────────
  static const Color emeraldVivid = Color(0xFF10B981);
  static const Color emeraldMint = Color(0xFF34D399);
  static const Color emeraldJade = Color(0xFF059669);
  static const Color emeraldLight = Color(0xFFA7F3D0);

  // ── Particle celebration list (Green + Gold only) ──────────────────────
  static const List<Color> confettiColors = [
    goldBright,
    goldRich,
    goldDeep,
    goldChampagne,
    emeraldVivid,
    emeraldMint,
    emeraldJade,
    emeraldLight,
    Colors.white,
  ];
}

/// Rotating sunburst rays painter creating celebratory god-ray beams.
class _SunburstPainter extends CustomPainter {
  final Color color;
  final int rayCount;

  const _SunburstPainter({
    required this.color,
    this.rayCount = 16,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.max(size.width, size.height) / 2;
    final angleStep = (2 * math.pi) / rayCount;
    final halfRay = angleStep / 2;

    final paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [
          color.withValues(alpha: 0.38),
          color.withValues(alpha: 0.14),
          Colors.transparent,
        ],
        [0.0, 0.60, 1.0],
      )
      ..style = PaintingStyle.fill;

    for (int i = 0; i < rayCount; i++) {
      final startAngle = i * angleStep;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle - halfRay * 0.45,
          halfRay * 0.9,
          false,
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SunburstPainter oldDelegate) =>
      color != oldDelegate.color || rayCount != oldDelegate.rayCount;
}

/// A premium, production-level daily-chest overlay with full Lottie vector physics,
/// green + gold celebration confetti, fast-feel animations, rolling rewards, and
/// instant tactile feedback.
///
/// Choreographed Timeline (Total ~950ms — snappy, punchy, zero drag):
///   0–215ms   : Fast anticipation rumble + tap reaction
///   215ms     : Lid pops open! Green + Gold confetti eruption from chest mouth
///   215–380ms : Radiant sunburst rays flare up and spin smoothly
///   320–550ms : Reward card springs up with micro-bounce and coin count roll-up
///   480ms+    : Prominent "COLLECT" CTA and close button ready for instant user agency
class MysteryChestOverlay extends StatefulWidget {
  /// Whether the chest has been opened.
  final bool isOpened;

  /// Whether the reward is from a premium tier chest.
  final bool isPremium;

  /// Number of coins or rewards revealed.
  final int rewardAmount;

  /// Callback executed when the chest is tapped to open.
  final VoidCallback onOpen;

  /// Callback executed when dismissing the chest overlay.
  final VoidCallback onClose;

  /// Controller driving celebratory confetti showers.
  final ConfettiController confettiController;

  /// Creates a [MysteryChestOverlay].
  const MysteryChestOverlay({
    super.key,
    required this.isOpened,
    required this.isPremium,
    required this.rewardAmount,
    required this.onOpen,
    required this.onClose,
    required this.confettiController,
  });

  @override
  State<MysteryChestOverlay> createState() => _MysteryChestOverlayState();
}

class _MysteryChestOverlayState extends State<MysteryChestOverlay>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────
  late final AnimationController _entranceCtrl;
  late final AnimationController _idlePulseCtrl;
  late final AnimationController _lottieCtrl;
  late final AnimationController _glowPulseCtrl;
  late final AnimationController _rayRotationCtrl;
  late final AnimationController _rewardCardCtrl;
  late final AnimationController _coinRollCtrl;

  // ── Derived animations ───────────────────────────────────────────────
  late final Animation<double> _entranceFade;
  late final Animation<double> _entranceScale;

  late final Animation<double> _sunburstFade;
  late final Animation<double> _sunburstScale;
  late final Animation<double> _rewardSlide;
  late final Animation<double> _rewardFade;
  late final Animation<double> _rewardScale;
  late final Animation<double> _coinRollAnim;
  late final Animation<double> _ctaFade;
  late final Animation<double> _ctaScale;

  // ── Internal State ───────────────────────────────────────────────────
  bool _hasTriggeredOpen = false;
  final math.Random _particleRandom = math.Random(1337);

  @override
  void initState() {
    super.initState();

    // 1) Entrance: backdrop + content snappy fade-in (400ms)
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    );
    _entranceScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutBack),
    );

    // 2) Idle breathing pulse on closed chest (1400ms loop)
    _idlePulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // 3) Lottie opening sequence (950ms total — snappy, punchy)
    //    Natural Lottie is 150 frames @ 30fps = 5s.
    //    Running in 950ms means ~5.2x speed, making the 34-frame anticipation
    //    rumble take exactly ~215ms, then lid pops with explosive energy!
    _lottieCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    // Sunburst rays flare up right at lid-pop (0.20 – 0.40)
    _sunburstFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _lottieCtrl,
        curve: const Interval(0.20, 0.40, curve: Curves.easeOut),
      ),
    );
    _sunburstScale = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(
        parent: _lottieCtrl,
        curve: const Interval(0.20, 0.48, curve: Curves.easeOutBack),
      ),
    );

    // Reward card slides up (0.32 – 0.60)
    _rewardSlide = Tween<double>(begin: 36.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _lottieCtrl,
        curve: const Interval(0.32, 0.60, curve: Curves.easeOutCubic),
      ),
    );
    _rewardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _lottieCtrl,
        curve: const Interval(0.32, 0.52, curve: Curves.easeOut),
      ),
    );

    // Action button & close button fade in right after reward (0.50 – 0.72)
    _ctaFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _lottieCtrl,
        curve: const Interval(0.50, 0.72, curve: Curves.easeOut),
      ),
    );
    _ctaScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _lottieCtrl,
        curve: const Interval(0.50, 0.75, curve: Curves.easeOutBack),
      ),
    );

    // 4) Reward Card Micro-Bounce (320ms spring)
    _rewardCardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _rewardScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.88, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_rewardCardCtrl);

    // 5) Coin roll-up counter (400ms) with smooth deceleration curve
    _coinRollCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _coinRollAnim = CurvedAnimation(
      parent: _coinRollCtrl,
      curve: Curves.easeOutCubic,
    );

    // 6) Ambient glow pulse on opened chest
    _glowPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // 7) Sunburst ray rotation (6 seconds per revolution — celebratory & alive)
    _rayRotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    // Start entrance animation
    _entranceCtrl.forward();

    // If opened on mount (e.g. state restoration), jump directly to final state
    if (widget.isOpened) {
      _lottieCtrl.value = 1.0;
      _rewardCardCtrl.value = 1.0;
      _coinRollCtrl.value = 1.0;
      _idlePulseCtrl.stop();
      _hasTriggeredOpen = true;
    }
  }

  @override
  void didUpdateWidget(covariant MysteryChestOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpened && !_hasTriggeredOpen) {
      _hasTriggeredOpen = true;
      _triggerOpenSequence();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    if (!_hasTriggeredOpen) {
      if (!reduceMotion) {
        if (!_idlePulseCtrl.isAnimating) _idlePulseCtrl.repeat(reverse: true);
      } else {
        _idlePulseCtrl.stop();
        _idlePulseCtrl.value = 0.5;
      }
    } else {
      if (!reduceMotion) {
        if (!_rayRotationCtrl.isAnimating) _rayRotationCtrl.repeat();
        if (!_glowPulseCtrl.isAnimating) _glowPulseCtrl.repeat(reverse: true);
      } else {
        _rayRotationCtrl.stop();
        _glowPulseCtrl.stop();
        _glowPulseCtrl.value = 0.5;
      }
    }
  }

  void _triggerOpenSequence() {
    _idlePulseCtrl.stop();

    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    if (reduceMotion) {
      _lottieCtrl.value = 1.0;
      _rewardCardCtrl.value = 1.0;
      _coinRollCtrl.value = 1.0;
      return;
    }

    // ── 215ms: Exact Lid Pop Moment ──
    // Fire Green + Gold confetti eruption immediately when the lid snaps open!
    Future.delayed(const Duration(milliseconds: 215), () {
      if (!mounted) return;
      widget.confettiController.play();
      try {
        Haptics.vibrate(HapticsType.success);
      } catch (_) {}
    });

    // ── 220ms: Rays & Glow ──
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      if (!VowlMotion.shouldReduceMotion(context)) {
        if (!_rayRotationCtrl.isAnimating) _rayRotationCtrl.repeat();
        if (!_glowPulseCtrl.isAnimating) _glowPulseCtrl.repeat(reverse: true);
      } else {
        _glowPulseCtrl.value = 0.5;
      }
    });

    // ── 340ms: Reward Card Pop & Coin Roll ──
    Future.delayed(const Duration(milliseconds: 340), () {
      if (!mounted) return;
      _rewardCardCtrl.forward();
      _coinRollCtrl.forward();
    });

    _lottieCtrl.forward();
  }

  /// Fast-forward animation if user taps while opening (instant skip).
  void _skipToEndIfOpening() {
    if (_hasTriggeredOpen && !_lottieCtrl.isCompleted) {
      _lottieCtrl.value = 1.0;
      _rewardCardCtrl.value = 1.0;
      _coinRollCtrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _idlePulseCtrl.dispose();
    _lottieCtrl.dispose();
    _glowPulseCtrl.dispose();
    _rayRotationCtrl.dispose();
    _rewardCardCtrl.dispose();
    _coinRollCtrl.dispose();
    super.dispose();
  }

  /// Varied celebratory shapes: Gold Coins, Emerald Diamonds, Ribbons, and Stars.
  /// All shapes are mathematically centered at (cx, cy) so they spin cleanly on their true axes.
  Path _createCelebrationPath(Size size) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final shapeType = _particleRandom.nextInt(4);

    switch (shapeType) {
      case 0: // Metallic ribbon strip
        final rw = size.width * 0.9;
        final rh = size.height * 0.45;
        path.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: rw, height: rh),
            const Radius.circular(2),
          ),
        );
      case 1: // Gold coin / medallion disc
        final radius = math.min(size.width, size.height) * 0.42;
        path.addOval(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        );
      case 2: // Emerald gem / diamond
        final hw = size.width * 0.42;
        final hh = size.height * 0.45;
        path
          ..moveTo(cx, cy - hh)
          ..lineTo(cx + hw, cy)
          ..lineTo(cx, cy + hh)
          ..lineTo(cx - hw, cy)
          ..close();
      default: // 4-pointed sparkle star
        final r = math.min(size.width, size.height) * 0.45;
        path
          ..moveTo(cx, cy - r)
          ..quadraticBezierTo(cx, cy, cx + r, cy)
          ..quadraticBezierTo(cx, cy, cx, cy + r)
          ..quadraticBezierTo(cx, cy, cx - r, cy)
          ..quadraticBezierTo(cx, cy, cx, cy - r)
          ..close();
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final chestColor = widget.isPremium
        ? _ChestPalette.goldBright
        : AppColors.amber500;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _entranceCtrl,
          _idlePulseCtrl,
          _lottieCtrl,
          _glowPulseCtrl,
          _rayRotationCtrl,
          _rewardCardCtrl,
          _coinRollCtrl,
        ]),
        builder: (context, _) {
          return Stack(
            children: [
              // ── 1) Translucent blurred backdrop ──
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    if (_hasTriggeredOpen && !_lottieCtrl.isCompleted) {
                      _skipToEndIfOpening();
                    } else if (widget.isOpened) {
                      try {
                        Haptics.vibrate(HapticsType.light);
                      } catch (_) {}
                      widget.onClose();
                    }
                  },
                  child: VowlMotion.shouldReduceMotion(context)
                      ? Container(
                          color: Colors.black.withValues(
                            alpha: 0.85 * _entranceFade.value,
                          ),
                        )
                      : BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            color: Colors.black.withValues(
                              alpha: 0.72 * _entranceFade.value,
                            ),
                          ),
                        ),
                ),
              ),

              // ── 2) Main interactive content ──
              Center(
                child: FadeTransition(
                  opacity: _entranceFade,
                  child: Material(
                    type: MaterialType.transparency,
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      clipBehavior: Clip.none,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 18.h,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Header Title & Subtitle ──
                          _buildTitle(context, chestColor),
                          SizedBox(height: 6.h),
                          _buildSubtitle(context, chestColor),
                          SizedBox(height: 18.h),

                          // ── Chest Visual with Sunburst & Glow ──
                          _buildChestArea(context, chestColor),

                          // ── Post-Open: Reward Card & Collect CTA ──
                          if (_hasTriggeredOpen) ...[
                            SizedBox(height: 16.h),
                            _buildRewardCard(context),
                            SizedBox(height: 16.h),
                            _buildCollectButton(context, chestColor),
                          ],

                          // ── Pre-Open: "Tap to unveil" prompt ──
                          if (!_hasTriggeredOpen) ...[
                            SizedBox(height: 24.h),
                            _buildTapPrompt(context, chestColor),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── 3) Celebration Confetti Layer (Erupts directly out of chest mouth across full screen) ──
              Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: const Alignment(0.0, -0.06),
                    child: ConfettiWidget(
                      confettiController: widget.confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      colors: _ChestPalette.confettiColors,
                      numberOfParticles: 16,
                      gravity: 0.18,
                      emissionFrequency: 0.05,
                      maxBlastForce: 45,
                      minBlastForce: 20,
                      particleDrag: 0.03,
                      minimumSize: const Size(12, 12),
                      maximumSize: const Size(22, 18),
                      createParticlePath: _createCelebrationPath,
                    ),
                  ),
                ),
              ),

              // ── 4) Top-Right Close Button ──
              if (_hasTriggeredOpen)
                PositionedDirectional(
                  top: MediaQuery.of(context).padding.top + 16.h,
                  end: 18.w,
                  child: IgnorePointer(
                    ignoring: _ctaFade.value < 0.4,
                    child: Opacity(
                      opacity: _ctaFade.value,
                      child: Semantics(
                        button: true,
                        label: context.tr('common.close', fallback: 'Close'),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              try {
                                Haptics.vibrate(HapticsType.light);
                              } catch (_) {}
                              widget.onClose();
                            },
                            borderRadius: BorderRadius.circular(24.r),
                            child: Container(
                              width: 44.r,
                              height: 44.r,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white24,
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 22.r,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── Header Title & Subtitle ──────────────────────────────────────────────

  Widget _buildTitle(BuildContext context, Color chestColor) {
    final isOpen = _hasTriggeredOpen && _lottieCtrl.value > 0.22;

    final String titleText;
    if (isOpen) {
      titleText = widget.isPremium
          ? context.tr('home.chest_vip_unlocked', fallback: 'VIP VAULT UNLOCKED!')
          : context.tr('home.chest_treasure_unlocked', fallback: 'TREASURE UNLOCKED!');
    } else {
      titleText = widget.isPremium
          ? context.tr('home.chest_vip_gift', fallback: 'VIP DAILY GIFT')
          : context.tr('home.chest_daily_mystery', fallback: 'DAILY MYSTERY');
    }

    return Transform.scale(
      scale: _entranceScale.value,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: AutoSizeText(
          titleText,
          key: ValueKey(titleText),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: widget.isPremium ? 26.sp : 28.sp,
            fontWeight: FontWeight.w900,
            color: widget.isPremium
                ? _ChestPalette.goldBright
                : Colors.white,
            letterSpacing: widget.isPremium ? 2.5 : 3.5,
            decoration: TextDecoration.none,
            shadows: [
              Shadow(
                color: chestColor.withValues(alpha: widget.isPremium ? 0.65 : 0.45),
                blurRadius: 24,
              ),
            ],
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          minFontSize: 16,
        ),
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context, Color chestColor) {
    final isOpen = _hasTriggeredOpen && _lottieCtrl.value > 0.22;

    final String subtitleText;
    if (isOpen) {
      subtitleText = widget.isPremium
          ? context.tr(
              'home.chest_vip_multiplier_applied',
              fallback: 'EXCLUSIVE 3X PRO MULTIPLIER APPLIED',
            )
          : context.tr('home.chest_claimed', fallback: 'CLAIMED!');
    } else {
      subtitleText = widget.isPremium
          ? context.tr('home.chest_pro_reward', fallback: 'YOUR EXCLUSIVE PRO REWARD')
          : context.tr('home.chest_ready_to_open', fallback: 'READY TO OPEN?');
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: AutoSizeText(
        subtitleText,
        key: ValueKey(subtitleText),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12.5.sp,
          fontWeight: FontWeight.w700,
          color: widget.isPremium
              ? _ChestPalette.goldLight
              : Colors.white70,
          letterSpacing: 1.8,
          decoration: TextDecoration.none,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        minFontSize: 10,
      ),
    );
  }

  // ── Chest Visual Area ────────────────────────────────────────────────────

  Widget _buildChestArea(BuildContext context, Color chestColor) {
    return Semantics(
      button: true,
      enabled: true,
      label: widget.isPremium
          ? context.tr('home.chest_vip_gift', fallback: 'VIP DAILY GIFT')
          : context.tr('home.chest_daily_mystery', fallback: 'DAILY MYSTERY'),
      child: GestureDetector(
        onTap: () {
          if (!_hasTriggeredOpen) {
            try {
              Haptics.vibrate(HapticsType.heavy);
            } catch (_) {}
            widget.onOpen();
          } else if (!_lottieCtrl.isCompleted) {
            _skipToEndIfOpening();
          } else {
            try {
              Haptics.vibrate(HapticsType.light);
            } catch (_) {}
            widget.onClose();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 290.r,
          height: 290.r,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Ambient background aura glow ──
              _buildBackgroundGlow(chestColor),

              // ── Radiant celebratory sunburst rays ──
              if (_hasTriggeredOpen && _sunburstFade.value > 0.01)
                _buildSunburstRays(chestColor),

              // ── Vector Lottie Chest (950ms fast timeline) ──
              Transform.scale(
                scale: _hasTriggeredOpen
                    ? (1.0 + (_glowPulseCtrl.value * 0.02))
                    : (1.0 + (_idlePulseCtrl.value * 0.03)),
                child: Lottie.asset(
                  'assets/lottie/chest.json',
                  controller: _lottieCtrl,
                  width: 280.r,
                  height: 280.r,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildFallbackImage(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackImage(BuildContext context) {
    final isOpen = _hasTriggeredOpen && _lottieCtrl.value > 0.22;
    return Image.asset(
      isOpen ? 'assets/images/chest_3d.webp' : 'assets/images/closed_chest_3d.webp',
      key: ValueKey(isOpen ? 'opened_chest' : 'closed_chest'),
      width: 250.r,
      height: 250.r,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.card_giftcard_rounded,
        size: 130.r,
        color: _ChestPalette.goldBright,
      ),
    );
  }

  Widget _buildBackgroundGlow(Color chestColor) {
    final double glowScale;
    final double glowAlpha;

    if (_hasTriggeredOpen) {
      glowScale = 0.95 + (_glowPulseCtrl.value * 0.22);
      glowAlpha = widget.isPremium ? 0.42 : 0.28;
    } else {
      glowScale = 0.85 + (_idlePulseCtrl.value * 0.12);
      glowAlpha = widget.isPremium ? 0.30 : 0.12;
    }

    return ExcludeSemantics(
      child: Transform.scale(
        scale: glowScale,
        child: Container(
          width: 280.r,
          height: 280.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                chestColor.withValues(alpha: glowAlpha),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSunburstRays(Color chestColor) {
    final double rotation = _rayRotationCtrl.value * 2 * math.pi;

    return ExcludeSemantics(
      child: Opacity(
        opacity: _sunburstFade.value,
        child: Transform.scale(
          scale: _sunburstScale.value,
          child: Transform.rotate(
            angle: rotation,
            child: CustomPaint(
              size: Size(300.r, 300.r),
              painter: _SunburstPainter(
                color: chestColor,
                rayCount: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Reward Card with Rolling Counter ───────────────────────────────────────

  Widget _buildRewardCard(BuildContext context) {
    // Current rolling coins count for dynamic visual gratification with cubic ease-out
    final displayedAmount = (_coinRollAnim.value * widget.rewardAmount).round();

    return Opacity(
      opacity: _rewardFade.value,
      child: Transform.translate(
        offset: Offset(0, _rewardSlide.value),
        child: Transform.scale(
          scale: _rewardScale.value,
          child: Semantics(
            label: context.tr(
              'home.chest_coins_collected_value',
              fallback: 'COINS COLLECTED',
              args: ['${widget.rewardAmount}'],
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 15.h),
              decoration: BoxDecoration(
                color: const Color(0xFF131826).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(26.r),
                border: Border.all(
                  color: widget.isPremium
                      ? _ChestPalette.goldBright.withValues(alpha: 0.65)
                      : _ChestPalette.emeraldMint.withValues(alpha: 0.45),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isPremium
                            ? _ChestPalette.goldRich
                            : _ChestPalette.emeraldVivid)
                        .withValues(alpha: 0.35),
                    blurRadius: 28,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: ExcludeSemantics(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Glowing Icon
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: (widget.isPremium
                                  ? _ChestPalette.goldRich
                                  : _ChestPalette.goldBright)
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isPremium
                              ? Icons.stars_rounded
                              : Icons.monetization_on_rounded,
                          color: _ChestPalette.goldBright,
                          size: 36.r,
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '+$displayedAmount',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 30.sp,
                                  fontWeight: FontWeight.w900,
                                  color: _ChestPalette.goldBright,
                                  decoration: TextDecoration.none,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (widget.isPremium) ...[
                                SizedBox(width: 10.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        _ChestPalette.goldRich,
                                        _ChestPalette.goldDeep,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _ChestPalette.goldRich
                                            .withValues(alpha: 0.4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '3X VIP',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF1E1000),
                                      letterSpacing: 1,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            widget.isPremium
                                ? context.tr(
                                    'home.chest_vip_coins_collected',
                                    fallback: 'VIP Bonus Coins Collected',
                                  )
                                : context.tr(
                                    'home.chest_coins_collected',
                                    fallback: 'Coins Collected',
                                  ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w700,
                              color: widget.isPremium
                                  ? _ChestPalette.goldLight
                                  : Colors.white70,
                              letterSpacing: 1,
                              decoration: TextDecoration.none,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── High-Agency "COLLECT" CTA Button ─────────────────────────────────────

  Widget _buildCollectButton(BuildContext context, Color chestColor) {
    return Opacity(
      opacity: _ctaFade.value,
      child: Transform.scale(
        scale: _ctaScale.value,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  try {
                    Haptics.vibrate(HapticsType.light);
                  } catch (_) {}
                  widget.onClose();
                },
                borderRadius: BorderRadius.circular(24.r),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 36.w,
                    vertical: 14.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.isPremium
                          ? [
                              _ChestPalette.goldBright,
                              _ChestPalette.goldRich,
                            ]
                          : [
                              _ChestPalette.emeraldVivid,
                              _ChestPalette.emeraldJade,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.isPremium
                                ? _ChestPalette.goldRich
                                : _ChestPalette.emeraldVivid)
                            .withValues(alpha: 0.45),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: widget.isPremium
                            ? const Color(0xFF1E1000)
                            : Colors.white,
                        size: 20.r,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        context.tr('common.continue', fallback: 'COLLECT'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                          color: widget.isPremium
                              ? const Color(0xFF1E1000)
                              : Colors.white,
                          letterSpacing: 1.5,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            GestureDetector(
              onTap: () {
                try {
                  Haptics.vibrate(HapticsType.light);
                } catch (_) {}
                widget.onClose();
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
                child: Text(
                  context.tr(
                    'home.tap_anywhere_continue',
                    fallback: 'Tap anywhere to continue',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white38,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── "Tap to unveil" Pre-Open Prompt ──────────────────────────────────────

  Widget _buildTapPrompt(BuildContext context, Color chestColor) {
    final promptOpacity = 0.5 + (_idlePulseCtrl.value * 0.5);

    return GestureDetector(
      onTap: () {
        if (!_hasTriggeredOpen) {
          try {
            Haptics.vibrate(HapticsType.heavy);
          } catch (_) {}
          widget.onOpen();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: promptOpacity,
          child: AutoSizeText(
            widget.isPremium
                ? context.tr(
                    'home.chest_tap_vip_loot',
                    fallback: 'TAP TO UNLEASH VIP LOOT',
                  )
                : context.tr('home.chest_tap_unveil', fallback: 'TAP TO UNVEIL'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: chestColor,
              letterSpacing: 3,
              decoration: TextDecoration.none,
              shadows: [
                Shadow(
                  color: chestColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            minFontSize: 8,
          ),
        ),
      ),
    );
  }
}
