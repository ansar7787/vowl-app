import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// Progressive RPG milestone unlock card displayed to brand-new learners
/// (fewer than 2 total levels completed across the curriculum).
///
/// Eliminates the "Buffet Paradox" (decision paralysis) by gently guiding
/// Day 1 users to focus on their primary lesson card without overwhelming them
/// with 9 Bento Arena disciplines, 7 Tools, and 4 Discovery Decks all at once.
class BeginnerMilestoneCard extends StatelessWidget {
  /// Authenticated user entity.
  final UserEntity user;

  /// Optional callback triggered when an ambitious beginner chooses
  /// to bypass progressive disclosure and reveal all features immediately.
  final VoidCallback onUnlockNow;

  /// Creates a [BeginnerMilestoneCard].
  const BeginnerMilestoneCard({
    super.key,
    required this.user,
    required this.onUnlockNow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final cleared = user.totalLevelsCompleted.clamp(0, 2);
    final progress = (cleared / 2.0).clamp(0.05, 1.0);

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: isMidnight
              ? AppColors.midnightSurface
              : (isDark ? const Color(0xFF131A29) : Colors.white),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isMidnight
                ? Colors.white.withValues(alpha: 0.12)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.slate100),
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illuminated Lock/Trophy Emblem
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.indigo500.withValues(
                  alpha: isDark ? 0.16 : 0.10,
                ),
                border: Border.all(
                  color: AppColors.indigo500.withValues(
                    alpha: isDark ? 0.36 : 0.24,
                  ),
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: 20.r,
                  color: AppColors.indigo500,
                ),
              ),
            ),
            SizedBox(height: 10.h),

            // Milestone Title
            Text(
              context.tr(
                'home.arena_unlock_title',
                fallback: 'Skill Arena & Tools Unlock at Level 2',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.slate900,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: 4.h),

            // Milestone Description
            Text(
              context.tr(
                'home.arena_unlock_subtitle',
                fallback:
                    'Complete your first lesson above to unlock the 9-discipline Bento Arena and AI Tools Hub!',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.slate400 : AppColors.slate600,
                height: 1.35,
              ),
            ),
            SizedBox(height: 12.h),

            // Unlock Progress Bar
            Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 6.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppColors.slate200,
                          borderRadius: BorderRadius.circular(100.r),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 6.h,
                          decoration: BoxDecoration(
                            color: AppColors.indigo500,
                            borderRadius: BorderRadius.circular(100.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  '$cleared / 2',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.indigo500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),

            // Bypass Button for ambitious learners
            Semantics(
              button: true,
              label: context.tr(
                'home.show_all_features',
                fallback: 'Explore all features now',
              ),
              child: ScaleButton(
                onTap: () {
                  try {
                    di.sl<HapticService>().selection();
                  } catch (_) {}
                  onUnlockNow();
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  child: Text(
                    context.tr(
                      'home.show_all_features',
                      fallback: 'Explore all features now →',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.indigo500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
