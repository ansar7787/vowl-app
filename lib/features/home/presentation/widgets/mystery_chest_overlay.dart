import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:confetti/confetti.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:auto_size_text/auto_size_text.dart';

/// A premium daily-chest overlay with AAA-grade staged transitions.
///
/// Animation timeline (on tap → open):
///   0–300ms : Violent shake intensifies + slight scale-up
///   300–500ms: Blinding white flash explosion
///   400–900ms: Closed chest fades/scales out, opened chest scales in (elasticOut)
///   500ms+   : Confetti fires, glow pulses, reward card slides up
///
/// The key insight: we never do an instant image swap. Every visual change
/// is driven by explicit [AnimationController]s so the user sees a
/// continuous, cinematic flow — not a jarring frame-skip.
class MysteryChestOverlay extends StatefulWidget {
  const MysteryChestOverlay({
    super.key,
    required this.isOpened,
    required this.isPremium,
    required this.rewardAmount,
    required this.onOpen,
    required this.onClose,
    required this.confettiController,
  });

  final bool isOpened;
  final bool isPremium;
  final int rewardAmount;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final ConfettiController confettiController;

  @override
  State<MysteryChestOverlay> createState() => _MysteryChestOverlayState();
}

class _MysteryChestOverlayState extends State<MysteryChestOverlay>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────
  late final AnimationController _entranceCtrl;
  late final AnimationController _idlePulseCtrl;
  late final AnimationController _openSequenceCtrl;
  late final AnimationController _glowPulseCtrl;

  // ── Derived animations ───────────────────────────────────────────────
  late final Animation<double> _entranceFade;
  late final Animation<double> _entranceScale;

  // Opening sequence sub-animations (all driven by _openSequenceCtrl)
  late final Animation<double> _shakeIntensity;
  late final Animation<double> _flashOpacity;
  late final Animation<double> _closedChestFade;
  late final Animation<double> _openedChestScale;
  late final Animation<double> _openedChestFade;
  late final Animation<double> _rewardSlide;
  late final Animation<double> _rewardFade;
  late final Animation<double> _closeButtonFade;

  bool _hasTriggeredOpen = false;

  @override
  void initState() {
    super.initState();

    // 1) Entrance: backdrop + title fade-in (400ms)
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    );
    _entranceScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutBack),
    );

    // 2) Idle breathing pulse on closed chest (loops)
    _idlePulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // 3) Opening sequence (1200ms total, sub-intervals via Interval)
    _openSequenceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // 0.00–0.35: Shake intensifies
    _shakeIntensity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _openSequenceCtrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    // 0.25–0.50: White flash
    _flashOpacity =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 60),
        ]).animate(
          CurvedAnimation(
            parent: _openSequenceCtrl,
            curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
          ),
        );

    // 0.30–0.50: Closed chest fades out
    _closedChestFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _openSequenceCtrl,
        curve: const Interval(0.30, 0.50, curve: Curves.easeIn),
      ),
    );

    // 0.40–0.85: Opened chest scales & fades in
    _openedChestScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _openSequenceCtrl,
        curve: const Interval(0.40, 0.85, curve: Curves.elasticOut),
      ),
    );
    _openedChestFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _openSequenceCtrl,
        curve: const Interval(0.38, 0.55, curve: Curves.easeOut),
      ),
    );

    // 0.60–1.00: Reward card slides up
    _rewardSlide = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _openSequenceCtrl,
        curve: const Interval(0.60, 1.0, curve: Curves.easeOutBack),
      ),
    );
    _rewardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _openSequenceCtrl,
        curve: const Interval(0.60, 0.85, curve: Curves.easeOut),
      ),
    );

    // 0.80–1.00: Close button fades in
    _closeButtonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _openSequenceCtrl,
        curve: const Interval(0.80, 1.0, curve: Curves.easeOut),
      ),
    );

    // 4) Glow pulse on opened chest (loops)
    _glowPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Start entrance
    _entranceCtrl.forward();

    // If already opened on build (e.g. widget re-created), skip to end
    if (widget.isOpened) {
      _openSequenceCtrl.value = 1.0;
      _idlePulseCtrl.stop();
      _glowPulseCtrl.repeat(reverse: true);
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

  void _triggerOpenSequence() {
    // Stop idle pulse
    _idlePulseCtrl.stop();

    // Fire confetti at the flash peak (~350ms into the sequence)
    Future.delayed(const Duration(milliseconds: 420), () {
      if (mounted) widget.confettiController.play();
    });

    // Start glow pulse after chest appears
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _glowPulseCtrl.repeat(reverse: true);
    });

    _openSequenceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _idlePulseCtrl.dispose();
    _openSequenceCtrl.dispose();
    _glowPulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chestColor = widget.isPremium
        ? const Color(0xFFF59E0B)
        : Colors.amber;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _entranceCtrl,
          _idlePulseCtrl,
          _openSequenceCtrl,
          _glowPulseCtrl,
        ]),
        builder: (context, _) {
          return Stack(
            children: [
              // ── Blurred backdrop ──
              Positioned.fill(
                child: GestureDetector(
                  onTap: widget.isOpened ? widget.onClose : null,
                  child: BackdropFilter(
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

              // ── Main content ──
              Center(
                child: FadeTransition(
                  opacity: _entranceFade,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Title ──
                        _buildTitle(context, chestColor),
                        SizedBox(height: 8.h),
                        _buildSubtitle(context, chestColor),
                        SizedBox(height: 50.h),

                        // ── Chest area ──
                        _buildChestArea(context, chestColor),

                        // ── Reward card (slides up after open) ──
                        if (_hasTriggeredOpen) ...[
                          SizedBox(height: 40.h),
                          _buildRewardCard(context),
                        ],

                        // ── "Tap to unveil" prompt ──
                        if (!_hasTriggeredOpen) ...[
                          SizedBox(height: 60.h),
                          _buildTapPrompt(context, chestColor),
                        ],
                      ],
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
    final isOpen = _hasTriggeredOpen && _openSequenceCtrl.value > 0.6;
    return Transform.scale(
      scale: _entranceScale.value,
      child: AutoSizeText(
        isOpen
            ? context.tr('home.chest_claimed', fallback: 'Chest Claimed')
            : (widget.isPremium
                  ? context.tr('home.chest_vip_gift', fallback: 'VIP Gift')
                  : context.tr(
                      'home.chest_daily_mystery',
                      fallback: 'Daily Mystery',
                    )),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: widget.isPremium && !isOpen ? 26.sp : 28.sp,
          fontWeight: FontWeight.w900,
          color: widget.isPremium && !isOpen
              ? const Color(0xFFFCD34D)
              : Colors.white,
          letterSpacing: 4,
          decoration: TextDecoration.none,
          shadows: [
            Shadow(color: chestColor.withValues(alpha: 0.5), blurRadius: 20),
          ],
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        minFontSize: 16,
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context, Color chestColor) {
    final isOpen = _hasTriggeredOpen && _openSequenceCtrl.value > 0.6;
    return AutoSizeText(
      isOpen
          ? context.tr(
              'home.chest_treasure_unlocked',
              fallback: 'Treasure Unlocked!',
            )
          : (widget.isPremium
                ? context.tr('home.chest_pro_reward', fallback: 'Pro Reward')
                : context.tr(
                    'home.chest_ready_to_open',
                    fallback: 'Ready to open',
                  )),
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 14.sp,
        fontWeight: FontWeight.w700,
        color: widget.isPremium && !isOpen
            ? const Color(0xFFFDE68A)
            : Colors.white54,
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
          ? context.tr('home.chest_vip_gift', fallback: 'VIP Gift')
          : context.tr('home.chest_daily_mystery', fallback: 'Daily Mystery'),
      child: GestureDetector(
        onTap: _hasTriggeredOpen ? null : widget.onOpen,
        child: SizedBox(
          width: 320.r,
          height: 320.r,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Background glow ──
              _buildBackgroundGlow(chestColor),

              // ── Closed chest (with shake + idle pulse) ──
              if (!_hasTriggeredOpen || _closedChestFade.value > 0.01)
                _buildClosedChest(context),

              // ── Opened chest (scales in during sequence) ──
              if (_hasTriggeredOpen && _openedChestFade.value > 0.01)
                _buildOpenedChest(context),

              // ── White flash explosion ──
              if (_hasTriggeredOpen && _flashOpacity.value > 0.01)
                IgnorePointer(
                  child: Container(
                    width: 400.r,
                    height: 400.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: _flashOpacity.value),
                          Colors.white.withValues(
                            alpha: _flashOpacity.value * 0.6,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
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

  Widget _buildBackgroundGlow(Color chestColor) {
    final double glowScale;
    final double glowAlpha;

    if (_hasTriggeredOpen) {
      // After opening: gentle pulsing glow
      glowScale = 0.9 + (_glowPulseCtrl.value * 0.3);
      glowAlpha = widget.isPremium ? 0.35 : 0.25;
    } else {
      // Idle: subtle breathing
      glowScale = 0.85 + (_idlePulseCtrl.value * 0.15);
      glowAlpha = widget.isPremium ? 0.3 : 0.08;
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

  Widget _buildClosedChest(BuildContext context) {
    // Combine idle pulse + opening shake
    final double idleScale = 1.0 + (_idlePulseCtrl.value * 0.04);
    final double shakeAmount = _shakeIntensity.value * 6.0;
    final double fadeOut = _closedChestFade.value;

    // Shake offset uses a rapid sine pattern driven by time
    final now = DateTime.now().millisecondsSinceEpoch;
    final shakeX = math.sin(now * 0.05) * shakeAmount;
    final shakeY = math.cos(now * 0.07) * shakeAmount * 0.3;
    final shakeRot = math.sin(now * 0.04) * _shakeIntensity.value * 0.06;

    return ExcludeSemantics(
      child: Opacity(
        opacity: fadeOut,
        child: Transform.translate(
          offset: Offset(shakeX, shakeY),
          child: Transform.rotate(
            angle: shakeRot,
            child: Transform.scale(
              scale: idleScale,
              child: Image.asset(
                'assets/images/closed_chest_3d.webp',
                key: const ValueKey('closed_chest'),
                width: 240.r,
                height: 240.r,
                semanticLabel: context.tr(
                  'home.chest_daily_mystery',
                  fallback: 'Daily Mystery',
                ),
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.card_giftcard_rounded,
                  size: 150.r,
                  color: Colors.amber,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpenedChest(BuildContext context) {
    return ExcludeSemantics(
      child: Opacity(
        opacity: _openedChestFade.value,
        child: Transform.scale(
          scale: _openedChestScale.value,
          child: Image.asset(
            'assets/images/chest_3d.webp',
            key: const ValueKey('opened_chest'),
            width: 280.r,
            height: 280.r,
            semanticLabel: context.tr(
              'home.chest_daily_mystery',
              fallback: 'Daily Mystery',
            ),
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.card_giftcard_rounded,
              size: 150.r,
              color: Colors.amber,
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
            fallback: 'Coins Collected',
            args: ['${widget.rewardAmount}'],
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 20.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(color: Colors.white24),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: -10,
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
                      Icons.monetization_on_rounded,
                      color: Colors.amber,
                      size: 40.r,
                    ),
                    SizedBox(width: 16.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        Text(
                          context.tr(
                            'home.chest_coins_collected',
                            fallback: 'Coins Collected',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white70,
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
                  fallback: 'Tap for VIP Loot',
                )
              : context.tr('home.chest_tap_unveil', fallback: 'Tap to unveil'),
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
