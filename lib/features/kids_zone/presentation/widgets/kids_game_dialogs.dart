import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/features/auth/data/repositories/gamification_repository_impl.dart';

class KidsGameDialogs {
  static String _safeTr(BuildContext context, String key, String fallback) {
    final translation = context.tr(key);
    if (translation.isEmpty || translation == key) return fallback;
    return translation;
  }

  static Future<void> showCompletionDialog({
    required BuildContext context,
    required KidsGameComplete state,
    required Color primaryColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final adService = di.sl<AdService>();
    final user = context.read<AuthBloc>().state.user;
    final isPremium = user?.isPremium ?? false;
    bool rewardsDoubled = false;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Stack(
              children: [

                Center(
                  child: AlertDialog(
                    backgroundColor:
                        (isDark ? const Color(0xFF1E293B) : Colors.white)
                            .withValues(alpha: 0.95),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32.r),
                      side: BorderSide(
                        color: primaryColor.withValues(alpha: 0.5),
                        width: 3,
                      ),
                    ),
                    elevation: 24,
                    shadowColor: primaryColor.withValues(alpha: 0.4),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ICON HEADER
                          ValueListenableBuilder<int>(
                            valueListenable: GamificationRepositoryImpl.lastEarnedStars,
                            builder: (context, stars, child) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (index) {
                                  final isEarned = index < stars;
                                  return Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                                    child: Icon(
                                      Icons.star_rounded,
                                      size: index == 1 ? 48.sp : 36.sp,
                                      color: isEarned ? const Color(0xFFFFD700) : Colors.black12,
                                    ).animate(delay: (150 * index).ms).scale(
                                      duration: 500.ms,
                                      curve: Curves.elasticOut,
                                    ),
                                  );
                                }),
                              );
                            },
                          ),

                          SizedBox(height: 16.h),
                          Text(
                            context.tr('games.kids_level_up'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w900,
                              color: primaryColor,
                              fontSize: 22.sp,
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(height: 20.h),

                          // REWARDS CARD
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.03)
                                  : Colors.black.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(24.r),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildReward(
                                    context,
                                    state.coinsEarned * (rewardsDoubled ? 3 : 1),
                                    "🪙",
                                    _safeTr(context, 'games.kids_coins', 'KIDS COINS'),
                                    Colors.amber,
                                  ),
                                ),
                                Container(
                                  width: 1.5,
                                  height: 50.h,
                                  color: Colors.grey.withValues(alpha: 0.2),
                                ),
                                Expanded(
                                  child: _buildReward(
                                    context,
                                    state.xpEarned,
                                    "⚡",
                                    _safeTr(context, 'games.kids_xp', 'XP'),
                                    Colors.blueAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (state.stickerAwarded != null) ...[
                            SizedBox(height: 24.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 12.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    color: Colors.amber,
                                    size: 22.sp,
                                  ),
                                  SizedBox(width: 12.w),
                                  Text(
                                    context.tr('games.kids_new_sticker'),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontWeight: FontWeight.w800,
                                      color: Colors.amber[700],
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().scale(curve: Curves.elasticOut),
                          ],

                          SizedBox(height: 32.h),

                          if (!rewardsDoubled) ...[
                            Text(
                              _safeTr(context, 'games.triple_reward_desc', "Watch an ad to get 3x Coins!"),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w700,
                                fontSize: 13.sp,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: 600.ms),
                            SizedBox(height: 12.h),
                            ScaleButton(
                                  onTap: () {
                                    adService.showRewardedAd(
                                      isPremium: isPremium,
                                      onUserEarnedReward: (_) {
                                        context.read<KidsBloc>().add(
                                          ClaimDoubleKidsRewards(
                                            (context.read<KidsBloc>().state
                                                    as KidsLoaded)
                                                .gameType,
                                            (context.read<KidsBloc>().state
                                                    as KidsLoaded)
                                                .level,
                                          ),
                                        );
                                        setDialogState(
                                          () => rewardsDoubled = true,
                                        );
                                      },
                                      onDismissed: () {},
                                    );
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    height: 48.h,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFFD700),
                                          Color(0xFFFF9500),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFFF9500,
                                          ).withValues(alpha: 0.4),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.play_circle_fill_rounded,
                                            color: Colors.white,
                                            size: 20.r,
                                          ),
                                          SizedBox(width: 8.w),
                                          Flexible(
                                            child: Text(
                                              "TRIPLE REWARDS",
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                fontSize: 13.sp,
                                                letterSpacing: 1,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .animate(onPlay: (c) => c.repeat())
                                .shimmer(
                                  duration: 2.seconds,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                          ] else
                            Container(
                              width: double.infinity,
                              height: 48.h,
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.green,
                                      size: 18.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      "REWARDS TRIPLED!",
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontWeight: FontWeight.w900,
                                        color: Colors.green,
                                        fontSize: 12.sp,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().scale(curve: Curves.easeOutBack),

                          SizedBox(height: 12.h),

                          ScaleButton(
                            onTap: () {
                              adService.recordLevelCompletion();
                              context.read<AuthBloc>().add(const AuthRefreshUser());
                              context.pop(); // Pop dialog
                              context.pop(); // Pop game screen to return to map
                            },
                            child: Container(
                              width: double.infinity,
                              height: 48.h,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  context
                                      .tr('common.continue_text')
                                      .toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    fontSize: 13.sp,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                ),
                const Positioned.fill(
                  child: IgnorePointer(child: GameConfetti(shouldPop: false)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Future<void> showGameOverDialog({
    required BuildContext context,
    required Color primaryColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final adService = di.sl<AdService>();
    final user = context.read<AuthBloc>().state.user;
    final isPremium = user?.isPremium ?? false;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AlertDialog(
          backgroundColor: (isDark ? const Color(0xFF1E293B) : Colors.white)
              .withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32.r),
            side: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text("💔", style: TextStyle(fontSize: 48.sp)),
              ).animate().shake(duration: 600.ms),

              SizedBox(height: 20.h),
              Text(
                context.tr('games.kids_game_over'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w900,
                  color: Colors.redAccent,
                  fontSize: 32.sp,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                context.tr('games.kids_game_over_subtitle'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 32.h),

              ScaleButton(
                onTap: () {
                  adService.showRewardedAd(
                    isPremium: isPremium,
                    onUserEarnedReward: (_) {
                      context.read<KidsBloc>().add(RestoreKidsLife());
                      Navigator.pop(context);
                    },
                    onDismissed: () {},
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.green, Color(0xFF10B981)],
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.tr('games.kids_resume_game'),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontSize: 18.sp,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(
                          Icons.play_circle_fill_rounded,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16.h),
              TextButton(
                onPressed: () {
                  context.pop(); // Pop dialog
                  context.pop(); // Pop game screen
                },
                child: Text(
                  context.tr('games.kids_exit_to_map'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.grey,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
      ),
    );
  }

  static Future<bool> showExitConfirmation({
    required BuildContext context,
    required Color primaryColor,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return await showDialog<bool>(
          context: context,
          builder: (context) => BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AlertDialog(
              backgroundColor: (isDark ? const Color(0xFF1E293B) : Colors.white)
                  .withValues(alpha: 0.85),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ICON HEADER
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 40.r,
                    ),
                  ).animate().scale(
                    duration: 400.ms,
                    curve: Curves.easeOutBack,
                  ),

                  SizedBox(height: 20.h),

                  Text(
                    context.tr('games.kids_quit_title'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w900,
                      fontSize: 22.sp,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),

                  SizedBox(height: 12.h),

                  Text(
                    context.tr('games.kids_quit_subtitle'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),

                  SizedBox(height: 30.h),

                  Row(
                    children: [
                      Expanded(
                        child: ScaleButton(
                          onTap: () => Navigator.pop(context, true),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey[200],
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              context.tr('games.kids_quit_button'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white60
                                    : Colors.grey[600],
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ScaleButton(
                          onTap: () => Navigator.pop(context, false),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor,
                                  primaryColor.withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Text(
                              context.tr('games.kids_play_on'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          ),
        ) ??
        false;
  }

  static Widget _buildReward(
    BuildContext context,
    int amount,
    String emoji,
    String label,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(emoji, style: TextStyle(fontSize: 20.sp)),
        ).animate().scale(
          delay: 200.ms,
          duration: 400.ms,
          curve: Curves.easeOutBack,
        ),

        SizedBox(height: 8.h),

        Text(
          '+$amount',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w900,
            fontSize: 18.sp,
            color: color,
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

        SizedBox(height: 2.h),

        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w800,
            fontSize: 9.sp,
            color: color,
            letterSpacing: 1.2,
          ),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }
}
