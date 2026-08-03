import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/offline_play_gate_service.dart';

/// Shown when a free user exhausts their offline play quota.
///
/// Unlike [NoInternetPage] (which is a generic "no internet" blocker),
/// this page is specifically designed for the offline play quota system.
/// It provides three monetization-friendly exit paths:
///
///  1. **RECONNECT** — user reconnects, interstitial ad plays, quota resets.
///  2. **WATCH AD** — cached rewarded ad plays, grants +3 offline levels.
///  3. **GO PREMIUM** — unlimited offline play upsell.
class OfflineQuotaExhaustedPage extends StatefulWidget {
  final Future<void> Function() onRetry;
  final VoidCallback onAdWatched;
  final VoidCallback onClose;

  const OfflineQuotaExhaustedPage({
    super.key,
    required this.onRetry,
    required this.onAdWatched,
    required this.onClose,
  });

  @override
  State<OfflineQuotaExhaustedPage> createState() =>
      _OfflineQuotaExhaustedPageState();
}

class _OfflineQuotaExhaustedPageState extends State<OfflineQuotaExhaustedPage> {
  bool _isChecking = false;
  bool _isLoadingAd = false;

  Future<void> _handleRetry() async {
    if (_isChecking) return;
    await Haptics.vibrate(HapticsType.selection);
    setState(() => _isChecking = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _handleWatchAd() {
    if (_isLoadingAd) return;
    Haptics.vibrate(HapticsType.selection);

    final adService = di.sl<AdService>();
    if (!adService.isRewardedAdLoaded) {
      // No cached ad available — user must reconnect
      Haptics.vibrate(HapticsType.warning);
      return;
    }

    setState(() => _isLoadingAd = true);
    adService.showRewardedAd(
      isPremium: false,
      onUserEarnedReward: (_) {
        OfflinePlayGateService.instance.grantBonusOfflinePlays();
        widget.onAdWatched();
      },
      onDismissed: () {
        if (mounted) setState(() => _isLoadingAd = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final adService = di.sl<AdService>();
    final hasAdReady = adService.isRewardedAdLoaded;
    final gate = OfflinePlayGateService.instance;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          color: (isDark ? const Color(0xFF0F172A) : Colors.white)
              .withValues(alpha: 0.92),
          child: Stack(
            children: [
              // ── Background glow accents ───────────────────────────────
              RepaintBoundary(
                child: Stack(
                  children: [
                    Positioned(
                      top: -80.h,
                      right: -60.w,
                      child: _GlowOrb(
                        color: Colors.amber.withValues(
                          alpha: isDark ? 0.12 : 0.08,
                        ),
                        size: 350.r,
                      ),
                    ),
                    Positioned(
                      bottom: -120.h,
                      left: -80.w,
                      child: _GlowOrb(
                        color: Colors.deepPurple.withValues(
                          alpha: isDark ? 0.1 : 0.06,
                        ),
                        size: 400.r,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Close / Back Button ─────────────────────────────────────
              Positioned(
                top: MediaQuery.of(context).padding.top + 16.h,
                left: 16.w,
                child: GestureDetector(
                  onTap: () {
                    Haptics.vibrate(HapticsType.selection);
                    widget.onClose();
                  },
                  child: Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    ),
                    child: Icon(
                      LucideIcons.x,
                      color: isDark ? Colors.white : Colors.black87,
                      size: 24.r,
                    ),
                  ),
                ),
              ),

              // ── Main content ─────────────────────────────────────────
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 24.h,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 48.h,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // ── Icon + counter ──────────────────────────
                            _QuotaIcon(
                              isDark: isDark,
                              levelsPlayed: gate.offlineLevelsPlayed,
                            )
                                .animate()
                                .fadeIn(duration: 600.ms)
                                .scale(
                                  begin: const Offset(0.8, 0.8),
                                  end: const Offset(1.0, 1.0),
                                  curve: Curves.easeOutBack,
                                ),

                            SizedBox(height: 36.h),

                            // ── Title ───────────────────────────────────
                            Text(
                              context.tr(
                                'connectivity.quota_title',
                                fallback: 'OFFLINE LIMIT REACHED',
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 200.ms, duration: 600.ms)
                                .moveY(begin: 10, end: 0),

                            SizedBox(height: 12.h),

                            // ── Subtitle ────────────────────────────────
                            Text(
                              context.tr(
                                'connectivity.quota_subtitle',
                                fallback:
                                    'You\'ve played ${gate.offlineLevelsPlayed} levels offline. Reconnect or watch an ad to keep playing!',
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w400,
                                color: isDark ? Colors.white60 : Colors.black54,
                                height: 1.5,
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 400.ms, duration: 600.ms),

                            SizedBox(height: 40.h),

                            // ── Watch Ad Button (Primary CTA) ───────────
                            if (hasAdReady)
                              _ActionButton(
                                isDark: isDark,
                                isLoading: _isLoadingAd,
                                onTap: _handleWatchAd,
                                icon: LucideIcons.play,
                                label: context.tr(
                                  'connectivity.watch_ad_continue',
                                  fallback: 'WATCH AD FOR +3 LEVELS',
                                ),
                                gradient: const [
                                  Color(0xFF10B981),
                                  Color(0xFF059669),
                                ],
                                glowColor: const Color(0xFF10B981),
                              )
                                  .animate()
                                  .fadeIn(delay: 500.ms, duration: 600.ms)
                                  .moveY(begin: 20, end: 0),

                            if (hasAdReady) SizedBox(height: 16.h),

                            // ── Reconnect Button ────────────────────────
                            _ActionButton(
                              isDark: isDark,
                              isLoading: _isChecking,
                              onTap: _handleRetry,
                              icon: LucideIcons.wifi,
                              label: context.tr(
                                'connectivity.retry_button',
                                fallback: 'RECONNECT',
                              ),
                              gradient: const [
                                Color(0xFF6366F1),
                                Color(0xFF1D4ED8),
                              ],
                              glowColor: Colors.blue,
                            )
                                .animate()
                                .fadeIn(delay: 600.ms, duration: 600.ms)
                                .moveY(begin: 20, end: 0),

                            SizedBox(height: 20.h),

                            // ── Premium Upsell ──────────────────────────
                            GestureDetector(
                              onTap: () {
                                Haptics.vibrate(HapticsType.light);
                                AppRouter.router
                                    .push(AppRouter.premiumRoute);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 14.h,
                                  horizontal: 24.w,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.amber.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: Colors.amber
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.crown,
                                      color: Colors.amber,
                                      size: 20.r,
                                    ),
                                    SizedBox(width: 8.w),
                                    Flexible(
                                      child: Text(
                                        context.tr(
                                          'connectivity.go_premium',
                                          fallback:
                                              'Play Offline with Premium',
                                        ),
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          color: Colors.amber,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 800.ms, duration: 600.ms)
                                .moveY(begin: 10, end: 0),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _QuotaIcon extends StatelessWidget {
  final bool isDark;
  final int levelsPlayed;
  const _QuotaIcon({required this.isDark, required this.levelsPlayed});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing rings
        ...List.generate(3, (i) {
          return Container(
                width: (140 + i * 36).r,
                height: (140 + i * 36).r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.04 * (3 - i)),
                    width: 1.5,
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.08, 1.08),
                duration: (2000 + i * 400).ms,
                curve: Curves.easeInOut,
              )
              .fadeOut();
        }),

        // Core disk
        Container(
          width: 120.r,
          height: 120.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.amber.withValues(alpha: 0.1)
                : Colors.amber.withValues(alpha: 0.12),
            border: Border.all(
              color: Colors.amber.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: isDark ? 0.1 : 0.06),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.wifiOff,
                size: 36.r,
                color: Colors.amber[400],
              ),
              SizedBox(height: 4.h),
              Text(
                '$levelsPlayed/${OfflinePlayGateService.maxOfflineLevels}',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.amber[400],
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .shimmer(
              duration: 3000.ms,
              color: Colors.amber.withValues(alpha: 0.15),
            ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  final bool isDark;
  final bool isLoading;
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final Color glowColor;

  const _ActionButton({
    required this.isDark,
    required this.isLoading,
    required this.onTap,
    required this.icon,
    required this.label,
    required this.gradient,
    required this.glowColor,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _scale = 0.96),
      onPointerUp: (_) => setState(() => _scale = 1.0),
      onPointerCancel: (_) => setState(() => _scale = 1.0),
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onTap,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: Container(
            height: 58.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
              gradient: LinearGradient(
                colors: widget.isLoading
                    ? widget.gradient
                        .map((c) => c.withValues(alpha: 0.5))
                        .toList()
                    : widget.gradient,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18.r),
              child: Stack(
                children: [
                  if (!widget.isLoading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  Center(
                    child: widget.isLoading
                        ? SizedBox(
                            width: 22.r,
                            height: 22.r,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.icon,
                                color: Colors.white,
                                size: 20.r,
                              ),
                              SizedBox(width: 10.w),
                              Flexible(
                                child: Text(
                                  widget.label,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color: Colors.white,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color, blurRadius: size / 2, spreadRadius: size / 4),
          ],
        ),
      ),
    );
  }
}
