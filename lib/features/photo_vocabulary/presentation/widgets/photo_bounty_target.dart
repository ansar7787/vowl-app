import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/photo_vocabulary/utils/photo_vocabulary_dictionary.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color2dd4bf = Color(0xFF2DD4BF);
  static const Color color0d9488 = Color(0xFF0D9488);
}

/// Target bounty objective card displaying the object to find via photo recognition.
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
    final dictionaryEntry = PhotoVocabularyDictionary.getEntry(currentBounty);

    final progressCount = dailyLimit > 0 ? dailyCount.clamp(0, dailyLimit) : dailyCount;

    final cardBgGradient = bountyFound
        ? LinearGradient(
            colors: isDark
                ? [
                    AppColors.teal500.withValues(alpha: 0.2),
                    const Color(0xFF064E3B).withValues(alpha: 0.35),
                  ]
                : [
                    const Color(0xFFF0FDF4),
                    const Color(0xFFDCFCE7).withValues(alpha: 0.7),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF042F2E).withValues(alpha: 0.45),
                    const Color(0xFF0F172A).withValues(alpha: 0.78),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFF8FAFC),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final cardBorderColor = bountyFound
        ? AppColors.emerald500.withValues(alpha: isDark ? 0.55 : 0.4)
        : (isDark
            ? Colors.white.withValues(alpha: 0.12)
            : AppColors.teal500.withValues(alpha: 0.2));

    final semanticMessage = bountyFound
        ? 'Daily Bounty found! Target: $currentBounty.'
        : 'Daily Bounty target: $currentBounty. Find this object to earn bonus XP and coins. Daily completed: $dailyCount of $dailyLimit.';

    return Semantics(
      label: semanticMessage,
      container: true,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: EdgeInsets.all(18.r),
              decoration: BoxDecoration(
                gradient: cardBgGradient,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: cardBorderColor,
                  width: 1.5.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (bountyFound ? AppColors.emerald500 : AppColors.teal500)
                        .withValues(alpha: isDark ? 0.22 : 0.07),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Top Header Row: Category Badge + Daily Goal Pill ────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Category / Bounty Tag (Never ellipsized)
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.5.h),
                          decoration: BoxDecoration(
                            color: bountyFound
                                ? AppColors.emerald500.withValues(alpha: 0.15)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : AppColors.teal500.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: bountyFound
                                  ? AppColors.emerald500.withValues(alpha: 0.3)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : AppColors.teal500.withValues(alpha: 0.2)),
                              width: 1.w,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                bountyFound
                                    ? Icons.verified_rounded
                                    : Icons.photo_camera_rounded,
                                size: 13.r,
                                color: bountyFound
                                    ? AppColors.emerald500
                                    : (isDark ? _LocalPalette.color2dd4bf : _LocalPalette.color0d9488),
                              ),
                              SizedBox(width: 5.w),
                              Flexible(
                                child: Text(
                                  dictionaryEntry.cefr != null && dictionaryEntry.cefr!.isNotEmpty
                                      ? 'OBJECT HUNT • ${dictionaryEntry.cefr}'
                                      : 'DAILY OBJECT HUNT',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                    color: bountyFound
                                        ? AppColors.emerald500
                                        : (isDark ? _LocalPalette.color2dd4bf : _LocalPalette.color0d9488),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(width: 8.w),

                      // Daily Goal Indicator Pill: "Today: $dailyCount/$dailyLimit found"
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.25)
                              : AppColors.slate100,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : AppColors.slate200,
                            width: 1.w,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(dailyLimit.clamp(1, 5), (index) {
                                final completed = index < progressCount;
                                return Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 1.w),
                                  child: Icon(
                                    completed ? Icons.star_rounded : Icons.star_outline_rounded,
                                    size: 13.r,
                                    color: completed
                                        ? (isDark ? Colors.amber.shade300 : AppColors.amber500)
                                        : (isDark ? Colors.white30 : AppColors.slate300),
                                  ),
                                );
                              }),
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              context.tr(
                                'vocabulary.daily_progress',
                                args: ['$dailyCount', '$dailyLimit'],
                                fallback: 'Today: $dailyCount/$dailyLimit found',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w800,
                                color: progressCount >= dailyLimit
                                    ? (isDark ? Colors.amber.shade300 : AppColors.amber500)
                                    : (isDark ? Colors.white70 : AppColors.slate600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 14.h),

                  // ── 2. Hero Target Object Row ──────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Object Plaque Icon Container
                      Container(
                        width: 44.r,
                        height: 44.r,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: bountyFound
                                ? [AppColors.emerald500, const Color(0xFF059669)]
                                : (isDark
                                    ? [AppColors.teal500, const Color(0xFF0F766E)]
                                    : [const Color(0xFF14B8A6), _LocalPalette.color0d9488]),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [
                            BoxShadow(
                              color: (bountyFound ? AppColors.emerald500 : AppColors.teal500)
                                  .withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            bountyFound
                                ? Icons.task_alt_rounded
                                : Icons.center_focus_strong_rounded,
                            color: Colors.white,
                            size: 22.r,
                          ),
                        ),
                      ),

                      SizedBox(width: 12.w),

                      // Target Object Text & Description (Never truncated, full text display)
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
                                fontSize: 16.5.sp,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                height: 1.25,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              bountyFound
                                  ? context.tr(
                                      'vocabulary.photo_bounty_completed',
                                      fallback: 'Object found! +5 XP & 10 Coins earned',
                                    )
                                  : (dictionaryEntry.definition.isNotEmpty
                                      ? dictionaryEntry.definition
                                      : context.tr(
                                          'vocabulary.find_bounty_desc',
                                          fallback: 'Find this object to earn +5 XP & 10 Coins',
                                        )),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: bountyFound
                                    ? (isDark ? AppColors.emerald400 : AppColors.emerald600)
                                    : (isDark ? Colors.white70 : AppColors.slate600),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 8.w),

                      // Symmetrical Action Buttons (Shuffle + Info)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!bountyFound && onShuffle != null) ...[
                            Semantics(
                              label: 'Shuffle bounty target',
                              button: true,
                              child: ScaleButton(
                                onTap: onShuffle,
                                child: Container(
                                  width: 36.r,
                                  height: 36.r,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(11.r),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.12)
                                          : AppColors.slate200,
                                      width: 1.w,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    LucideIcons.shuffle,
                                    size: 16.r,
                                    color: isDark ? _LocalPalette.color2dd4bf : _LocalPalette.color0d9488,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 6.w),
                          ],

                          Semantics(
                            label: 'How object bounties work',
                            button: true,
                            child: ScaleButton(
                              onTap: () => _showBountyInfo(context),
                              child: Container(
                                width: 36.r,
                                height: 36.r,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(11.r),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : AppColors.slate200,
                                    width: 1.w,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.info_outline_rounded,
                                  size: 17.r,
                                  color: isDark ? Colors.white70 : AppColors.slate600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // ── 3. Educational Context Tip (Clue / Example, Never ellipsized) ──
                  if (!bountyFound && (dictionaryEntry.example.isNotEmpty || dictionaryEntry.grammarTip.isNotEmpty)) ...[
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : AppColors.teal500.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : AppColors.teal500.withValues(alpha: 0.1),
                          width: 1.w,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 1.5.h),
                            child: Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 14.r,
                              color: isDark ? Colors.amber.shade300 : AppColors.amber600,
                            ),
                          ),
                          SizedBox(width: 7.w),
                          Expanded(
                            child: Text(
                              dictionaryEntry.example.isNotEmpty
                                  ? 'Example: "${dictionaryEntry.example}"'
                                  : dictionaryEntry.grammarTip,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white60 : AppColors.slate600,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── 4. Sleek Progress Indicator Bar ───────────────────────
                  if (dailyLimit > 0) ...[
                    SizedBox(height: 10.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: LinearProgressIndicator(
                        value: (dailyCount / dailyLimit).clamp(0.0, 1.0),
                        minHeight: 4.h,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : AppColors.teal500.withValues(alpha: 0.08),
                        color: dailyCount >= dailyLimit
                            ? AppColors.emerald500
                            : AppColors.teal500,
                      ),
                    ),
                  ],
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
              fallback: 'Don\'t have the object near you? Tap the shuffle button to get a new target.',
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

