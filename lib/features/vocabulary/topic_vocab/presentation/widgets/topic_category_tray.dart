import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// A guided semantic category tray for the Practice Phase.
/// Displays the category name, emoji, active selection indicator,
/// target progress counter, and slots for placed words.
class TopicCategoryTray extends StatelessWidget {
  final String categoryName;
  final String emoji;
  final String? clue;
  final String? explanation;
  final List<String>? collocations;
  final int targetCount;
  final List<String> placedWords;
  final bool isActive;
  final bool isCompleted;
  final Color accentColor;
  final VoidCallback onTap;
  final void Function(String word)? onRemoveWord;
  final void Function(String word)? onWordTap;

  const TopicCategoryTray({
    super.key,
    required this.categoryName,
    required this.emoji,
    this.clue,
    this.explanation,
    this.collocations,
    this.targetCount = 3,
    required this.placedWords,
    required this.isActive,
    required this.isCompleted,
    required this.accentColor,
    required this.onTap,
    this.onRemoveWord,
    this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isCompleted
        ? AppColors.emerald500
        : isActive
            ? accentColor
            : (isDark ? AppColors.slate700 : AppColors.slate200);

    final backgroundColor = isCompleted
        ? AppColors.emerald500.withValues(alpha: isDark ? 0.12 : 0.06)
        : isActive
            ? accentColor.withValues(alpha: isDark ? 0.10 : 0.05)
            : (isDark ? AppColors.slate800 : Colors.white);

    return ScaleButton(
      onTap: isCompleted ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: borderColor,
            width: isActive || isCompleted ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row: Icon, Category Name, Active/Done Badge
            Row(
              children: [
                Container(
                  width: 28.r,
                  height: 28.r,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.emerald500.withValues(alpha: 0.15)
                        : accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  alignment: Alignment.center,
                  child: emoji.isNotEmpty
                      ? Text(
                          emoji,
                          style: TextStyle(fontSize: 15.sp),
                        )
                      : Icon(
                          isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.category_rounded,
                          size: 16.r,
                          color:
                              isCompleted ? AppColors.emerald500 : accentColor,
                        ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: AutoSizeText(
                    categoryName,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.emerald500
                        : (isActive
                            ? accentColor
                            : (isDark ? Colors.white10 : Colors.black12)),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCompleted) ...[
                        Icon(
                          Icons.check_rounded,
                          size: 13.r,
                          color: Colors.white,
                        ),
                        SizedBox(width: 3.w),
                      ],
                      Text(
                        '${placedWords.length}/$targetCount',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: isCompleted || isActive
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Clue or Explanation subtitle
            if (isCompleted && explanation != null && explanation!.isNotEmpty) ...[
              SizedBox(height: 6.h),
              Text(
                explanation!,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ] else if (clue != null && clue!.isNotEmpty) ...[
              SizedBox(height: 4.h),
              Text(
                clue!,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],

            SizedBox(height: 10.h),

            // Placed word slots row
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: List.generate(targetCount, (index) {
                final hasWord = index < placedWords.length;
                if (hasWord) {
                  final word = placedWords[index];
                  return _PlacedWordChip(
                    word: word,
                    isCompleted: isCompleted,
                    accentColor: accentColor,
                    onTap: () => onWordTap?.call(word),
                    onRemove: isCompleted
                        ? null
                        : () => onRemoveWord?.call(word),
                  );
                } else {
                  return _EmptyWordSlot(
                    isActive: isActive,
                    accentColor: accentColor,
                  );
                }
              }),
            ),

            // Real-world Collocations spotlight
            if (isCompleted && collocations != null && collocations!.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.link_rounded,
                    size: 13.r,
                    color: AppColors.emerald500,
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: AutoSizeText(
                      collocations!.join(' • '),
                      maxLines: 2,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5.sp,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlacedWordChip extends StatelessWidget {
  final String word;
  final bool isCompleted;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _PlacedWordChip({
    required this.word,
    required this.isCompleted,
    required this.accentColor,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final chip = Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.emerald500.withValues(alpha: isDark ? 0.25 : 0.15)
            : accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isCompleted ? AppColors.emerald500 : accentColor,
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.volume_up_rounded,
                  size: 14.r,
                  color: isCompleted ? AppColors.emerald500 : accentColor,
                ),
                SizedBox(width: 4.w),
                Text(
                  word,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (onRemove != null) ...[
            SizedBox(width: 6.w),
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Icon(
                Icons.cancel_rounded,
                size: 15.r,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ],
      ),
    );

    if (VowlMotion.shouldReduceMotion(context)) {
      return chip;
    }

    return chip
        .animate()
        .scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1, 1),
          duration: 180.ms,
          curve: Curves.easeOutBack,
        );
  }
}

class _EmptyWordSlot extends StatelessWidget {
  final bool isActive;
  final Color accentColor;

  const _EmptyWordSlot({
    required this.isActive,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 78.w,
      height: 32.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate900 : AppColors.slate100,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isActive
              ? accentColor.withValues(alpha: 0.45)
              : (isDark ? AppColors.slate700 : AppColors.slate300),
          width: 1.0,
          style: BorderStyle.solid,
        ),
      ),
      child: Icon(
        Icons.add_rounded,
        size: 15.r,
        color: isActive
            ? accentColor.withValues(alpha: 0.7)
            : (isDark ? AppColors.slate500 : AppColors.slate400),
      ),
    );
  }
}
