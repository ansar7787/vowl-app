import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:vowl/core/utils/age_gate_service.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/ad_service.dart';

/// A one-time age verification screen shown before the user enters the app.
///
/// ### Design philosophy
/// - **Not annoying**: Shown exactly ONCE, never again.
/// - **Not spammy**: Clean, premium look that feels like part of the app.
/// - **Legally required**: Without this, ALL ads must be non-personalized
///   (COPPA safe-default), losing 40-60% ad revenue.
///
/// ### User flow
/// 1. First launch → splash → age gate → home
/// 2. All future launches → splash → home (age gate skipped)
class AgeGateScreen extends StatelessWidget {
  const AgeGateScreen({super.key});

  Future<void> _handleSelection(
    BuildContext context, {
    required bool isAdult,
  }) async {
    HapticFeedback.mediumImpact();
    await AgeGateService.completeAgeGate(isAdult: isAdult);
    
    try {
      di.sl<AdService>().refreshAdConfig();
    } catch (_) {
      // Ignored if AdService is not yet registered
    }

    if (!context.mounted) return;
    context.go(AppRouter.homeRoute);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor:
            isDark ? const Color(0xFF0F172A) : Colors.white,
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Icon
                Container(
                  width: 80.r,
                  height: 80.r,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6366F1),
                        const Color(0xFF8B5CF6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.verified_user_rounded,
                    size: 40.r,
                    color: Colors.white,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      curve: Curves.easeOutBack,
                    ),

                SizedBox(height: 32.h),

                // Title
                Text(
                  context.tr(
                    'age_gate.title',
                    fallback: 'Before we begin',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms),

                SizedBox(height: 12.h),

                // Subtitle
                Text(
                  context.tr(
                    'age_gate.subtitle',
                    fallback:
                        'We need to know your age to give you the best experience.',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 400.ms),

                const Spacer(flex: 1),

                // "I'm 16 or older" button
                ScaleButton(
                  onTap: () => _handleSelection(context, isAdult: true),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF6366F1).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      context.tr(
                        'age_gate.adult_button',
                        fallback: "I'm 16 or older",
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0),

                SizedBox(height: 16.h),

                // "I'm under 16" button
                ScaleButton(
                  onTap: () => _handleSelection(context, isAdult: false),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      context.tr(
                        'age_gate.child_button',
                        fallback: "I'm under 16",
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 700.ms).moveY(begin: 20, end: 0),

                SizedBox(height: 24.h),

                // Privacy note
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    context.tr(
                      'age_gate.privacy_note',
                      fallback:
                          'This is stored only on your device and is never shared. You can change this later in Settings.',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(delay: 800.ms),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
