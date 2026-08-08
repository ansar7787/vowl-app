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

import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/features/auth/data/repositories/gamification_repository_impl.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_dialog_components.dart';

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
    final adService = di.sl<AdService>();
    final authBloc = context.read<AuthBloc>();
    final kidsBloc = context.read<KidsBloc>();
    final navigator = Navigator.of(context);
    final user = authBloc.state.user;
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
              alignment: Alignment.center,
              children: [
                // Radiant Sunburst Background
                KidsSunburstBackground(color: primaryColor),
                
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: KidsDialogContainer(
                      primaryColor: primaryColor,
                      title: context.tr('games.kids_level_up', fallback: 'Level Up!'),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // STARS
                          ValueListenableBuilder<int>(
                            valueListenable: GamificationRepositoryImpl.lastEarnedStars,
                            builder: (context, stars, child) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (index) {
                                  final isEarned = index < stars;
                                  return Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                                    child: Container(
                                      width: index == 1 ? 65.r : 50.r,
                                      height: index == 1 ? 65.r : 50.r,
                                      decoration: BoxDecoration(
                                        color: isEarned ? const Color(0xFFFFD700) : Colors.grey[300],
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 4.w),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isEarned ? const Color(0xFFD97706) : Colors.grey[500]!,
                                            offset: Offset(0, 4.h),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(Icons.star_rounded, size: index == 1 ? 45.sp : 35.sp, color: Colors.white),
                                      ),
                                    ).animate(delay: (200 * index).ms).scale(curve: Curves.elasticOut),
                                  );
                                }),
                              );
                            },
                          ),
                          SizedBox(height: 24.h),
                          
                          // REWARDS CARD
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(24.r),
                              border: Border.all(color: primaryColor.withValues(alpha: 0.5), width: 4.w),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: _buildReward(context, state.coinsEarned * (rewardsDoubled ? 3 : 1), "🪙", _safeTr(context, 'games.kids_coins', 'KIDS COINS'), Colors.amber)),
                                Container(width: 2.w, height: 50.h, color: Colors.grey.withValues(alpha: 0.2)),
                                Expanded(child: _buildReward(context, state.xpEarned, "⚡", _safeTr(context, 'games.kids_xp', 'XP'), Colors.blueAccent)),
                              ],
                            ),
                          ),
                          
                          if (state.stickerAwarded != null) ...[
                            SizedBox(height: 16.h),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 22.sp),
                                  SizedBox(width: 8.w),
                                  Text(
                                    context.tr('games.kids_new_sticker', fallback: 'New Sticker!'),
                                    style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w800, color: Colors.amber[700], fontSize: 14.sp),
                                  ),
                                ],
                              ),
                            ).animate().scale(curve: Curves.elasticOut),
                          ],
                          
                          SizedBox(height: 32.h),
                          
                          if (!rewardsDoubled) ...[
                            Kids3DButton(
                              text: "WATCH AD FOR 3X REWARDS",
                              color: primaryColor,
                              isGolden: true,
                              icon: Icons.play_circle_fill_rounded,
                              onTap: () {
                                adService.showRewardedAd(
                                  context: context,
                                  isPremium: isPremium,
                                  childSafe: true,
                                  onUserEarnedReward: (_) {
                                    kidsBloc.add(ClaimDoubleKidsRewards((kidsBloc.state as KidsLoaded).gameType, (kidsBloc.state as KidsLoaded).level));
                                    setDialogState(() => rewardsDoubled = true);
                                  },
                                  onDismissed: () {},
                                );
                              },
                            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds, color: Colors.white.withValues(alpha: 0.4)),
                          ] else
                            Container(
                              width: double.infinity,
                              height: 54.h,
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(30.r),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.4), width: 3.w),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: Colors.green, size: 24.sp),
                                    SizedBox(width: 8.w),
                                    Text(
                                      "REWARDS TRIPLED!",
                                      style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w900, color: Colors.green, fontSize: 16.sp),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().scale(curve: Curves.easeOutBack),
                            
                          SizedBox(height: 16.h),
                          
                          Kids3DButton(
                            text: context.tr('common.continue_text', fallback: 'Continue'),
                            color: primaryColor,
                            onTap: () {
                              adService.recordLevelCompletion();
                              authBloc.add(const AuthRefreshUser());
                              navigator.pop();
                              navigator.pop();
                            },
                          ),
                        ],
                      ),
                    ),
                  ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                ),
                const Positioned.fill(child: IgnorePointer(child: GameConfetti(shouldPop: false))),
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
    final adService = di.sl<AdService>();
    final kidsBloc = context.read<KidsBloc>();
    final navigator = Navigator.of(context);
    final user = context.read<AuthBloc>().state.user;
    final isPremium = user?.isPremium ?? false;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: KidsDialogContainer(
              primaryColor: const Color(0xFF6366F1), // Moody purple/indigo
              title: context.tr('games.kids_game_over', fallback: 'Game Over'),
              ribbonColor: Colors.redAccent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(24.r),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.redAccent.withValues(alpha: 0.2), blurRadius: 20),
                      ],
                    ),
                    child: Icon(Icons.heart_broken_rounded, color: Colors.redAccent, size: 60.sp),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1), duration: 1.seconds),
                  
                  SizedBox(height: 16.h),
                  Text(
                    context.tr('games.kids_game_over_subtitle', fallback: 'Great effort!'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 16.sp, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w700),
                  ),
                  
                  SizedBox(height: 32.h),
                  
                  Kids3DButton(
                    text: context.tr('games.kids_resume_game', fallback: 'Resume Game'),
                    color: const Color(0xFF10B981), // Bright neon green for Revive
                    icon: Icons.play_circle_fill_rounded,
                    onTap: () {
                      adService.showRewardedAd(
                        context: context,
                        isPremium: isPremium,
                        childSafe: true,
                        onUserEarnedReward: (_) {
                          kidsBloc.add(RestoreKidsLife());
                          navigator.pop();
                        },
                        onDismissed: () {},
                      );
                    },
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  Kids3DButton(
                    text: context.tr('games.kids_exit_to_map', fallback: 'Exit to Map'),
                    color: Colors.grey.shade600,
                    onTap: () {
                      navigator.pop();
                      navigator.pop();
                    },
                  ),
                ],
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          ),
        ),
      ),
    );
  }

  static Future<bool> showExitConfirmation({
    required BuildContext context,
    required Color primaryColor,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<bool?>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(40.r),
              border: Border.all(
                color: const Color(0xFF8B5CF6),
                width: 8.w,
              ), // Playful purple
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6D28D9),
                  offset: Offset(0, 12.h),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
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
                    context.tr('games.kids_quit_title', fallback: 'Quit Game?'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w900,
                      fontSize: 20.sp,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),

                  SizedBox(height: 12.h),

                  Text(
                    context.tr(
                      'games.kids_quit_subtitle',
                      fallback: 'Are you sure you want to quit?',
                    ),
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
                            height: 52.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30.r),
                              border: Border.all(
                                color: Colors.grey[400]!,
                                width: 4.w,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey[400]!,
                                  offset: Offset(0, 5.h),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                context
                                    .tr('games.kids_quit_button')
                                    .toUpperCase(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w900,
                                  color: Colors.grey[600],
                                  fontSize: 14.sp,
                                  letterSpacing: 1,
                                ),
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
                            height: 52.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30.r),
                              border: Border.all(
                                color: const Color(0xFF6D28D9),
                                width: 4.w,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6D28D9),
                                  offset: Offset(0, 5.h),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                context
                                    .tr(
                                      'games.kids_play_on',
                                      fallback: 'Play On',
                                    )
                                    .toUpperCase(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF8B5CF6),
                                  fontSize: 14.sp,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
      ),
    );
    return result ?? false;
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
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3.w),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Text(emoji, style: TextStyle(fontSize: 24.sp)),
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
