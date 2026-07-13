import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';

/// Card widget that awards 20 Vowl Coins in exchange for watching a
/// rewarded video ad.
///
/// Uses a [ValueNotifier] for local ad-loading state so the parent widget
/// tree is not rebuilt unnecessarily.
class AdRewardCard extends StatefulWidget {
  final EdgeInsetsGeometry? margin;

  const AdRewardCard({super.key, this.margin});

  @override
  State<AdRewardCard> createState() => _AdRewardCardState();
}

class _AdRewardCardState extends State<AdRewardCard> {
  /// Prevents duplicate taps while an ad is already loading or showing.
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);

  static const int _coinReward = 20;

  @override
  void dispose() {
    _isLoading.dispose();
    super.dispose();
  }

  Future<void> _showRewardAd() async {
    if (_isLoading.value) return;
    _isLoading.value = true;

    bool rewardEarned = false;
    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;

    try {
      di.sl<AdService>().showRewardedAd(
        context: context,
        isPremium: isPremium,
        onUserEarnedReward: (reward) {
          rewardEarned = true;
          if (!context.mounted) return;
          context.read<EconomyBloc>().add(
            EconomyAddCoinsRequested(
              _coinReward,
              title: context.tr(
                'games.watched_rewarded_ad_title',
                fallback: 'Watched Rewarded Ad',
              ),
              isEarned: true,
            ),
          );
        },
        onDismissed: () {
          if (rewardEarned && context.mounted) {
            CustomSnackBar.show(
              context: context,
              message: context.tr(
                'games.coins_reward_earned_snack', fallback: 'Coins Earned!',
                args: ['$_coinReward'],
                fallback: 'Reward Earned! +$_coinReward Vowl Coins',
              ),
              type: CustomSnackBarType.success,
            );
          }
        },
      );
    } finally {
      // Always release the loading gate, even if the ad errors out.
      if (mounted) _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin:
          widget.margin ??
          EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      child: GlassTile(
        borderRadius: BorderRadius.circular(24.r),
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr(
                'games.watch_earn_coins_title',
                fallback: 'WATCH AND EARN COINS',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF2563EB),
                letterSpacing: 2.0,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ── Coin label ────────────────────────────────────
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.monetization_on_rounded,
                          color: const Color(0xFF10B981),
                          size: 16.r,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          context.tr(
                            'games.vowl_coins_amount', fallback: 'Coins',
                            args: ['$_coinReward'],
                            fallback: '$_coinReward VOWL COINS',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 8.w),

                // ── Watch button ──────────────────────────────────
                ValueListenableBuilder<bool>(
                  valueListenable: _isLoading,
                  builder: (context, loading, child) {
                    return Semantics(
                      button: true,
                      enabled: !loading,
                      label: context.tr(
                        'games.coins_semantic_label', fallback: 'Coins amount',
                        args: ['$_coinReward'],
                        fallback: 'Watch ad to earn $_coinReward coins',
                      ),
                      child: ScaleButton(
                        onTap: loading ? null : _showRewardAd,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          constraints: BoxConstraints(minHeight: 48.h),
                          decoration: BoxDecoration(
                            gradient: loading
                                ? null
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFF2563EB),
                                      Color(0xFF6366F1),
                                    ],
                                  ),
                            color: loading
                                ? const Color(0xFF2563EB).withValues(alpha: 0.4)
                                : null,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: loading
                                ? null
                                : [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF2563EB,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: loading
                              ? SizedBox(
                                  width: 18.r,
                                  height: 18.r,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 20.r,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      context.tr(
                                        'games.watch_button', fallback: 'Watch Ad',
                                        fallback: 'WATCH',
                                      ),
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
