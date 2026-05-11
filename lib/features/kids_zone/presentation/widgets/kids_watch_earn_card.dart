import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';

class KidsWatchEarnCard extends StatelessWidget {
  final Function(BuildContext, String, {bool isError}) showNotification;

  const KidsWatchEarnCard({
    super.key,
    required this.showNotification,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user;
        if (user == null) return const SizedBox.shrink();

        return ScaleButton(
          onTap: () {
            bool rewardEarned = false;
            di.sl<AdService>().showRewardedAd(
              isPremium: user.isPremium,
              onUserEarnedReward: (reward) {
                rewardEarned = true;
              },
              onDismissed: () {
                if (rewardEarned && context.mounted) {
                  context.read<EconomyBloc>().add(const EconomyAddKidsCoinsRequested(10));
                  showNotification(
                    context,
                    "📺 AWESOME! YOU GOT 10 🚗!",
                  );
                }
              },
            );
          },
          child: Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFF991B1B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white,
                    size: 32.sp,
                  ),
                ),
                SizedBox(width: 20.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "WATCH & EARN",
                        style: GoogleFonts.outfit(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Get 10 Kids Coins instantly!",
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 16.sp,
                ),
              ],
            ),
          )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 3.seconds, color: Colors.white24),
        );
      },
    );
  }
}
