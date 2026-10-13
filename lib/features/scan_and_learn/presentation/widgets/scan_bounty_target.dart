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
    final primaryIndigo = AppColors.indigo500;
    final dictionaryEntry = ScanVocabularyDictionary.getEntry(currentBounty);

    final unfoundBgColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);
    final unfoundBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.15);

    final foundBgColor = isDark
        ? primaryIndigo.withValues(alpha: 0.3)
        : primaryIndigo.withValues(alpha: 0.15);
    final foundBorderColor = isDark
        ? _LocalPalette.color818cf8
        : primaryIndigo;

    final progressCount = dailyCount.clamp(0, 3);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: bountyFound ? foundBgColor : unfoundBgColor,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: bountyFound ? foundBorderColor : unfoundBorderColor,
                width: 1.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryIndigo.withValues(alpha: bountyFound ? 0.2 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Category Pill & Daily Stars Progress
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: primaryIndigo.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: primaryIndigo.withValues(alpha: 0.35),
                            width: 1.w,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.signpost_rounded,
                              size: 11.r,
                              color: isDark ? _LocalPalette.color818cf8 : primaryIndigo,
                            ),
                            SizedBox(width: 4.w),
                            Flexible(
                              child: Text(
                                dictionaryEntry.signCategory.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: isDark ? _LocalPalette.color818cf8 : primaryIndigo,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Daily 3-Star Goal Indicator
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (index) {
                        final completed = index < progressCount;
                        return Padding(
                          padding: EdgeInsets.only(left: 3.w),
                          child: Icon(
                            completed ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 15.r,
                            color: completed
                                ? (isDark ? Colors.amber.shade300 : AppColors.amber500)
                                : (isDark ? Colors.white30 : Colors.black26),
                          ),
                        );
                      }),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '$progressCount/3',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: progressCount >= 3
                            ? (isDark ? Colors.amber.shade300 : AppColors.amber500)
                            : (isDark ? Colors.white60 : Colors.black54),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),

                // Main Content Row: Sign Icon, Word with No Ellipsis, Shuffle & Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: bountyFound
                            ? primaryIndigo.withValues(alpha: 0.25)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        bountyFound
                            ? Icons.verified_rounded
                            : Icons.document_scanner_rounded,
                        color: bountyFound
                            ? primaryIndigo
                            : (isDark ? Colors.amber.shade400 : Colors.amber.shade600),
                        size: 22.r,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  context.tr(
                                    'translation.scan_word',
                                    args: [currentBounty],
                                    fallback: 'Scan Sign: "$currentBounty"',
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            bountyFound
                                ? context.tr('vocabulary.bounty_completed', fallback: 'Sign found! Reward unlocked 🎉')
                                : dictionaryEntry.meaning,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black54,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Interactive Target Shuffle Button
                    if (!bountyFound && onShuffle != null) ...[
                      SizedBox(width: 6.w),
                      Semantics(
                        label: 'Change target sign word',
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
                                width: 1.w,
                              ),
                            ),
                            child: Icon(
                              LucideIcons.shuffle,
                              size: 16.r,
                              color: isDark ? _LocalPalette.color818cf8 : primaryIndigo,
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Interactive Info Button
                    SizedBox(width: 6.w),
                    Semantics(
                      label: 'How sign bounties work',
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
              fallback: 'Can\'t find this sign right now? Tap the shuffle button (🔀) to hunt for a different word.',
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
