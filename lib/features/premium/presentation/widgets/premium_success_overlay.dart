import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PremiumSuccessOverlay extends StatelessWidget {
  final VoidCallback onBeginAdventure;
  final String? transactionId;

  const PremiumSuccessOverlay({
    super.key,
    required this.onBeginAdventure,
    this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.all(32.r),
          margin: EdgeInsets.symmetric(horizontal: 24.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(32.r),
            border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                blurRadius: 50,
                spreadRadius: 10,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  liveRegion: true,
                  label: context.tr(
                    'premium.success_title',
                    fallback: 'Welcome to Premium!',
                  ),
                  child:
                      Container(
                            width: 90.r,
                            height: 90.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              LucideIcons.checkCircle2,
                              color: Colors.white,
                              size: 44.r,
                            ),
                          )
                          .animate()
                          .scale(duration: 600.ms, curve: Curves.elasticOut)
                          .shimmer(duration: 2.seconds, delay: 500.ms),
                ),
                SizedBox(height: 28.h),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    context.tr(
                      'premium.success_title',
                      fallback: 'Welcome to Premium!',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      height: 1.2,
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
                SizedBox(height: 12.h),
                Text(
                  context.tr(
                    'premium.success_subtitle',
                    fallback:
                        'Your upgrade was successful. All elite features are now unlocked.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                if (transactionId != null) ...[
                  SizedBox(height: 20.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          context.tr(
                            'premium.transaction_id_label',
                            fallback: 'TRANSACTION ID',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            color: Colors.white.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        SelectableText(
                          transactionId!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ],
                SizedBox(height: 32.h),
                Semantics(
                  button: true,
                  label: context.tr(
                    'premium.begin_adventure_button',
                    fallback: 'Begin Adventure',
                  ),
                  child: ScaleButton(
                    onTap: onBeginAdventure,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Text(
                        context
                            .tr(
                              'premium.begin_adventure_button',
                              fallback: 'Begin Adventure',
                            )
                            .toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: Colors.black87,
                          fontWeight: FontWeight.w900,
                          fontSize: 15.sp,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ),
      ),
    ).animate().fade().scale(
      begin: const Offset(0.95, 0.95),
      curve: Curves.easeOutBack,
      duration: 400.ms,
    );
  }
}
