import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class KidsGameDialogs {
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
            child: AlertDialog(
              backgroundColor: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32.r),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 2),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ICON HEADER
                  Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text("🏆", style: TextStyle(fontSize: 48.sp)),
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                  
                  SizedBox(height: 20.h),
                  Text("LEVEL UP!", style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: primaryColor, fontSize: 32.sp, letterSpacing: 2)),
                  SizedBox(height: 24.h),
                  
                  // REWARDS CARD
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildReward(state.coinsEarned * (rewardsDoubled ? 2 : 1), "🚗"),
                        SizedBox(width: 30.w),
                        _buildReward(state.xpEarned * (rewardsDoubled ? 2 : 1), "🌟"),
                      ],
                    ),
                  ),

                  if (state.stickerAwarded != null) ...[
                    SizedBox(height: 20.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15.r)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 18.sp),
                          SizedBox(width: 8.w),
                          Text("NEW STICKER UNLOCKED!", style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: Colors.amber, fontSize: 12.sp)),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 32.h),
                  
                  if (!rewardsDoubled)
                    ScaleButton(
                      onTap: () {
                        adService.showRewardedAd(
                          isPremium: isPremium,
                          onUserEarnedReward: (_) {
                            context.read<KidsBloc>().add(ClaimDoubleKidsRewards(
                              (context.read<KidsBloc>().state as KidsLoaded).gameType,
                              (context.read<KidsBloc>().state as KidsLoaded).level,
                            ));
                            setDialogState(() => rewardsDoubled = true);
                          },
                          onDismissed: () {},
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("DOUBLE REWARDS", style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16.sp)),
                              SizedBox(width: 8.w),
                              Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 20.sp),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.green, size: 20.sp),
                            SizedBox(width: 8.w),
                            Text("REWARDS DOUBLED!", style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.green, fontSize: 16.sp)),
                          ],
                        ),
                      ),
                    ).animate().scale(curve: Curves.easeOutBack),
                    
                  SizedBox(height: 12.h),
                  
                  ScaleButton(
                    onTap: () {
                      context.pop(); // Pop dialog
                      context.pop(); // Pop game screen to return to map
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [primaryColor, primaryColor.withValues(alpha: 0.8)]),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
                      ),
                      child: Text("CONTINUE", textAlign: TextAlign.center, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18.sp, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
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
          backgroundColor: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32.r),
            side: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Text("💔", style: TextStyle(fontSize: 48.sp)),
              ).animate().shake(duration: 600.ms),
              
              SizedBox(height: 20.h),
              Text("GAME OVER", style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.redAccent, fontSize: 32.sp)),
              SizedBox(height: 12.h),
              Text("Don't give up! You were so close! \u{1F4AA}", textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 16.sp, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w600)),
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
                    gradient: const LinearGradient(colors: [Colors.green, Color(0xFF10B981)]),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("RESUME GAME", style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18.sp)),
                        SizedBox(width: 8.w),
                        Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 24.sp),
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
                child: Text("EXIT TO MAP", style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w800, letterSpacing: 1))
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
          backgroundColor: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.r),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
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
                child: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 40.r),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              
              SizedBox(height: 20.h),
              
              Text(
                "Leaving so soon? 😢",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 22.sp,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              
              SizedBox(height: 12.h),
              
              Text(
                "Your progress in this level will be lost! Are you sure you want to quit?",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
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
                          "QUIT",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white60 : Colors.grey[600],
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
                            colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
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
                          "PLAY ON!",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
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
    ) ?? false;
  }

  static Widget _buildReward(int amount, String asset) {
    return Row(
      children: [
        Text(asset, style: TextStyle(fontSize: 26.sp)),
        SizedBox(width: 8.w),
        Text(amount.toString(), style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 24.sp)),
      ],
    );
  }
}
