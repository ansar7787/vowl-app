import 'package:vowl/core/theme/app_colors.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
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
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
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
                              : Icons.center_focus_strong_rounded,
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
                                fontWeight: FontWeight.w700,
                                color: textColor,
                                height: 1.25,
                              ),
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              bountyFound
                                  ? context.tr(
                                      'vocabulary.bounty_completed',
                                      fallback: 'Object found! +5 XP & 10 Coins earned 🎉',
                                    )
                                  : context.tr(
                                      'vocabulary.find_bounty_desc',
                                      fallback:
                                          'Find this object to earn +5 XP & 10 Coins',
                                    ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
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

                      // Interactive Info Button
                      SizedBox(width: 6.w),
                      Semantics(
                        label: 'How object bounties work',
                        button: true,
                        child: ScaleButton(
                          onTap: () => _showBountyInfo(context),
                          child: Container(
                            padding: EdgeInsets.all(7.r),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: 0.1),
                                width: 1.w,
                              ),
                            ),
                            child: Icon(
                              Icons.info_outline_rounded,
                              size: 16.r,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
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

  void _showBountyInfo(BuildContext context) {
    try {
      di.sl<HapticService>().selection();
      di.sl<SoundService>().playClick();
    } catch (_) {}

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => _BountyInfoDialog(
        title: context.tr(
          'vocabulary.bounty_how_to_play',
          fallback: 'HOW OBJECT BOUNTIES WORK',
        ),
        accentColor: AppColors.teal500,
        icon: Icons.camera_alt_rounded,
        steps: [
          _BountyInfoStep(
            icon: Icons.track_changes_rounded,
            title: context.tr('vocabulary.info_step1_title', fallback: 'Hunt the Object'),
            description: context.tr(
              'vocabulary.info_step1_desc',
              fallback: 'Look around your room or outside for real-world items matching the target.',
            ),
          ),
          _BountyInfoStep(
            icon: Icons.photo_camera_rounded,
            title: context.tr('vocabulary.info_step2_title', fallback: 'Take a Clear Photo'),
            description: context.tr(
              'vocabulary.info_step2_desc',
              fallback: 'Point your camera directly at the object with good lighting, or choose from gallery.',
            ),
          ),
          _BountyInfoStep(
            icon: Icons.stars_rounded,
            title: context.tr('vocabulary.info_step3_title', fallback: 'Earn Daily Rewards'),
            description: context.tr(
              'vocabulary.info_step3_desc',
              fallback: 'Earn +5 XP and 10 Coins per detected bounty! You can collect rewards for up to 3 objects each day.',
            ),
          ),
          _BountyInfoStep(
            icon: LucideIcons.shuffle,
            title: context.tr('vocabulary.info_step4_title', fallback: 'Skip Anytime'),
            description: context.tr(
              'vocabulary.info_step4_desc',
              fallback: 'Don\'t have the object near you? Tap the shuffle button (🔀) to get a new target.',
            ),
          ),
        ],
      ),
    );
  }
}

class _BountyInfoStep {
  final IconData icon;
  final String title;
  final String description;

  const _BountyInfoStep({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _BountyInfoDialog extends StatelessWidget {
  final String title;
  final Color accentColor;
  final IconData icon;
  final List<_BountyInfoStep> steps;

  const _BountyInfoDialog({
    required this.title,
    required this.accentColor,
    required this.icon,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.all(22.r),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.82)
                  : Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.35),
                width: 1.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Row with Centered Icon & Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(width: 32.r),
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.4),
                            width: 1.5.w,
                          ),
                        ),
                        child: Icon(icon, color: accentColor, size: 28.r),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 22.r,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        onPressed: () {
                          try {
                            di.sl<HapticService>().light();
                          } catch (_) {}
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),

                  // Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 18.h),

                  // Steps List
                  ...steps.map((step) => Padding(
                        padding: EdgeInsets.only(bottom: 14.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Icon(
                                step.icon,
                                color: accentColor,
                                size: 18.r,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.title,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    step.description,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),

                  SizedBox(height: 8.h),

                  // Dismiss Button
                  ScaleButton(
                    onTap: () {
                      try {
                        di.sl<HapticService>().light();
                        di.sl<SoundService>().playClick();
                      } catch (_) {}
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        context.tr('common.got_it', fallback: 'GOT IT!'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

