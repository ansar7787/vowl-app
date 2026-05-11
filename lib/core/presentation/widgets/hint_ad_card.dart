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

class HintAdCard extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  final String? title;
  final String? subtitle;

  const HintAdCard({
    super.key,
    this.margin,
    this.title,
    this.subtitle,
  });

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
              (title ?? 'WATCH AND EARN HINTS').toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFF59E0B),
                letterSpacing: 2.0,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lightbulb_rounded,
                          color: const Color(0xFFF59E0B),
                          size: 16.r,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          subtitle ?? '1 STRATEGIC HINT',
                          style: GoogleFonts.outfit(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                ScaleButton(
                  onTap: () => _showHintAd(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
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

  void _showHintAd(BuildContext context) {
    bool rewardEarned = false;
    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;

    di.sl<AdService>().showHintRewardedAd(
      isPremium: isPremium,
      onHintEarned: () {
        rewardEarned = true;
        // Use a new event or just add to coins/hints
        // I'll use a direct hint addition event if it exists or AddHintRequested
        context.read<EconomyBloc>().add(
          const EconomyPurchaseHintRequested(0, hintAmount: 1), // Cost 0 for Ad
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
                    'Hint Earned! +1 Strategic Hint',
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
