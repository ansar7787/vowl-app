import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';

class AdRewardCard extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  const AdRewardCard({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin ?? EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      child: GlassTile(
        borderRadius: BorderRadius.circular(24.r),
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WATCH AND EARN COINS',
              style: GoogleFonts.outfit(
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                    Text(
                      '20 VOWL COINS',
                      style: GoogleFonts.outfit(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                ScaleButton(
                  onTap: () => _showRewardAd(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF6366F1)],
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 20.r,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'WATCH',
                          style: GoogleFonts.outfit(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRewardAd(BuildContext context) {
    bool rewardEarned = false;
    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;

    di.sl<AdService>().showRewardedAd(
      isPremium: isPremium,
      onUserEarnedReward: (reward) {
        rewardEarned = true;
        // Use EconomyAddCoinsRequested to ensure history is logged
        context.read<EconomyBloc>().add(
          const EconomyAddCoinsRequested(
            20,
            title: 'Watched Rewarded Ad',
            isEarned: true,
          ),
        );
      },
      onDismissed: () {
        if (rewardEarned && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16.r,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Reward Earned! +20 Vowl Coins',
                    style: GoogleFonts.outfit(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              margin: EdgeInsets.all(16.r),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }
}
