import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:vowl/core/utils/age_gate_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';

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

    if (!isAdult) {
      final confirm = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) {
          final isDarkSheet = Theme.of(ctx).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: isDarkSheet ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            padding: EdgeInsets.fromLTRB(
              24.w,
              12.h,
              24.w,
              32.h + MediaQuery.of(ctx).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDarkSheet ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 24.h),
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber,
                    size: 32.r,
                    semanticLabel: 'Warning',
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  context.tr(
                    'age_gate.confirm_kid_title',
                    fallback: 'Wait, Are You Sure?',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  context.tr(
                    'age_gate.confirm_kid_desc',
                    fallback:
                        'By selecting this, advanced courses, speaking practice, and grammar features will be hidden to keep the app safe for kids.',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    color: isDarkSheet ? Colors.white70 : Colors.black54,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            context.tr(
                              'age_gate.oops_adult',
                              fallback: "Oops, I'm an Adult",
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: isDarkSheet
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            context.tr(
                              'age_gate.yes_kid',
                              fallback: "Yes, I'm a Kid",
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

      if (confirm == null) return; // User dismissed by swiping down
      if (!confirm) {
        if (!context.mounted) return;
        return _handleSelection(context, isAdult: true);
      }
    }

    await AgeGateService.completeAgeGate(isAdult: isAdult);

    try {
      di.sl<AdService>().refreshAdConfig();
    } catch (_) {
      // Ignored if AdService is not yet registered
    }

    if (!context.mounted) return;

    if (isAdult) {
      CustomSnackBar.show(
        context: context,
        message: context.tr(
          'age_gate.adult_welcome_toast',
          fallback:
              '🎉 Full Experience Unlocked! You have access to all courses and the Kids Zone. You can switch modes anytime in Settings.',
        ),
        type: CustomSnackBarType.success,
      );
    }

    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark
            ? const Color(0xFF0F172A)
            : Colors.white,
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 32.w,
                            vertical: 24.h,
                          ),
                          child: Column(
                            children: [
                              const Spacer(flex: 2),

                              // Icon
                              Semantics(
                                label: 'Shield Icon',
                                image: true,
                                child:
                                    Container(
                                          width: 80.r,
                                          height: 80.r,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF6366F1),
                                                Color(0xFF8B5CF6),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              24.r,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF6366F1,
                                                ).withValues(alpha: 0.3),
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
                              ),

                              SizedBox(height: 32.h),

                              // Title
                              Semantics(
                                header: true,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    context.tr(
                                      'age_gate.title',
                                      fallback: 'Before we begin',
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 28.sp,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                      letterSpacing: -0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ).animate().fadeIn(delay: 200.ms),
                                ),
                              ),

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
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ).animate().fadeIn(delay: 400.ms),

                              const Spacer(flex: 1),

                              // "I'm 16 or older" button
                              Semantics(
                                button: true,
                                label: context.tr(
                                  'age_gate.adult_button',
                                  fallback: "I'm 16 or older",
                                ),
                                hint: context.tr(
                                  'age_gate.adult_subtitle',
                                  fallback:
                                      "Access the full learning experience",
                                ),
                                excludeSemantics: true,
                                child:
                                    ScaleButton(
                                          onTap: () => _handleSelection(
                                            context,
                                            isAdult: true,
                                          ),
                                          child: Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.symmetric(
                                              vertical: 18.h,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF6366F1),
                                                  Color(0xFF8B5CF6),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16.r),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF6366F1,
                                                  ).withValues(alpha: 0.3),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            alignment: Alignment.center,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    context.tr(
                                                      'age_gate.adult_button',
                                                      fallback:
                                                          "I'm 16 or older",
                                                    ),
                                                    style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      fontSize: 17.sp,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: Colors.white,
                                                      letterSpacing: 0.3,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 2.h),
                                                Text(
                                                  context.tr(
                                                    'age_gate.adult_subtitle',
                                                    fallback:
                                                        "Access the full learning experience",
                                                  ),
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white
                                                        .withValues(alpha: 0.8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .animate()
                                        .fadeIn(delay: 600.ms)
                                        .moveY(begin: 20, end: 0),
                              ),

                              SizedBox(height: 16.h),

                              // "I'm under 16" button
                              Semantics(
                                button: true,
                                label: context.tr(
                                  'age_gate.child_button',
                                  fallback: "I'm under 16",
                                ),
                                hint: context.tr(
                                  'age_gate.child_subtitle',
                                  fallback: "Fun, simplified games for kids",
                                ),
                                excludeSemantics: true,
                                child:
                                    ScaleButton(
                                          onTap: () => _handleSelection(
                                            context,
                                            isAdult: false,
                                          ),
                                          child: Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.symmetric(
                                              vertical: 18.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF1E293B)
                                                  : const Color(0xFFF1F5F9),
                                              borderRadius:
                                                  BorderRadius.circular(16.r),
                                              border: Border.all(
                                                color: isDark
                                                    ? Colors.white.withValues(
                                                        alpha: 0.1,
                                                      )
                                                    : const Color(0xFFE2E8F0),
                                                width: 1.5,
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    context.tr(
                                                      'age_gate.child_button',
                                                      fallback: "I'm under 16",
                                                    ),
                                                    style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      fontSize: 17.sp,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: isDark
                                                          ? Colors.white70
                                                          : Colors
                                                                .grey
                                                                .shade700,
                                                      letterSpacing: 0.3,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 2.h),
                                                Text(
                                                  context.tr(
                                                    'age_gate.child_subtitle',
                                                    fallback:
                                                        "Fun, simplified games for kids",
                                                  ),
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.w500,
                                                    color: isDark
                                                        ? Colors.white54
                                                        : Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .animate()
                                        .fadeIn(delay: 700.ms)
                                        .moveY(begin: 20, end: 0),
                              ),

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
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
