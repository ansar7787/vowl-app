import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/vowl_button_spinner.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';

class KidsRewardAdCard extends StatefulWidget {
  const KidsRewardAdCard({super.key});

  @override
  State<KidsRewardAdCard> createState() => _KidsRewardAdCardState();
}

class _KidsRewardAdCardState extends State<KidsRewardAdCard> {
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);

  static const int _coinReward = 10;

  @override
  void dispose() {
    _isLoading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const kidsPrimaryColor = Color(
      0xFFF43F5E,
    ); // Matching Rose color for Kids Zone

    final title = context.tr(
      'home.kids_watch_earn_title',
      fallback: 'KIDS WATCH & EARN',
    );
    final claimTitle = context.tr(
      'home.kids_claim_coins',
      fallback: 'Claim $_coinReward Coins!',
      args: ['$_coinReward'],
    );
    final claimSubtitle = context.tr(
      'home.kids_claim_subtitle',
      fallback: 'Watch a quick video to unlock rewards',
    );
    final startLabel = context.tr(
      'home.kids_start_button',
      fallback: 'START',
    );

    return Semantics(
      button: true,
      label: '$title. $claimTitle. $claimSubtitle',
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.h),
        child: GlassTile(
          borderRadius: BorderRadius.circular(32.r),
          padding: EdgeInsets.all(24.r),
          child: ExcludeSemantics(
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
                            border: Border.all(
                              color: kidsPrimaryColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            Icons.star_rounded, // Star coin icon for Kids Zone
                            color: kidsPrimaryColor,
                            size: 18.r,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(
                          duration: 2.seconds,
                          color: kidsPrimaryColor.withValues(alpha: 0.2),
                        ),
                    SizedBox(width: 12.w),
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w900,
                          color: kidsPrimaryColor,
                          letterSpacing: 1.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                            claimTitle,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            claimSubtitle,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white38 : Colors.black45,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    ValueListenableBuilder<bool>(
                      valueListenable: _isLoading,
                      builder: (context, loading, child) {
                        return ScaleButton(
                          onTap: loading ? null : () => _showRewardAd(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 12.h,
                            ),
                            constraints: BoxConstraints(minHeight: 48.h),
                            decoration: BoxDecoration(
                              gradient: loading
                                  ? null
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFFF43F5E),
                                        Color(0xFFFB7185),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              color: loading
                                  ? kidsPrimaryColor.withValues(alpha: 0.4)
                                  : null,
                              borderRadius: BorderRadius.circular(24.r),
                              boxShadow: loading
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFF43F5E,
                                        ).withValues(alpha: 0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                            ),
                            child: loading
                                ? const VowlButtonSpinner(
                                    size: 18,
                                    color: Colors.white,
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 20.r,
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        startLabel,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w900,
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
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRewardAd(BuildContext context) {
    if (_isLoading.value) return;
    _isLoading.value = true;

    bool rewardEarned = false;
    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;

    try {
      di.sl<AdService>().showRewardedAd(
        context: context,
        isPremium: isPremium,
        childSafe: true,
        onUserEarnedReward: (reward) {
          rewardEarned = true;
          if (!context.mounted) return;
          context.read<EconomyBloc>().add(
            const EconomyAddKidsCoinsRequested(_coinReward),
          );
        },
        onDismissed: () {
          if (rewardEarned && context.mounted) {
            CustomSnackBar.show(
              context: context,
              message: context.tr(
                'home.kids_coins_earned_snack',
                fallback: 'Great! You earned $_coinReward Kids Coins! ⭐',
                args: ['$_coinReward'],
              ),
              type: CustomSnackBarType.info,
            );
          }
        },
      );
    } finally {
      if (mounted) _isLoading.value = false;
    }
  }
}


