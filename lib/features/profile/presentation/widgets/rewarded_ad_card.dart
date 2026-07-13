import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';

class RewardedAdCard extends StatefulWidget {
  /// Coins granted per successfully-watched ad. Single source of truth -
  /// previously this number (20) was duplicated across the default
  /// subtitle text, the EconomyAddCoinsRequested call, the success
  /// snackbar, and the button label, with no link between them; changing
  /// the reward meant remembering to update it in four places.
  final int rewardAmount;
  final String? title;
  final String? subtitle;

  const RewardedAdCard({
    super.key,
    this.rewardAmount = 20,
    this.title,
    this.subtitle,
  });

  @override
  State<RewardedAdCard> createState() => _RewardedAdCardState();
}

class _RewardedAdCardState extends State<RewardedAdCard> {
  // CONSOLIDATION FIX: Previously used the duplicate RewardedAdService
  // which maintained its own independent RewardedAd instance + load/retry
  // state, hitting the same ad unit ID as AdService — causing wasted SDK
  // quota and competing loads. Now uses the single canonical AdService.
  final _adService = di.sl<AdService>();
  bool _isLoading = false;

  Future<void> _handleWatchAd() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;

    bool rewardEarned = false;

    _adService.showRewardedAd(
      context: context,
      isPremium: isPremium,
      onUserEarnedReward: (_) {
        rewardEarned = true;
        if (!mounted) return;
        context.read<EconomyBloc>().add(
          EconomyAddCoinsRequested(
            widget.rewardAmount,
            title: 'Watched Rewarded Ad',
            isEarned: true,
          ),
        );
        CustomSnackBar.show(
          context: context,
          message: context.tr(
            'economy.reward_earned_coins', fallback: 'Coins Earned!',
            args: ['${widget.rewardAmount}'],
          ),
          type: CustomSnackBarType.success,
        );
      },
      onDismissed: () {
        if (!mounted) return;
        if (!rewardEarned) {
          // No snackbar for early dismissal — user chose to back out.
        }
        setState(() => _isLoading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ?? context.tr('economy.get_free_coins_title', fallback: 'Free Coins!');
    final subtitle =
        widget.subtitle ??
        context.tr(
          'economy.get_free_coins_subtitle', fallback: 'Watch an ad to earn 20 coins.',
          args: ['${widget.rewardAmount}'],
        );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.1),
            const Color(0xFFA855F7).withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.all(24.r),
      child: Row(
        children: [
          Container(
            width: 56.r,
            height: 56.r,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              LucideIcons.playCircle,
              color: const Color(0xFF6366F1),
              size: 28.r,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            enabled: !_isLoading,
            label: context.tr(
              'economy.watch_ad_button', fallback: 'Watch Ad',
              args: ['${widget.rewardAmount}'],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleWatchAd,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 18.r,
                      height: 18.r,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.coins, size: 14.r),
                        SizedBox(width: 4.w),
                        Text(
                          '+${widget.rewardAmount}',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w900,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1);
  }
}
