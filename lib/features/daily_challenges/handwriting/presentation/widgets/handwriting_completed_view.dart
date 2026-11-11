import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/daily_challenges/handwriting/domain/models/handwriting_puzzle.dart';
import 'package:vowl/features/daily_challenges/handwriting/presentation/widgets/handwriting_top_bar.dart';

/// Screen view displayed when today's Handwriting challenge has been completed.
class HandwritingCompletedView extends StatelessWidget {
  final HandwritingPuzzle? puzzle;
  final int streak;
  final Color primaryColor;
  final HapticService hapticService;
  final VoidCallback onPracticeAgain;
  final bool isPracticeMode;

  const HandwritingCompletedView({
    super.key,
    required this.puzzle,
    required this.streak,
    required this.primaryColor,
    required this.hapticService,
    required this.onPracticeAgain,
    this.isPracticeMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final target = puzzle?.target ?? '';
    final instruction = puzzle?.instruction ?? '';
    final explanation = puzzle?.explanation ?? '';
    final funFact = puzzle?.funFact ?? '';

    return Column(
      children: [
        HandwritingTopBar(streak: streak, isPracticeMode: isPracticeMode),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 16.h,
            ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 24.h),
            child: Column(
              children: [
                SizedBox(height: 12.h),

                // Success icon badge
                Container(
                  padding: EdgeInsets.all(22.r),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.teal500, Color(0xFF0F766E)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal500.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 38.r,
                  ),
                ),
                SizedBox(height: 20.h),

                // Title
                Text(
                  isPracticeMode
                      ? context.tr(
                          'vocabulary.practice_complete',
                          fallback: 'Practice Complete!',
                        )
                      : context.tr(
                          'home.already_completed_title',
                          fallback: 'Challenge Complete!',
                        ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  isPracticeMode
                      ? context.tr(
                          'daily_challenges.practice_done_desc',
                          fallback: 'Great stroke practice! Ready for more?',
                        )
                      : context.tr(
                          'daily_challenges.completed_desc',
                          fallback: 'You solved today\'s daily challenge!',
                        ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                SizedBox(height: 24.h),

                // Word / Target card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : AppColors.slate200,
                      width: 1.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.2 : 0.04,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Target symbol/word display
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.teal500.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Text(
                          target,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.teal500,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                      if (instruction.isNotEmpty) ...[
                        SizedBox(height: 14.h),
                        Text(
                          instruction,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.8,
                            ),
                            height: 1.4,
                          ),
                        ),
                      ],
                      if (explanation.isNotEmpty) ...[
                        SizedBox(height: 12.h),
                        Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : AppColors.slate50,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                LucideIcons.info,
                                size: 16.r,
                                color: AppColors.teal500,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  explanation,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13.sp,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.75),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (funFact.isNotEmpty) ...[
                        SizedBox(height: 10.h),
                        Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: AppColors.amber500.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('💡', style: TextStyle(fontSize: 14.sp)),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  funFact,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.sp,
                                    fontStyle: FontStyle.italic,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.75),
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
                SizedBox(height: 28.h),

                // Action buttons
                ScaleButton(
                  onTap: () {
                    try {
                      hapticService.selection();
                    } catch (_) {}
                    onPracticeAgain();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.teal500, Color(0xFF0F766E)],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.teal500.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.repeat,
                            color: Colors.white,
                            size: 18.r,
                          ),
                          SizedBox(width: 8.w),
                          Flexible(
                            child: Text(
                              context.tr(
                                'daily_challenges.practice_another',
                                fallback: 'Practice Another Word',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),

                // Done button
                ScaleButton(
                  onTap: () {
                    try {
                      hapticService.light();
                    } catch (_) {}
                    context.pop();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.slate100,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Center(
                      child: Text(
                        context.tr('common.done', fallback: 'Done'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
