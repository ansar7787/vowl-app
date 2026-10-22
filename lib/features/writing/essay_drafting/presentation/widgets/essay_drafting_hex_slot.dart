import 'package:vowl/features/kids_zone/theme/kids_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EssayDraftingHexSlot extends StatelessWidget {
  final String slotKey;
  final String? slotValue;
  final Color color;
  final bool isDark;
  final Function(String, String) onSlot;
  final Function(String) onClearSlot;
  final String placeholder;

  const EssayDraftingHexSlot({
    super.key,
    required this.slotKey,
    required this.slotValue,
    required this.color,
    required this.isDark,
    required this.onSlot,
    required this.onClearSlot,
    this.placeholder = 'Place sentence here...',
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final bool hasData = slotValue != null;

    return DragTarget<String>(
      onAcceptWithDetails: (details) => onSlot(slotKey, details.data),
      builder: (context, candidateData, rejectedData) {
        final successColor = isDark ? tokens.gameCorrect : KidsColors.safeGreen;
        final highlight = candidateData.isNotEmpty;

        return GestureDetector(
          key: Key('essay_drafting_slot_$slotKey'),
          onTap: () => onClearSlot(slotKey),
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: isDark
                  ? (hasData
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.03))
                  : (hasData
                      ? Colors.white
                      : Colors.black.withValues(alpha: 0.02)),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: highlight
                    ? successColor
                    : (hasData
                        ? color.withValues(alpha: isDark ? 0.7 : 0.6)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.08))),
                width: 1.5,
              ),
              boxShadow: [
                if (hasData)
                  BoxShadow(
                    color: color.withValues(alpha: isDark ? 0.2 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          slotKey.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: color,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    if (hasData) ...[
                      SizedBox(width: 8.w),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Tap to remove",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Icon(
                            Icons.check_circle_rounded,
                            color: successColor,
                            size: 18.r,
                          ).animate().scale().fadeIn(),
                        ],
                      ),
                    ]
                    else
                      Text(
                        "Empty slot",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: isDark ? Colors.white24 : Colors.black26,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 10.h),
                Text(
                  slotValue ?? placeholder,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: hasData
                        ? (isDark
                            ? Colors.white.withValues(alpha: 0.95)
                            : Colors.black87)
                        : (isDark ? Colors.white38 : Colors.black38),
                    fontSize: 14.5.sp,
                    fontWeight: hasData ? FontWeight.w500 : FontWeight.w400,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
