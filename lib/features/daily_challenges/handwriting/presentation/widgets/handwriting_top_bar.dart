import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';

/// Modern top navigation bar for the Handwriting daily challenge.
///
/// Designed cleanly with NO bulky progress bars or overwhelming question banners,
/// providing direct focus on the chalkboard slate.
class HandwritingTopBar extends StatelessWidget {
  final int streak;
  final bool isPracticeMode;
  final VoidCallback? onBackPressed;
  final VoidCallback? onInfoTap;

  const HandwritingTopBar({
    super.key,
    required this.streak,
    this.isPracticeMode = false,
    this.onBackPressed,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final backIcon = isRtl
        ? Icons.arrow_forward_ios_rounded
        : Icons.arrow_back_ios_new_rounded;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          // Tactile back button
          Semantics(
            label: context.tr('common.back', fallback: 'Back'),
            button: true,
            child: ScaleButton(
              onTap: () {
                try {
                  di.sl<HapticService>().light();
                } catch (_) {}
                if (onBackPressed != null) {
                  onBackPressed!();
                } else {
                  context.pop();
                }
              },
              child: Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : AppColors.slate200,
                    width: 1.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.04,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: isRtl ? 0 : 2.w,
                      left: isRtl ? 2.w : 0,
                    ),
                    child: Icon(
                      backIcon,
                      color: theme.colorScheme.onSurface,
                      size: 18.r,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Title
          Expanded(
            child: Text(
              context.tr('home.tools_handwriting', fallback: 'Handwriting'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
          ),

          // Right pill (Practice mode or Streak)
          if (isPracticeMode)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.teal500.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: AppColors.teal500.withValues(alpha: 0.4),
                  width: 1.w,
                ),
              ),
              child: Text(
                context.tr('daily_challenges.practice', fallback: 'PRACTICE'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teal500,
                  letterSpacing: 0.5,
                ),
              ),
            )
          else if (streak > 0)
            Semantics(
              label: '$streak day streak',
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.amber500, AppColors.red500],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.amber500.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 12.sp)),
                    SizedBox(width: 4.w),
                    Text(
                      '$streak',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(width: 44.r),
        ],
      ),
    );
  }
}
