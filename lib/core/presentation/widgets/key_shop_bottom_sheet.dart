import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/modern_game_dialog.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/domain/usecases/purchase_golden_key.dart';
import 'package:vowl/features/auth/domain/usecases/add_golden_key.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/presentation/widgets/premium_store_bottom_sheet.dart';
import 'package:vowl/core/utils/reward_limit_service.dart';

class KeyShopBottomSheet {
  static void show({
    required BuildContext context,
    required bool isKidsMode,
    Color primaryColor = Colors.amber,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _KeyShopContent(
          parentContext: context,
          isKidsMode: isKidsMode,
          primaryColor: primaryColor,
        );
      },
    );
  }
}

class _KeyShopContent extends StatefulWidget {
  final BuildContext parentContext;
  final bool isKidsMode;
  final Color primaryColor;

  const _KeyShopContent({
    required this.parentContext,
    required this.isKidsMode,
    required this.primaryColor,
  });

  @override
  State<_KeyShopContent> createState() => _KeyShopContentState();
}

class _KeyShopContentState extends State<_KeyShopContent> {
  int _remainingClaims = RewardLimitService.maxClaimsPerDay;
  bool _isLoadingLimits = true;

  @override
  void initState() {
    super.initState();
    _loadLimits();
  }

  Future<void> _loadLimits() async {
    final remaining = await RewardLimitService.getRemainingClaims('keys');
    if (mounted) {
      setState(() {
        _remainingClaims = remaining;
        _isLoadingLimits = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = widget.parentContext.read<AuthBloc>().state.user?.isPremium ?? false;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.pop(context),
      child: GestureDetector(
        onTap: () {}, // Prevent taps on the sheet content from closing it
        child: Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
            border: Border.all(
              color: widget.primaryColor.withValues(alpha: 0.3),
              width: 1.5.w,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withValues(alpha: 0.15),
                blurRadius: 24.r,
                offset: Offset(0, -4.h),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 16.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.primaryColor.withValues(alpha: 0.15),
                        widget.primaryColor.withValues(alpha: 0.25),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.primaryColor.withValues(alpha: 0.4),
                      width: 1.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.primaryColor.withValues(alpha: 0.2),
                        blurRadius: 16.r,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.key_rounded,
                    size: 56.r,
                    color: widget.primaryColor,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                      duration: 2.seconds,
                      delay: 1.seconds,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                SizedBox(height: 16.h),
                Text(
                  context.tr(
                    'store.golden_keys_title',
                    fallback: 'Golden Keys',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: widget.primaryColor,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  context.tr(
                    'store.golden_keys_desc',
                    fallback:
                        'Get a Golden Key to unlock Toll Gates on the map!',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 24.h),

                // Purchase with Coins
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    final user = authState.user;
                    final userCoins = widget.isKidsMode
                        ? (user?.kidsCoins ?? 0)
                        : (user?.coins ?? 0);
                    const int cost = 150;

                    return ScaleButton(
                      onTap: () async {
                        if (userCoins < cost) {
                          Navigator.pop(context);
                          if (!widget.parentContext.mounted) return;
                          // BUG FIX (STALE CONTEXT): was `context: context`
                          // (this BlocBuilder's own, sheet-scoped context)
                          // used right after Navigator.pop deactivated the
                          // sheet it belongs to. `parentContext` (captured
                          // before the sheet was shown) is what every other
                          // dialog in this file correctly uses for this
                          // exact situation.
                          showDialog(
                            context: widget.parentContext,
                            builder: (ctx) => ModernGameDialog(
                              title: widget.isKidsMode
                                  ? context.tr(
                                      'store.not_enough_toys_title',
                                      fallback: 'NOT ENOUGH TOYS',
                                    )
                                  : context.tr(
                                      'store.not_enough_coins_title',
                                      fallback: 'NOT ENOUGH COINS',
                                    ),
                              description: context.tr(
                                'store.not_enough_currency_desc',
                                args: [
                                  '$cost',
                                  widget.isKidsMode
                                      ? context.tr('store.toys_lower')
                                      : context.tr('store.coins_lower'),
                                ],
                                fallback:
                                    'You need $cost ${widget.isKidsMode ? 'toys' : 'coins'} to get a key!',
                              ),
                              buttonText: context.tr(
                                'games.keep_playing',
                                fallback: 'KEEP PLAYING',
                              ),
                              isSuccess: false,
                              onButtonPressed: () => Navigator.of(ctx).pop(),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context);
                        final result = await di.sl<PurchaseGoldenKey>().call(
                          PurchaseGoldenKeyParams(
                            cost: cost,
                            isKidsMode: widget.isKidsMode,
                          ),
                        );

                        if (!widget.parentContext.mounted) return;

                        // BUG FIX (SILENT FAILURE): previously only the
                        // success branch (`result.isRight()`) was handled -
                        // if the purchase failed server-side (insufficient
                        // funds detected server-side, network error,
                        // concurrent-spend race, etc.), the sheet had
                        // already closed and NOTHING told the user their
                        // 150 coins purchase didn't go through. `.fold()`
                        // now handles both outcomes explicitly.
                        result.fold(
                          (failure) {
                            showDialog(
                              context: widget.parentContext,
                              builder: (ctx) => ModernGameDialog(
                                title: context.tr(
                                  'store.purchase_failed_title',
                                  fallback: 'PURCHASE FAILED',
                                ),
                                description: context.tr(
                                  'store.purchase_failed_desc',
                                  fallback:
                                      'Something went wrong and your coins were not spent. Please try again.',
                                ),
                                buttonText: context
                                    .tr('common.ok', fallback: 'OK')
                                    .toUpperCase(),
                                isSuccess: false,
                                onButtonPressed: () => Navigator.of(ctx).pop(),
                              ),
                            );
                          },
                          (_) {
                            widget.parentContext.read<AuthBloc>().add(
                              const AuthReloadUser(),
                            );
                            showDialog(
                              context: widget.parentContext,
                              builder: (ctx) => Material(
                                type: MaterialType.transparency,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ModernGameDialog(
                                      title: context.tr(
                                        'store.got_key_title',
                                        fallback: 'GOT A KEY!',
                                      ),
                                      description: context.tr(
                                        'store.got_key_desc',
                                        fallback: 'You got a Golden Key! 🗝️',
                                      ),
                                      buttonText: context.tr(
                                        'store.awesome',
                                        fallback: 'AWESOME',
                                      ),
                                      isSuccess: true,
                                      onButtonPressed: () =>
                                          Navigator.of(ctx).pop(),
                                    ),
                                    const Positioned.fill(
                                      child: IgnorePointer(
                                        child: GameConfetti(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: userCoins >= cost
                                ? [widget.primaryColor, Colors.amber.shade700]
                                : [Colors.grey.shade400, Colors.grey.shade500],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.w,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (userCoins >= cost
                                          ? widget.primaryColor
                                          : Colors.grey.shade500)
                                      .withValues(alpha: 0.4),
                              offset: Offset(0, 4.h),
                              blurRadius: 8.r,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.monetization_on_rounded,
                              color: Colors.white,
                              size: 20.r,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              context.tr(
                                'store.buy_for',
                                args: ['$cost'],
                                fallback: 'Buy for $cost',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 12.h),

                // Get with Ad
                ScaleButton(
                  onTap: _remainingClaims <= 0
                      ? null
                      : () {
                    final adService = di.sl<AdService>();
                    // FIX: Read premium status from AuthBloc instead of
                    // hardcoding `false`. Premium users who open the key
                    // shop (e.g. via Kids Zone toll gate) should get the
                    // premium bypass, not be forced to watch an ad.
                    if (!isPremium && !adService.isRewardedAdLoaded) {
                      Navigator.pop(context);
                      showDialog(
                        context: widget.parentContext,
                        builder: (ctx) => ModernGameDialog(
                          title: context.tr(
                            'store.ad_not_ready_title',
                            fallback: 'AD NOT READY',
                          ),
                          description: context.tr(
                            'games.ad_not_ready',
                            fallback:
                                'Ad not ready yet, try again in a moment.',
                          ),
                          buttonText: context.tr('store.ok', fallback: 'OK'),
                          isSuccess: false,
                          onButtonPressed: () => Navigator.of(ctx).pop(),
                          customIcon: Icon(
                            Icons.hourglass_empty_rounded,
                            color: Colors.orange,
                            size: 48.sp,
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    adService.showRewardedAd(
                      context: widget.parentContext,
                      isPremium: isPremium,
                      // FIX: COPPA compliance — when the key shop is opened
                      // from Kids Zone (isKidsMode: true), force child-safe
                      // ad parameters.
                      childSafe: widget.isKidsMode,
                      onUserEarnedReward: (_) async {
                        final result = await di.sl<AddGoldenKey>().call(
                          const AddGoldenKeyParams(amount: 1),
                        );

                        if (!widget.parentContext.mounted) return;

                        await RewardLimitService.incrementClaimCount('keys');
                        if (mounted) await _loadLimits();

                        // BUG FIX (SILENT FAILURE): same missing-failure-
                        // handling issue as the coin-purchase flow above -
                        // worse here, since the user has already watched a
                        // full rewarded ad. Silently doing nothing on
                        // failure would mean "watched an ad, got nothing,
                        // no explanation why."
                        result.fold(
                          (failure) {
                            showDialog(
                              context: widget.parentContext,
                              builder: (ctx) => ModernGameDialog(
                                title: context.tr(
                                  'store.reward_failed_title',
                                  fallback: 'REWARD FAILED',
                                ),
                                description: context.tr(
                                  'store.reward_failed_desc',
                                  fallback:
                                      "We couldn't grant your reward. Please contact support if this keeps happening.",
                                ),
                                buttonText: context
                                    .tr('common.ok', fallback: 'OK')
                                    .toUpperCase(),
                                isSuccess: false,
                                onButtonPressed: () => Navigator.of(ctx).pop(),
                              ),
                            );
                          },
                          (_) {
                            widget.parentContext.read<AuthBloc>().add(
                              const AuthReloadUser(),
                            );
                            showDialog(
                              context: widget.parentContext,
                              builder: (ctx) => Material(
                                type: MaterialType.transparency,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ModernGameDialog(
                                      title: context.tr(
                                        'store.reward_unlocked_title',
                                        fallback: 'REWARD UNLOCKED!',
                                      ),
                                      description: context.tr(
                                        'store.got_key_desc',
                                        fallback: 'You got a Golden Key! 🗝️',
                                      ),
                                      buttonText: context.tr(
                                        'store.awesome',
                                        fallback: 'AWESOME',
                                      ),
                                      isSuccess: true,
                                      onButtonPressed: () =>
                                          Navigator.of(ctx).pop(),
                                    ),
                                    const Positioned.fill(
                                      child: IgnorePointer(
                                        child: GameConfetti(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      onDismissed: () {},
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.4),
                          offset: Offset(0, 4.h),
                          blurRadius: 8.r,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isPremium ? Icons.redeem_rounded : Icons.play_circle_fill_rounded,
                          color: Colors.white,
                          size: 20.r,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          _isLoadingLimits
                              ? context.tr('store.loading_ad', fallback: 'Loading...')
                              : _remainingClaims <= 0
                                  ? context.tr('store.daily_limit_reached', fallback: "Daily Limit Reached")
                                  : isPremium
                                      ? context.tr(
                                          'store.claim_free_key',
                                          fallback: 'Claim 1 Free Key',
                                        )
                                      : context.tr(
                                          'store.watch_ad_key',
                                          fallback: 'Watch Ad for 1 Key',
                                        ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Open Premium Store
                ScaleButton(
                  onTap: () {
                    Navigator.pop(context);
                    PremiumStoreBottomSheet.show(
                      context: widget.parentContext,
                      isKidsMode: widget.isKidsMode,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                          offset: Offset(0, 4.h),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.storefront_rounded,
                          color: Colors.white,
                          size: 20.r,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          context.tr(
                            'store.get_more_coins_keys',
                            fallback: 'Get More Coins & Keys',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (!isPremium) ...[
                  SizedBox(height: 24.h),

                  // Premium bypass info
                  ScaleButton(
                    onTap: () {
                      Navigator.pop(context);
                      widget.parentContext.push(AppRouter.premiumRoute);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: 16.h,
                        horizontal: 16.w,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                          width: 1.w,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF59E0B,
                              ).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.workspace_premium_rounded,
                              color: const Color(0xFFF59E0B),
                              size: 24.r,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr(
                                    'store.tired_of_keys',
                                    fallback: 'Tired of Keys?',
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFFF59E0B),
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  context.tr(
                                    'store.premium_bypass_gates',
                                    fallback: 'Premium users bypass all gates!',
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: const Color(0xFFF59E0B),
                            size: 24.r,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
