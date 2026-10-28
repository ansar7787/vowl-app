import 'package:vowl/core/theme/app_colors.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:confetti/confetti.dart';
import 'package:lottie/lottie.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color colorfcd34d = Color(0xFFFCD34D);
  static const Color colorfde68a = Color(0xFFFDE68A);
}

/// Rotating sunburst rays painter creating celebratory god-ray beams.
class _SunburstPainter extends CustomPainter {
  final Color color;
  final int rayCount;

  const _SunburstPainter({
    required this.color,
    this.rayCount = 14,
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
          color.withValues(alpha: 0.35),
          color.withValues(alpha: 0.12),
          Colors.transparent,
        ],
        [0.0, 0.65, 1.0],
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

/// A premium daily-chest overlay with full Lottie vector physics and AAA staged transitions.
///
/// Choreographed Timeline:
///   0–470ms   : Lottie anticipation rumble + closed chest breathing
///   470–520ms : Latch pops open with mechanical hinge lift, gold coins & stars erupt
///   500ms     : Confetti showers, haptic feedback, celebratory ambient beams
///   750ms+    : Reward card slides up smoothly with VIP / Standard breakdown
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

  // ── Derived animations ───────────────────────────────────────────────
  late final Animation<double> _entranceFade;
  late final Animation<double> _entranceScale;

  late final Animation<double> _sunburstFade;
  late final Animation<double> _sunburstScale;
  late final Animation<double> _rewardSlide;
  late final Animation<double> _rewardFade;
  late final Animation<double> _closeButtonFade;

  bool _hasTriggeredOpen = false;

  @override
  void initState() {
    super.initState();

    // 1) Entrance: backdrop + title fade-in (600ms)
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    );
    _entranceScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic),
    );

    // 2) Idle breathing pulse on closed chest (loops)
    _idlePulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // 3) Lottie opening sequence (2200ms total)
    _lottieCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // 0.22–0.50 of Lottie timeline: Radiant sunburst rays emerge as lid opens
    _sunburstFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _lottieCtrl,
        curve: const Interval(0.22, 0.50, curve: Curves.easeOut),
      ),
    );
    _sunburstScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _lottieCtrl,
        curve: const Interval(0.22, 0.60, curve: Curves.easeOutBack),
      ),
    );

    // 0.35–0.70 of Lottie timeline (~770ms+): Reward card slides up
    _rewardSlide = Tween<double>(begin: 45.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _lottieCtrl,
        curve: const Interval(0.35, 0.70, curve: Curves.easeOutCubic),
      ),
    );
    _rewardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _lottieCtrl,
        curve: const Interval(0.35, 0.60, curve: Curves.easeOut),
      ),
    );

    // 0.60–0.90 of Lottie timeline: Close button fades in
    _closeButtonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _lottieCtrl,
        curve: const Interval(0.60, 0.90, curve: Curves.easeOut),
      ),
    );

    // 4) Glow pulse on opened chest (loops)
    _glowPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // 5) Continuous rotating sunburst rays (loops)
    _rayRotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );

    // Start entrance
    _entranceCtrl.forward();

    // If already opened on build (e.g. widget re-created), jump to end state
    if (widget.isOpened) {
      _lottieCtrl.value = 1.0;
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
    // Stop idle breathing pulse
    _idlePulseCtrl.stop();

    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    if (reduceMotion) {
      _lottieCtrl.value = 1.0;
      return;
    }

    // Fire confetti at the exact lid pop moment (~480ms into sequence)
    Future.delayed(const Duration(milliseconds: 480), () {
      if (mounted) widget.confettiController.play();
    });

    // Start sunburst rotation and ambient glow pulse
    Future.delayed(const Duration(milliseconds: 520), () {
      if (mounted) {
        if (!VowlMotion.shouldReduceMotion(context)) {
          if (!_rayRotationCtrl.isAnimating) _rayRotationCtrl.repeat();
          if (!_glowPulseCtrl.isAnimating) _glowPulseCtrl.repeat(reverse: true);
        } else {
          _glowPulseCtrl.value = 0.5;
        }
      }
    });

    _lottieCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _idlePulseCtrl.dispose();
    _lottieCtrl.dispose();
    _glowPulseCtrl.dispose();
    _rayRotationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chestColor = widget.isPremium ? AppColors.amber500 : Colors.amber;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _entranceCtrl,
          _idlePulseCtrl,
          _lottieCtrl,
          _glowPulseCtrl,
          _rayRotationCtrl,
        ]),
        builder: (context, _) {
          return Stack(
            children: [
              // ── Blurred backdrop ──
              Positioned.fill(
                child: GestureDetector(
                  onTap: widget.isOpened ? widget.onClose : null,
                  child: VowlMotion.shouldReduceMotion(context)
                      ? Container(
                          color: Colors.black.withValues(
                            alpha: 0.82 * _entranceFade.value,
                          ),
                        )
                      : BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            color: Colors.black.withValues(
                              alpha: 0.6 * _entranceFade.value,
                            ),
                          ),
                        ),
                ),
              ),

              // ── Close button (fades in after opening sequence) ──
              if (_hasTriggeredOpen)
                PositionedDirectional(
                  top: MediaQuery.of(context).padding.top + 20.h,
                  end: 20.w,
                  child: IgnorePointer(
                    ignoring: _closeButtonFade.value < 0.5,
                    child: Opacity(
                      opacity: _closeButtonFade.value,
                      child: Semantics(
                        button: true,
                        label: context.tr('common.close', fallback: 'Close'),
                        child: GestureDetector(
                          onTap: widget.onClose,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            constraints: BoxConstraints(
                              minWidth: 48.r,
                              minHeight: 48.r,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 24.r,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Main content (scrollable on ultra-compact devices or large text scale) ──
              Center(
                child: FadeTransition(
                  opacity: _entranceFade,
                  child: Material(
                    type: MaterialType.transparency,
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 24.h,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Title (distinct for VIP vs Standard) ──
                          _buildTitle(context, chestColor),
                          SizedBox(height: 8.h),
                          _buildSubtitle(context, chestColor),
                          SizedBox(height: 25.h),

                          // ── Chest area (Lottie vector animation) ──
                          _buildChestArea(context, chestColor),

                          // ── Reward card (slides up after open) ──
                          if (_hasTriggeredOpen) ...[
                            SizedBox(height: 24.h),
                            _buildRewardCard(context),
                          ],

                          // ── "Tap to unveil" prompt ──
                          if (!_hasTriggeredOpen) ...[
                            SizedBox(height: 35.h),
                            _buildTapPrompt(context, chestColor),
                          ],
                        ],
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

  // ── Title ──────────────────────────────────────────────────────────────

  Widget _buildTitle(BuildContext context, Color chestColor) {
    final isOpen = _hasTriggeredOpen && _lottieCtrl.value > 0.25;

    final String titleText;
    if (isOpen) {
      if (widget.isPremium) {
        titleText = context.tr(
          'home.chest_vip_unlocked',
          fallback: 'VIP VAULT UNLOCKED!',
        );
      } else {
        titleText = context.tr(
          'home.chest_treasure_unlocked',
          fallback: 'TREASURE UNLOCKED!',
        );
      }
    } else {
      if (widget.isPremium) {
        titleText = context.tr(
          'home.chest_vip_gift',
          fallback: 'VIP DAILY GIFT',
        );
      } else {
        titleText = context.tr(
          'home.chest_daily_mystery',
          fallback: 'DAILY MYSTERY',
        );
      }
    }

    return Transform.scale(
      scale: _entranceScale.value,
      child: AutoSizeText(
        titleText,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: widget.isPremium ? 26.sp : 28.sp,
          fontWeight: FontWeight.w900,
          color: widget.isPremium && !isOpen
              ? _LocalPalette.colorfcd34d
              : (isOpen && widget.isPremium ? _LocalPalette.colorfcd34d : Colors.white),
          letterSpacing: widget.isPremium ? 3 : 4,
          decoration: TextDecoration.none,
          shadows: [
            Shadow(
              color: chestColor.withValues(alpha: widget.isPremium ? 0.6 : 0.4),
              blurRadius: 24,
            ),
          ],
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        minFontSize: 16,
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context, Color chestColor) {
    final isOpen = _hasTriggeredOpen && _lottieCtrl.value > 0.25;

    final String subtitleText;
    if (isOpen) {
      if (widget.isPremium) {
        subtitleText = context.tr(
          'home.chest_vip_multiplier_applied',
          fallback: 'EXCLUSIVE 3X PRO MULTIPLIER APPLIED',
        );
      } else {
        subtitleText = context.tr(
          'home.chest_claimed',
          fallback: 'DAILY REWARD CLAIMED',
        );
      }
    } else {
      if (widget.isPremium) {
        subtitleText = context.tr(
          'home.chest_pro_reward',
          fallback: 'YOUR EXCLUSIVE PRO REWARD',
        );
      } else {
        subtitleText = context.tr(
          'home.chest_ready_to_open',
          fallback: 'READY TO OPEN?',
        );
      }
    }

    return AutoSizeText(
      subtitleText,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        color: widget.isPremium
            ? _LocalPalette.colorfde68a
            : Colors.white70,
        letterSpacing: 2,
        decoration: TextDecoration.none,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      minFontSize: 10,
    );
  }

  // ── Chest area ─────────────────────────────────────────────────────────

  Widget _buildChestArea(BuildContext context, Color chestColor) {
    return Semantics(
      button: true,
      enabled: !_hasTriggeredOpen,
      label: widget.isPremium
          ? context.tr('home.chest_vip_gift', fallback: 'VIP DAILY GIFT')
          : context.tr('home.chest_daily_mystery', fallback: 'DAILY MYSTERY'),
      child: GestureDetector(
        onTap: _hasTriggeredOpen ? null : widget.onOpen,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 330.r,
          height: 330.r,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Background ambient glow ──
              _buildBackgroundGlow(chestColor),

              // ── Sunburst rays (revealed when opened) ──
              if (_hasTriggeredOpen && _sunburstFade.value > 0.01)
                _buildSunburstRays(chestColor),

              // ── Vector Lottie Chest with gentle idle breathing ──
              Transform.scale(
                scale: _hasTriggeredOpen
                    ? (1.0 + (_glowPulseCtrl.value * 0.02))
                    : (1.0 + (_idlePulseCtrl.value * 0.035)),
                child: Lottie.asset(
                  'assets/lottie/chest.json',
                  controller: _lottieCtrl,
                  width: 310.r,
                  height: 310.r,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildFallbackImage(context),
                ),
              ),

              // ── Confetti ──
              ExcludeSemantics(
                child: ConfettiWidget(
                  confettiController: widget.confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [
                    Colors.amber,
                    Colors.orange,
                    Colors.yellow,
                    Colors.white,
                    Colors.blueAccent,
                  ],
                  numberOfParticles: 50,
                  gravity: 0.3,
                  emissionFrequency: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackImage(BuildContext context) {
    final isOpen = _hasTriggeredOpen && _lottieCtrl.value > 0.25;
    return Image.asset(
      isOpen ? 'assets/images/chest_3d.webp' : 'assets/images/closed_chest_3d.webp',
      key: ValueKey(isOpen ? 'opened_chest' : 'closed_chest'),
      width: 270.r,
      height: 270.r,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.card_giftcard_rounded,
        size: 150.r,
        color: Colors.amber,
      ),
    );
  }

  Widget _buildBackgroundGlow(Color chestColor) {
    final double glowScale;
    final double glowAlpha;

    if (_hasTriggeredOpen) {
      // After opening: gentle pulsing glow
      glowScale = 0.95 + (_glowPulseCtrl.value * 0.25);
      glowAlpha = widget.isPremium ? 0.38 : 0.25;
    } else {
      // Idle: subtle breathing
      glowScale = 0.85 + (_idlePulseCtrl.value * 0.15);
      glowAlpha = widget.isPremium ? 0.32 : 0.10;
    }

    return ExcludeSemantics(
      child: Transform.scale(
        scale: glowScale,
        child: Container(
          width: 300.r,
          height: 300.r,
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
              size: Size(330.r, 330.r),
              painter: _SunburstPainter(
                color: chestColor,
                rayCount: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Reward card ────────────────────────────────────────────────────────

  Widget _buildRewardCard(BuildContext context) {
    return Opacity(
      opacity: _rewardFade.value,
      child: Transform.translate(
        offset: Offset(0, _rewardSlide.value),
        child: Semantics(
          label: context.tr(
            'home.chest_coins_collected_value',
            fallback: 'COINS COLLECTED',
            args: ['${widget.rewardAmount}'],
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 18.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(
                color: widget.isPremium
                    ? _LocalPalette.colorfcd34d.withValues(alpha: 0.5)
                    : Colors.white24,
                width: widget.isPremium ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: (widget.isPremium ? Colors.amber : Colors.orange)
                      .withValues(alpha: 0.25),
                  blurRadius: 30,
                  spreadRadius: -8,
                ),
              ],
            ),
            child: ExcludeSemantics(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isPremium
                          ? Icons.stars_rounded
                          : Icons.monetization_on_rounded,
                      color: Colors.amber,
                      size: 42.r,
                    ),
                    SizedBox(width: 14.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '+${widget.rewardAmount}',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 32.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.amber,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            if (widget.isPremium) ...[
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 3.h,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFF59E0B),
                                      Color(0xFFD97706),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  '3X VIP',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black87,
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
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: widget.isPremium
                                ? _LocalPalette.colorfde68a
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
    );
  }

  // ── Tap prompt ─────────────────────────────────────────────────────────

  Widget _buildTapPrompt(BuildContext context, Color chestColor) {
    // Gentle opacity pulse: 0.4 → 1.0
    final promptOpacity = 0.4 + (_idlePulseCtrl.value * 0.6);

    return ExcludeSemantics(
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
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
            color: chestColor,
            letterSpacing: 3,
            decoration: TextDecoration.none,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          minFontSize: 8,
        ),
      ),
    );
  }
}
