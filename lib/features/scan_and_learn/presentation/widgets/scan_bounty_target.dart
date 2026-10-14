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
import 'package:vowl/features/scan_and_learn/utils/scan_vocabulary_dictionary.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color818cf8 = Color(0xFF818CF8);
}

class ScanBountyTarget extends StatelessWidget {
  final String currentBounty;
  final bool bountyFound;
  final int dailyCount;
  final VoidCallback? onShuffle;

  const ScanBountyTarget({
    super.key,
    required this.currentBounty,
    required this.bountyFound,
    this.dailyCount = 0,
    this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final dictionaryEntry = ScanVocabularyDictionary.getEntry(currentBounty);

    final progressCount = dailyCount.clamp(0, 3);

    final cardBgGradient = bountyFound
        ? LinearGradient(
            colors: isDark
                ? [
                    AppColors.emerald500.withValues(alpha: 0.2),
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
                    const Color(0xFF1E1B4B).withValues(alpha: 0.55),
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
            : AppColors.indigo500.withValues(alpha: 0.2));

    return Padding(
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
                  color: (bountyFound ? AppColors.emerald500 : AppColors.indigo500)
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
                // ── 1. Top Header Row: Category Badge + Star Tracker ─────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Full Category Badge (NEVER ELLIPSIZED)
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.5.h),
                        decoration: BoxDecoration(
                          color: bountyFound
                              ? AppColors.emerald500.withValues(alpha: 0.15)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : AppColors.indigo500.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: bountyFound
                                ? AppColors.emerald500.withValues(alpha: 0.3)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : AppColors.indigo500.withValues(alpha: 0.2)),
                            width: 1.w,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              bountyFound
                                  ? Icons.verified_rounded
                                  : Icons.signpost_rounded,
                              size: 13.r,
                              color: bountyFound
                                  ? AppColors.emerald500
                                  : (isDark ? _LocalPalette.color818cf8 : AppColors.indigo600),
                            ),
                            SizedBox(width: 5.w),
                            Flexible(
                              child: Text(
                                dictionaryEntry.signCategory,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                  color: bountyFound
                                      ? AppColors.emerald500
                                      : (isDark ? _LocalPalette.color818cf8 : AppColors.indigo600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: 10.w),

                    // Daily 3-Star Goal Indicator Pill
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
                            children: List.generate(3, (index) {
                              final completed = index < progressCount;
                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 1.w),
                                child: Icon(
                                  completed ? Icons.star_rounded : Icons.star_outline_rounded,
                                  size: 14.r,
                                  color: completed
                                      ? (isDark ? Colors.amber.shade300 : AppColors.amber500)
                                      : (isDark ? Colors.white30 : AppColors.slate300),
                                ),
                              );
                            }),
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            '$progressCount/3',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              color: progressCount >= 3
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

                // ── 2. Hero Word & Actions Row ───────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sign Plaque Icon Container
                    Container(
                      width: 44.r,
                      height: 44.r,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: bountyFound
                              ? [AppColors.emerald500, const Color(0xFF059669)]
                              : (isDark
                                  ? [AppColors.indigo500, const Color(0xFF4338CA)]
                                  : [const Color(0xFF6366F1), AppColors.indigo500]),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: (bountyFound ? AppColors.emerald500 : AppColors.indigo500)
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
                              : Icons.document_scanner_rounded,
                          color: Colors.white,
                          size: 22.r,
                        ),
                      ),
                    ),

                    SizedBox(width: 12.w),

                    // Target Sign Text (Never truncated, full text display)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(
                              'translation.scan_word',
                              args: [currentBounty],
                              fallback: 'Scan Sign: "$currentBounty"',
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            bountyFound
                                ? context.tr('vocabulary.scan_bounty_completed', fallback: 'Sign found! Reward unlocked')
                                : dictionaryEntry.meaning,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.5.sp,
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
                            label: 'Change target sign word',
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
                                  color: isDark ? _LocalPalette.color818cf8 : AppColors.indigo600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                        ],

                        Semantics(
                          label: 'How sign bounties work',
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

                // ── 3. Real-World Spotting Tip (Educational context) ──────────
                if (!bountyFound && dictionaryEntry.realWorldTip.isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : AppColors.indigo500.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : AppColors.indigo500.withValues(alpha: 0.1),
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
                            dictionaryEntry.realWorldTip,
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
              ],
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
      builder: (dialogCtx) => _ScanBountyInfoDialog(
        title: context.tr(
          'translation.bounty_how_to_play',
          fallback: 'HOW SIGN BOUNTIES WORK',
        ),
        accentColor: AppColors.indigo500,
        icon: Icons.document_scanner_rounded,
        steps: [
          _ScanBountyInfoStep(
            icon: Icons.signpost_rounded,
            title: context.tr('translation.info_step1_title', fallback: 'Spot the Sign'),
            description: context.tr(
              'translation.info_step1_desc',
              fallback: 'Find English printed signs, restaurant menus, packaging, or book pages with this word.',
            ),
          ),
          _ScanBountyInfoStep(
            icon: Icons.document_scanner_rounded,
            title: context.tr('translation.info_step2_title', fallback: 'Scan with OCR'),
            description: context.tr(
              'translation.info_step2_desc',
              fallback: 'Capture clear printed text. Our smart AI extracts and translates the words instantly.',
            ),
          ),
          _ScanBountyInfoStep(
            icon: Icons.stars_rounded,
            title: context.tr('translation.info_step3_title', fallback: 'Earn Daily Rewards'),
            description: context.tr(
              'translation.info_step3_desc',
              fallback: 'Earn +5 XP and 10 Coins when your target sign is detected! Collect up to 3 stars per day.',
            ),
          ),
          _ScanBountyInfoStep(
            icon: LucideIcons.shuffle,
            title: context.tr('translation.info_step4_title', fallback: 'Change Sign'),
            description: context.tr(
              'translation.info_step4_desc',
              fallback: 'Can\'t find this sign right now? Tap the shuffle button to hunt for a different word.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanBountyInfoStep {
  final IconData icon;
  final String title;
  final String description;

  const _ScanBountyInfoStep({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _ScanBountyInfoDialog extends StatelessWidget {
  final String title;
  final Color accentColor;
  final IconData icon;
  final List<_ScanBountyInfoStep> steps;

  const _ScanBountyInfoDialog({
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
