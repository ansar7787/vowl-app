import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Top navigation bar for the Word Snap challenge.
class WordSnapTopBar extends StatelessWidget {
  final int streak;

  const WordSnapTopBar({
    super.key,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          // Accessible, tactile back button
          Semantics(
            label: context.tr('common.back', fallback: 'Back'),
            button: true,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14.r),
              child: InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(14.r),
                child: Container(
                  width: 44.r,
                  height: 44.r,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: theme.colorScheme.onSurface,
                    size: 22.r,
                  ),
                ),
              ),
            ),
          ),

          // Title
          Expanded(
            child: Text(
              context.tr('home.tools_word_snap', fallback: 'Word Snap'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
          ),

          // Streak badge or balancing spacer
          if (streak > 0)
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
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(width: 44.r), // Balances the 44.r back button width
        ],
      ),
    );
  }
}
