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

  const EssayDraftingHexSlot({
    super.key,
    required this.slotKey,
    required this.slotValue,
    required this.color,
    required this.isDark,
    required this.onSlot,
    required this.onClearSlot,
  });

  @override
  Widget build(BuildContext context) {
    bool hasData = slotValue != null;

    return DragTarget<String>(
      onAcceptWithDetails: (details) => onSlot(slotKey, details.data),
      builder: (context, candidateData, rejectedData) {
        final successColor = isDark
            ? Colors.greenAccent
            : const Color(0xFF16A34A);
        final highlight = candidateData.isNotEmpty;

        return GestureDetector(
          onTap: () => onClearSlot(slotKey),
          child: Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: isDark ? Colors.black45 : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: highlight
                    ? successColor
                    : (hasData ? color : color.withValues(alpha: 0.2)),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: isDark ? 0.25 : 0.08),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    slotKey.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: color,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    slotValue ?? "Drop paragraph block here...",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: hasData
                          ? (isDark ? Colors.white70 : Colors.black87)
                          : (isDark ? Colors.white24 : Colors.black26),
                      fontSize: 12.sp,
                      fontWeight: hasData ? FontWeight.w600 : FontWeight.normal,
                      height: 1.3,
                    ),
                  ),
                ),
                if (hasData)
                  Icon(
                    Icons.check_circle_rounded,
                    color: successColor,
                    size: 18.r,
                  ).animate().scale().fadeIn(),
              ],
            ),
          ),
        );
      },
    );
  }
}
