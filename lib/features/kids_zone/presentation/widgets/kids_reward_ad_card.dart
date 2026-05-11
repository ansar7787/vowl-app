import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';

class KidsRewardAdCard extends StatelessWidget {
  const KidsRewardAdCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const kidsPrimaryColor = Color(0xFFF43F5E); // Matching Rose color for Kids Zone

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: GlassTile(
        borderRadius: BorderRadius.circular(32.r),
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: kidsPrimaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: kidsPrimaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Icon(
                    Icons.directions_car_rounded, // Red toy car style icon
                    color: kidsPrimaryColor,
                    size: 18.r,
                  ),
                ).animate(onPlay: (c) => c.repeat())
                 .shimmer(duration: 2.seconds, color: kidsPrimaryColor.withValues(alpha: 0.2)),
                SizedBox(width: 12.w),
                Text(
                  'KIDS WATCH & EARN',
                  style: GoogleFonts.outfit(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    color: kidsPrimaryColor,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Claim 10 Coins!',
                        style: GoogleFonts.outfit(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Watch a quick video to unlock rewards',
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white38 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                ScaleButton(
                  onTap: () => _showRewardAd(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF43F5E), Color(0xFFFB7185)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF43F5E).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20.r),
                        SizedBox(width: 6.w),
                        Text(
                          'START',
                          style: GoogleFonts.outfit(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
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
        context.read<EconomyBloc>().add(const EconomyAddKidsCoinsRequested(10));
      },
      onDismissed: () {
        if (rewardEarned && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.directions_car_rounded, color: Colors.white),
                  SizedBox(width: 12.w),
                  Text(
                    'Great! You earned 10 Kids Coins! 🏎️',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFF43F5E),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16.r),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          );
        }
      },
    );
  }
}
