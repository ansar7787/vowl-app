import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PremiumFailureOverlay extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onClose;
  final String? errorMessage;

  const PremiumFailureOverlay({
    super.key,
    required this.onRetry,
    required this.onClose,
    this.errorMessage,
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
              color: const Color(0xFFF43F5E).withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.15),
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
                  label: context.tr('premium.failure_title', fallback: 'Payment Failed'),
                  child: Container(
                    width: 90.r,
                    height: 90.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFB7185), Color(0xFFE11D48)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE11D48).withValues(alpha: 0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                    ),
                    child: Icon(
                      LucideIcons.alertTriangle,
                      color: Colors.white,
                      size: 44.r,
                    ),
                  )
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.elasticOut)
                  .shake(hz: 4, delay: 500.ms, duration: 400.ms),
                ),
                SizedBox(height: 28.h),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFB7185), Color(0xFFE11D48)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    context.tr('premium.failure_title', fallback: 'Payment Failed'),
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
                if (errorMessage != null && errorMessage!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: const Color(0xFFF43F5E).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          color: const Color(0xFFFB7185),
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                Text(
                  errorMessage == null
                      ? context.tr('premium.failure_body_default', fallback: 'We could not process your payment.')
                      : context.tr('premium.failure_body_retry_hint', fallback: 'Please check your connection and try again.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
                SizedBox(height: 32.h),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: context.tr('common.close', fallback: 'Close'),
                        child: ScaleButton(
                          onTap: onClose,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(24.r),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              context.tr('common.close', fallback: 'Close').toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13.sp,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      flex: 2,
                      child: Semantics(
                        button: true,
                        label: context.tr('premium.retry_button', fallback: 'Retry'),
                        child: ScaleButton(
                          onTap: onRetry,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFB7185), Color(0xFFE11D48)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24.r),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE11D48).withValues(alpha: 0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Text(
                              context.tr('premium.retry_button', fallback: 'Retry').toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14.sp,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ),
      ),
    ).animate().fade().scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack, duration: 400.ms);
  }
}
