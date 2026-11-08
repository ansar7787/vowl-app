import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/category_colors.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/profile/domain/models/trophy_metadata.dart';

/// Goal accelerator banner surfacing the nearest unearned achievement
/// with live percentage proximity, glowing jewel splash pod, and 1-tap practice routing.
class NextInReachRadar extends StatelessWidget {
  /// Badge ID of the closest locked achievement.
  final String badgeId;

  /// Calculated progress ratio (0.0 to 1.0).
  final double progress;

  /// Authenticated user entity.
  final UserEntity? user;

  const NextInReachRadar({
    super.key,
    required this.badgeId,
    required this.progress,
    this.user,
  });

  void _handleNavigate(BuildContext context, TrophyMetadata metadata) {
    Haptics.vibrate(HapticsType.medium);
    const validCategories = {
      'speaking',
      'listening',
      'reading',
      'writing',
      'grammar',
      'vocabulary',
      'accent',
      'roleplay',
      'elitemastery',
    };
    final cat = metadata.category.toLowerCase().trim();
    if (validCategories.contains(cat)) {
      context.push('${AppRouter.categoryGamesRoute}?category=$cat');
    } else {
      context.go(AppRouter.gamesRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final metadata = TrophyMetadata.forId(badgeId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final catColor = CategoryColors.forCategory(metadata.category);
    final darkVariant = CategoryColors.darkVariant(metadata.category);
    final percentage = (progress * 100).toInt();

    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark
              ? const Color(0xFF0F172A).withValues(alpha: 0.85)
              : Colors.white);

    final borderColor = isDark
        ? catColor.withValues(alpha: 0.35)
        : catColor.withValues(alpha: 0.20);

    return ScaleButton(
      onTap: () => _handleNavigate(context, metadata),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: catColor.withValues(alpha: isDark ? 0.15 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(
          children: [
            // 1. Glowing Category Jewel Splash Pod (Full bleed, big feel!)
            Container(
              width: 42.r,
              height: 42.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.2, -0.3),
                  radius: 0.85,
                  colors: [
                    catColor.withValues(alpha: isDark ? 0.85 : 0.95),
                    darkVariant.withValues(alpha: isDark ? 0.98 : 1.0),
                  ],
                ),
                border: Border.all(
                  color:
                      catColor, // SAME COLOR as background: gives the circle a large, full bleed feel!
                  width: 2.2.r,
                ),
                boxShadow: [
                  BoxShadow(
                    color: catColor.withValues(alpha: isDark ? 0.45 : 0.30),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Icon(metadata.icon, size: 19.r, color: Colors.white),
              ),
            ),
            SizedBox(width: 12.w),

            // 2. Info & Sleek Progress Bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6.r,
                              height: 6.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: catColor,
                              ),
                            ),
                            SizedBox(width: 5.w),
                            Flexible(
                              child: Text(
                                'NEXT TROPHY',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 8.5.sp,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.slate900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.slate900,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    metadata.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6.r),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.04, 1.0),
                      minHeight: 5.h,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.slate100,
                      valueColor: AlwaysStoppedAnimation<Color>(catColor),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 12.w),

            // 3. Tactile Brand Action Button with Play Icon (Not an Arrow!)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.indigo500,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.indigo500.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    size: 16.r,
                    color: Colors.white,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'PLAY',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
