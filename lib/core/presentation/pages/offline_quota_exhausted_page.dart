import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/vowl_button_spinner.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/offline_play_gate_service.dart';
import 'package:vowl/core/utils/offline_reward_sync_service.dart';

/// Shown when a free user exhausts their offline play quota.
///
/// Designed with a pure [ValueNotifier] state architecture to eliminate
/// full-screen rebuilds and wasteful polling. Provides clear monetization paths:
///  1. **RECONNECT** — primary brand action; reconnecting restores unlimited free play.
///  2. **WATCH AD** — secondary action; cached rewarded ad grants bonus offline plays.
///  3. **GO PREMIUM** — tertiary upsell; 100% unlimited offline play everywhere.
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
  // Pure fine-grained ValueNotifiers — no full setState() widget rebuilds.
  late final ValueNotifier<bool> _isChecking = ValueNotifier<bool>(false);
  late final ValueNotifier<bool> _isLoadingAd = ValueNotifier<bool>(false);
  late final ValueNotifier<bool> _hasAdReady;

  Timer? _adPollTimer;
  Timer? _loadingAdTimeout;

  @override
  void initState() {
    super.initState();
    final isLoaded = di.sl<AdService>().isRewardedAdLoaded;
    _hasAdReady = ValueNotifier<bool>(isLoaded);

    // If an ad is not yet loaded, poll until ready, then immediately cancel.
    if (!isLoaded) {
      _adPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (!mounted) return;
        final readyNow = di.sl<AdService>().isRewardedAdLoaded;
        if (readyNow) {
          _hasAdReady.value = true;
          _adPollTimer?.cancel();
          _adPollTimer = null;
        }
      });
    }
  }

  @override
  void dispose() {
    _adPollTimer?.cancel();
    _loadingAdTimeout?.cancel();
    _isChecking.dispose();
    _isLoadingAd.dispose();
    _hasAdReady.dispose();
    super.dispose();
  }

  Future<void> _handleRetry() async {
    if (_isChecking.value) return;
    _isChecking.value = true;
    Haptics.vibrate(HapticsType.selection);

    try {
      await widget.onRetry();
      if (mounted && di.sl.isRegistered<NetworkInfo>()) {
        final isStillOffline = di.sl<NetworkInfo>().isCurrentlyOffline;
        if (isStillOffline) {
          CustomSnackBar.show(
            context: context,
            message: context.tr(
              'connectivity.still_offline',
              fallback:
                  'No internet connection detected. Please check Wi-Fi or data.',
            ),
            type: CustomSnackBarType.warning,
          );
        } else {
          if (di.sl.isRegistered<OfflineRewardSyncService>()) {
            unawaited(di.sl<OfflineRewardSyncService>().syncPendingRewards());
          }
        }
      }
    } finally {
      if (mounted) {
        _isChecking.value = false;
      }
    }
  }

  void _handleWatchAd() {
    if (_isLoadingAd.value) return;
    Haptics.vibrate(HapticsType.selection);

    final adService = di.sl<AdService>();
    if (!adService.isRewardedAdLoaded) {
      _hasAdReady.value = false;
      Haptics.vibrate(HapticsType.warning);
      CustomSnackBar.show(
        context: context,
        message: context.tr(
          'connectivity.no_ad_cached',
          fallback: 'No ad available offline. Please reconnect to continue.',
        ),
        type: CustomSnackBarType.warning,
      );
      return;
    }

    _isLoadingAd.value = true;

    // Safety fallback: reset loading indicator if ad SDK dismiss callback drops
    _loadingAdTimeout?.cancel();
    _loadingAdTimeout = Timer(const Duration(seconds: 15), () {
      if (mounted) {
        _isLoadingAd.value = false;
      }
    });

    adService.showRewardedAd(
      context: context,
      isPremium: false,
      onUserEarnedReward: (_) {
        OfflinePlayGateService.instance.grantBonusOfflinePlays();
        widget.onAdWatched();
      },
      onDismissed: () {
        _loadingAdTimeout?.cancel();
        if (mounted) {
          _isLoadingAd.value = false;
          _hasAdReady.value = adService.isRewardedAdLoaded;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final gate = OfflinePlayGateService.instance;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Frosted blur backdrop
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: const SizedBox.expand(),
          ),

          // 2. Consistent brand surface tint overlay
          Container(
            color: (isMidnight
                    ? AppColors.midnightSurface
                    : (isDark ? AppColors.slate900 : Colors.white))
                .withValues(alpha: 0.96),
          ),

          // 3. Subtle, cohesive background ambient accent
          RepaintBoundary(
            child: Stack(
              children: [
                Positioned(
                  top: -80.h,
                  right: -60.w,
                  child: _GlowOrb(
                    color: AppColors.indigo500.withValues(
                      alpha: isDark ? 0.09 : 0.05,
                    ),
                    size: 320.r,
                  ),
                ),
              ],
            ),
          ),

          // 4. Main Scrollable Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Top Counter Disc
                Widget iconCounter = _QuotaIcon(
                  isDark: isDark,
                  levelsPlayed: gate.offlineLevelsPlayed,
                );

                // Title
                Widget title = Text(
                  context.tr(
                    'connectivity.quota_title',
                    fallback: 'OFFLINE LIMIT REACHED',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                );

                // Subtitle (reacts to ad readiness via ValueNotifier)
                Widget subtitle = ValueListenableBuilder<bool>(
                  valueListenable: _hasAdReady,
                  builder: (context, hasAd, _) {
                    final String subtitleText = hasAd
                        ? context.tr(
                            'connectivity.quota_subtitle',
                            args: [gate.offlineLevelsPlayed.toString()],
                            fallback:
                                'You\'ve played ${gate.offlineLevelsPlayed} levels offline. Reconnect or watch an ad to keep playing!',
                          )
                        : context.tr(
                            'connectivity.quota_subtitle_no_ad',
                            args: [gate.offlineLevelsPlayed.toString()],
                            fallback:
                                'You\'ve played ${gate.offlineLevelsPlayed} levels offline. Reconnect to restore unlimited free play!',
                          );

                    return Text(
                      subtitleText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w400,
                        color: isDark ? AppColors.slate400 : AppColors.slate600,
                        height: 1.45,
                      ),
                    );
                  },
                );

                // Neutral Reassurance Card
                Widget unlimitedCard = _UnlimitedPlayCard(isDark: isDark);

                // Secondary CTA: Watch Ad Button (rendered reactively via ValueNotifier)
                Widget watchAdSection = ValueListenableBuilder<bool>(
                  valueListenable: _hasAdReady,
                  builder: (context, hasAd, _) {
                    if (!hasAd) return const SizedBox.shrink();

                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _isLoadingAd,
                        builder: (context, isLoading, _) {
                          return _SecondaryAdButton(
                            isDark: isDark,
                            isLoading: isLoading,
                            onTap: _handleWatchAd,
                            label: context.tr(
                              'connectivity.watch_ad_continue',
                              fallback: 'WATCH AD FOR +3 LEVELS',
                            ),
                          );
                        },
                      ),
                    );
                  },
                );

                // Primary CTA: Retry Connection Button (reacts to _isChecking ValueNotifier)
                Widget reconnectBtn = ValueListenableBuilder<bool>(
                  valueListenable: _isChecking,
                  builder: (context, isChecking, _) {
                    return _PrimaryActionButton(
                      isLoading: isChecking,
                      onTap: _handleRetry,
                      icon: LucideIcons.wifi,
                      label: context.tr(
                        'connectivity.retry_button',
                        fallback: 'RETRY CONNECTION',
                      ),
                    );
                  },
                );

                // Tertiary Upsell: Go Premium Link
                Widget premiumBtn = ScaleButton(
                  onTap: () {
                    Haptics.vibrate(HapticsType.light);
                    AppRouter.router.push(AppRouter.premiumRoute);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 11.h,
                      horizontal: 16.w,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: isDark ? 0.08 : 0.1),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.crown,
                          color: Colors.amber,
                          size: 18.r,
                        ),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: Text(
                            context.tr(
                              'connectivity.go_premium',
                              fallback: 'Play Offline with Premium',
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: isDark ? Colors.amber[300] : Colors.amber[800],
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                // Ad hint for no-ad scenario
                Widget adHintSection = ValueListenableBuilder<bool>(
                  valueListenable: _hasAdReady,
                  builder: (context, hasAd, _) {
                    if (hasAd) return const SizedBox.shrink();
                    return Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Text(
                        context.tr(
                          'connectivity.no_ad_cached_hint',
                          fallback:
                              'Need bonus offline plays? Connect once to load rewarded ads or upgrade to Premium.',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.slate500 : AppColors.slate400,
                          height: 1.35,
                        ),
                      ),
                    );
                  },
                );

                // Apply crisp, snappy entrance animation (max 300ms, not 1400ms)
                Widget content = Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    iconCounter,
                    SizedBox(height: 20.h),
                    title,
                    SizedBox(height: 8.h),
                    subtitle,
                    SizedBox(height: 16.h),
                    unlimitedCard,
                    SizedBox(height: 20.h),
                    watchAdSection,
                    reconnectBtn,
                    SizedBox(height: 14.h),
                    premiumBtn,
                    adHintSection,
                  ],
                );

                if (!reduceMotion) {
                  content = content
                      .animate()
                      .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                      .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 20.h,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 40.h,
                    ),
                    child: content,
                  ),
                );
              },
            ),
          ),

          // 5. Close / Exit Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12.h,
            left: 16.w,
            child: Semantics(
              button: true,
              label: 'Close',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Haptics.vibrate(HapticsType.selection);
                  widget.onClose();
                },
                child: Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  child: Icon(
                    LucideIcons.x,
                    color: isDark ? Colors.white : AppColors.slate900,
                    size: 22.r,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private Sub-Widgets with Unified AppColors Tokens
// ---------------------------------------------------------------------------

class _UnlimitedPlayCard extends StatelessWidget {
  final bool isDark;
  const _UnlimitedPlayCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.slate800.withValues(alpha: 0.6)
            : AppColors.slate100,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? AppColors.slate700 : AppColors.slate200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(7.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.indigo500.withValues(
                alpha: isDark ? 0.2 : 0.12,
              ),
            ),
            child: Icon(
              LucideIcons.infinity,
              color: isDark ? AppColors.indigo400 : AppColors.indigo600,
              size: 18.r,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(
                    'connectivity.unlimited_online_title',
                    fallback: 'Online Play is Always Unlimited',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  context.tr(
                    'connectivity.unlimited_online_desc',
                    fallback:
                        'Turn on Wi-Fi or mobile data to continue playing for free without limits!',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w400,
                    color: isDark ? AppColors.slate400 : AppColors.slate600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuotaIcon extends StatelessWidget {
  final bool isDark;
  final int levelsPlayed;
  const _QuotaIcon({required this.isDark, required this.levelsPlayed});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Subtle ambient ring
        Container(
          width: 140.r,
          height: 140.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.amber.withValues(alpha: isDark ? 0.08 : 0.12),
              width: 1.5,
            ),
          ),
        ),

        // Core disc
        Container(
          width: 110.r,
          height: 110.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.amber.withValues(alpha: isDark ? 0.1 : 0.12),
            border: Border.all(
              color: Colors.amber.withValues(alpha: 0.35),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.wifiOff,
                size: 32.r,
                color: isDark ? Colors.amber[300] : Colors.amber[700],
              ),
              SizedBox(height: 3.h),
              Text(
                '$levelsPlayed/${OfflinePlayGateService.maxOfflineLevels}',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.amber[300] : Colors.amber[700],
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  final IconData icon;
  final String label;

  const _PrimaryActionButton({
    required this.isLoading,
    required this.onTap,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: isLoading ? () {} : onTap,
      child: Container(
        height: 52.h,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: const LinearGradient(
            colors: [AppColors.indigo500, AppColors.indigo600],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.indigo500.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const VowlButtonSpinner(color: Colors.white, size: 20)
              : Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 19.r),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: Colors.white,
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _SecondaryAdButton extends StatelessWidget {
  final bool isDark;
  final bool isLoading;
  final VoidCallback onTap;
  final String label;

  const _SecondaryAdButton({
    required this.isDark,
    required this.isLoading,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: isLoading ? () {} : onTap,
      child: Container(
        height: 50.h,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: isDark
              ? AppColors.emerald950.withValues(alpha: 0.35)
              : AppColors.emerald50,
          border: Border.all(
            color: isDark
                ? AppColors.emerald500.withValues(alpha: 0.5)
                : AppColors.emerald500.withValues(alpha: 0.6),
            width: 1.2,
          ),
        ),
        child: Center(
          child: isLoading
              ? VowlButtonSpinner(
                  color: isDark ? AppColors.emerald400 : AppColors.emerald600,
                  size: 18,
                )
              : Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.play,
                        color: isDark
                            ? AppColors.emerald400
                            : AppColors.emerald600,
                        size: 17.r,
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: isDark
                                ? AppColors.emerald400
                                : AppColors.emerald600,
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
            BoxShadow(
              color: color,
              blurRadius: size / 2,
              spreadRadius: size / 4,
            ),
          ],
        ),
      ),
    );
  }
}
