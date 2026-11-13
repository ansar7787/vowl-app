import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/daily_words/data/services/daily_words_service.dart';
import 'package:vowl/features/home/presentation/widgets/discovery_deck.dart';

/// Premium Daily Vocabulary Sprint Card.
///
/// Prominently featured right below [ContinueLearningCard] in the core daily habit flow.
/// Shows real-time daily status (pending vs completed) and navigates to [AppRouter.dailyWordsRoute].
class DailyWordsSprintCard extends StatefulWidget {
  const DailyWordsSprintCard({super.key});

  @override
  State<DailyWordsSprintCard> createState() => _DailyWordsSprintCardState();
}

class _DailyWordsSprintCardState extends State<DailyWordsSprintCard> {
  @override
  void initState() {
    super.initState();
    DiscoveryDeck.dailyCompletionNotifier.addListener(_onCompletionChanged);
  }

  void _onCompletionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DiscoveryDeck.dailyCompletionNotifier.removeListener(_onCompletionChanged);
    super.dispose();
  }

  void _handleTap() {
    try {
      di.sl<HapticService>().selection();
    } catch (_) {}
    context.push(AppRouter.dailyWordsRoute);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final bool isDone =
        di.sl.isRegistered<DailyWordsService>() &&
        di.sl<DailyWordsService>().isTodayCompleted;

    final tagText = isDone
        ? context.tr('home.tools_daily_completed', fallback: 'COMPLETED ✓')
        : context.tr('home.tools_daily_tag', fallback: 'TODAY');

    final titleText = context.tr(
      'home.tools_daily_words',
      fallback: 'Daily Words',
    );
    final subtitleText = isDone
        ? context.tr(
            'home.tools_daily_all_learned',
            fallback: 'All 10 words mastered today!',
          )
        : context.tr('home.tools_daily_desc', fallback: '10 new words today');

    return Semantics(
      button: true,
      label: '$titleText. $subtitleText',
      hint: context.tr(
        'home.daily_words_hint',
        fallback: 'Double tap to open Daily Words',
      ),
      child: ScaleButton(
        onTap: _handleTap,
        scaleDown: 0.98,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
          decoration: BoxDecoration(
            color: isMidnight
                ? AppColors.midnightSurface
                : (isDark ? const Color(0xFF131A29) : Colors.white),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: isDone
                  ? AppColors.emerald500.withValues(alpha: isDark ? 0.35 : 0.25)
                  : (isMidnight
                        ? Colors.white.withValues(alpha: 0.12)
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppColors.slate100)),
              width: 1.2.r,
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Row(
            children: [
              // Icon Box with status halo
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44.r,
                    height: 44.r,
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.emerald500.withValues(
                              alpha: isDark ? 0.18 : 0.12,
                            )
                          : AppColors.amber500.withValues(
                              alpha: isDark ? 0.16 : 0.10,
                            ),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: isDone
                            ? AppColors.emerald500.withValues(
                                alpha: isDark ? 0.45 : 0.30,
                              )
                            : AppColors.amber500.withValues(
                                alpha: isDark ? 0.32 : 0.20,
                              ),
                        width: 1.r,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: isDone
                            ? AppColors.emerald500
                            : AppColors.amber500,
                        size: 22.r,
                      ),
                    ),
                  ),
                  if (isDone)
                    Positioned(
                      top: -3.r,
                      right: -3.r,
                      child: Container(
                        width: 15.r,
                        height: 15.r,
                        decoration: BoxDecoration(
                          color: AppColors.emerald500,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isMidnight
                                ? AppColors.midnightSurface
                                : (isDark
                                      ? const Color(0xFF131A29)
                                      : Colors.white),
                            width: 1.5.r,
                          ),
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 9.r,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 14.w),

              // Center column: Tag + Title + Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 1.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppColors.emerald500.withValues(
                                alpha: isDark ? 0.20 : 0.12,
                              )
                            : AppColors.amber500.withValues(
                                alpha: isDark ? 0.20 : 0.12,
                              ),
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                      child: Text(
                        tagText.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w900,
                          color: isDone
                              ? AppColors.emerald500
                              : AppColors.amber500,
                          letterSpacing: 0.6,
                          height: 1.1,
                        ),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      titleText,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.slate900,
                        height: 1.15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitleText,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: isDone ? FontWeight.w600 : FontWeight.w500,
                        color: isDone
                            ? (isDark
                                  ? AppColors.emerald400
                                  : AppColors.emerald600)
                            : (isDark
                                  ? AppColors.slate400
                                  : AppColors.slate600),
                        height: 1.15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),

              // Trailing indicator: Emerald check or Start capsule
              if (isDone)
                Container(
                  width: 32.r,
                  height: 32.r,
                  decoration: BoxDecoration(
                    color: AppColors.emerald500.withValues(
                      alpha: isDark ? 0.16 : 0.10,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.emerald500,
                      size: 20.r,
                    ),
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.amber500.withValues(
                      alpha: isDark ? 0.16 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.amber500.withValues(
                        alpha: isDark ? 0.35 : 0.22,
                      ),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.tr('common.start', fallback: 'Start'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.amber500,
                          height: 1,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Icon(
                        CupertinoIcons.chevron_forward,
                        size: 12.r,
                        color: AppColors.amber500,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
