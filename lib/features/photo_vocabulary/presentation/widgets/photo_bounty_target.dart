import 'package:vowl/core/theme/app_colors.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:lucide_icons/lucide_icons.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color2dd4bf = Color(0xFF2DD4BF);
}

class PhotoBountyTarget extends StatelessWidget {
  final String currentBounty;
  final bool bountyFound;
  final int dailyCount;
  final int dailyLimit;
  final VoidCallback? onShuffle;

  const PhotoBountyTarget({
    super.key,
    required this.currentBounty,
    required this.bountyFound,
    this.dailyCount = 0,
    this.dailyLimit = 3,
    this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtitleColor = isDark
        ? Colors.amber.shade300
        : Colors.amber.shade700;

    final unfoundBgColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);
    final unfoundBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.15);

    final foundBgColor = isDark
        ? AppColors.teal500.withValues(alpha: 0.3)
        : AppColors.teal500.withValues(alpha: 0.15);
    final foundBorderColor = isDark
        ? _LocalPalette.color2dd4bf
        : AppColors.teal500;

    final semanticMessage = bountyFound
        ? 'Daily Bounty found! Target: $currentBounty.'
        : 'Daily Bounty target: $currentBounty. Find this object to earn bonus XP and coins. Daily completed: $dailyCount of $dailyLimit.';

    return Semantics(
      label: semanticMessage,
      container: true,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: bountyFound ? foundBgColor : unfoundBgColor,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: bountyFound ? foundBorderColor : unfoundBorderColor,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Target Icon / Verified Icon
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: bountyFound
                              ? AppColors.teal500.withValues(alpha: 0.2)
                              : (isDark
                                  ? Colors.amber.shade400.withValues(alpha: 0.15)
                                  : Colors.amber.shade600.withValues(alpha: 0.15)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          bountyFound
                              ? Icons.verified_rounded
                              : Icons.radar_rounded,
                          color: bountyFound
                              ? AppColors.teal500
                              : (isDark
                                  ? Colors.amber.shade400
                                  : Colors.amber.shade600),
                          size: 22.r,
                        ),
                      ),
                      SizedBox(width: 12.w),

                      // Title & Subtitle without ellipsis truncation
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr(
                                'vocabulary.daily_bounty',
                                args: [currentBounty],
                                fallback: 'Daily Bounty: $currentBounty',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                height: 1.25,
                              ),
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              bountyFound
                                  ? context.tr(
                                      'vocabulary.bounty_completed',
                                      fallback: 'Target verified! +5 XP earned',
                                    )
                                  : context.tr(
                                      'vocabulary.find_bounty_desc',
                                      fallback:
                                          'Find this object to earn +5 XP & 5 Coins',
                                    ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: bountyFound
                                    ? AppColors.teal500
                                    : subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Shuffle / Skip Button (only when uncompleted)
                      if (!bountyFound && onShuffle != null) ...[
                        SizedBox(width: 8.w),
                        Semantics(
                          label: 'Shuffle bounty target',
                          button: true,
                          child: ScaleButton(
                            onTap: onShuffle,
                            child: Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : Colors.black.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Icon(
                                LucideIcons.shuffle,
                                size: 16.r,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Info Tooltip
                      if (!bountyFound)
                        Tooltip(
                          message: context.tr(
                            'vocabulary.bounty_info',
                            fallback:
                                'Take a photo containing this object to earn bonus XP and Coins! A new object appears each time.',
                          ),
                          preferBelow: true,
                          child: Padding(
                            padding: EdgeInsets.only(left: 6.w),
                            child: Icon(
                              Icons.info_outline_rounded,
                              size: 18.r,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Daily Progress Indicator Bar
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Text(
                        context.tr(
                          'vocabulary.daily_progress',
                          args: ['$dailyCount', '$dailyLimit'],
                          fallback: 'Today: $dailyCount/$dailyLimit found',
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: LinearProgressIndicator(
                            value: dailyLimit > 0
                                ? (dailyCount / dailyLimit).clamp(0.0, 1.0)
                                : 0.0,
                            minHeight: 5.h,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.08),
                            color: dailyCount >= dailyLimit
                                ? AppColors.emerald500
                                : AppColors.teal500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
    .animate(target: bountyFound ? 1 : 0)
    .shimmer(
      duration: 1.seconds,
      color: isDark ? Colors.white54 : Colors.black12,
    );
  }
}
