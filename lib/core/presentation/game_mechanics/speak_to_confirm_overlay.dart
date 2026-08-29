import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/presentation/game_mechanics/speaking_self_evaluation_controls.dart';

/// A self-evaluation overlay for speaking tasks.
///
/// Uses [SpeakingSelfEvaluationControls] inside a floating bottom-sheet design.
class SpeakToConfirmOverlay extends StatelessWidget {
  final String expectedText;
  final String? displayText;
  final Color primaryColor;
  final VoidCallback onConfirmed;
  final VoidCallback onSkipped;
  final VoidCallback? onBypassed;
  final double threshold;
  final int maxAttempts;
  final int? bonusCoins;
  final bool allowSkip;
  final bool isPositioned;

  const SpeakToConfirmOverlay({
    super.key,
    required this.expectedText,
    this.displayText,
    required this.primaryColor,
    required this.onConfirmed,
    required this.onSkipped,
    this.onBypassed,
    this.threshold = 0.65,
    this.maxAttempts = 3,
    this.bonusCoins = 5,
    this.allowSkip = true,
    this.isPositioned = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white70 : Colors.black87;

    final content = Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          bottom: isPositioned ? MediaQuery.of(context).viewInsets.bottom + 24.h : 0,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 28.h),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(32.r),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : primaryColor.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ──
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(
                            Icons.mic_rounded,
                            color: primaryColor,
                            size: 22.r,
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.05, 1.05),
                          duration: 1.5.seconds,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NOW SAY IT',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w900,
                                  color: primaryColor,
                                  letterSpacing: 2,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Speak the answer to confirm',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (bonusCoins != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor,
                                  primaryColor.withValues(alpha: 0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '+$bonusCoins COINS',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // ── Expected text display ──
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 16.h,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        displayText ?? expectedText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    SpeakingSelfEvaluationControls(
                      expectedText: expectedText,
                      primaryColor: primaryColor,
                      onConfirmed: onConfirmed,
                      onSkipped: onSkipped,
                      isDark: isDark,
                    ),

                    // Skip button
                    if (allowSkip)
                      Padding(
                        padding: EdgeInsets.only(top: 16.h),
                        child: ScaleButton(
                          onTap: () {
                            final user = context.read<AuthBloc>().state.user;
                            final isPremium = user?.isPremium ?? false;
                            if (isPremium) {
                              if (onBypassed != null) {
                                onBypassed!();
                              } else {
                                onConfirmed();
                              }
                            } else {
                              di.sl<AdService>().showRewardedAd(
                                context: context,
                                isPremium: false,
                                onUserEarnedReward: (_) {
                                  if (context.mounted) {
                                    if (onBypassed != null) {
                                      onBypassed!();
                                    } else {
                                      onConfirmed();
                                    }
                                  }
                                },
                                onDismissed: () {},
                              );
                            }
                          },
                          child: Builder(
                            builder: (context) {
                              final isPremium =
                                  context.watch<AuthBloc>().state.user?.isPremium ??
                                  false;
                              return Text(
                                isPremium ? 'SKIP' : 'WATCH AD TO BYPASS',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: subtitleColor,
                                  letterSpacing: 1.5,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    )
    .animate()
    .slideY(
      begin: 0.2,
      end: 0,
      duration: 400.ms,
      curve: Curves.easeOut,
    )
    .fadeIn(duration: 300.ms);

    if (!isPositioned) {
      return content;
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: content,
    );
  }
}
