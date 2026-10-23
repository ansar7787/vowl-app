import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/kids_zone/theme/kids_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Drop target receiving email sections into designated positions such as Subject or Greeting.
class WritingEmailHexSlot extends StatelessWidget {
  /// Key identifying the section role (e.g. SUBJECT, GREETING, BODY, SIGN-OFF).
  final String slotKey;

  /// The currently assigned text for this email slot, or null if empty.
  final String? slotValue;

  /// Theme accent color applied to highlight borders.
  final Color color;

  /// Whether the active theme is in dark mode.
  final bool isDark;

  /// Callback invoked when a fragment is dropped or assigned to this slot.
  final Function(String, String) onSlot;

  /// Callback invoked when an assigned slot is tapped to remove its fragment.
  final Function(String) onClearSlot;

  /// Creates a [WritingEmailHexSlot] widget.
  const WritingEmailHexSlot({
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
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final bool hasData = slotValue != null;

    return DragTarget<String>(
      onAcceptWithDetails: (details) => onSlot(slotKey, details.data),
      builder: (context, candidateData, rejectedData) {
        final highlight = candidateData.isNotEmpty;

        final successColor = isDark
            ? (tokens?.gameCorrect ?? AppColors.emerald500)
            : KidsColors.safeGreen;

        return Semantics(
          label: "Slot for $slotKey",
          value: hasData ? slotValue : "Empty",
          hint: hasData ? "Double tap to clear" : "Drag an email part here",
          button: hasData,
          child: GestureDetector(
            key: Key('writing_email_slot_$slotKey'),
            onTap: () => onClearSlot(slotKey),
            child: Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isDark
                    ? (hasData ? const Color(0xFF1E2230) : const Color(0xFF161922))
                    : (hasData ? Colors.white : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: highlight
                      ? successColor
                      : (hasData
                          ? color.withValues(alpha: isDark ? 0.6 : 0.45)
                          : (isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                  width: highlight ? 2 : 1.2,
                ),
                boxShadow: hasData
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: isDark ? 0.15 : 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 9.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: hasData
                          ? color.withValues(alpha: 0.12)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: hasData
                            ? color.withValues(alpha: 0.25)
                            : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      slotKey,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: hasData
                            ? color
                            : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Text(
                        slotValue ?? "Empty slot",
                        softWrap: true,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: hasData
                              ? (isDark
                                  ? Colors.white.withValues(alpha: 0.95)
                                  : const Color(0xFF1E293B))
                              : (isDark
                                  ? Colors.white38
                                  : const Color(0xFF94A3B8)),
                          fontSize: 14.sp,
                          fontWeight: hasData ? FontWeight.w500 : FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  if (hasData) ...[
                    SizedBox(width: 8.w),
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: (VowlMotion.shouldReduceMotion(context) ||
                              VowlMotion.lowAnimationModeOverride.value)
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: successColor,
                              size: 18.r,
                            )
                          : Icon(
                              Icons.check_circle_rounded,
                              color: successColor,
                              size: 18.r,
                            ).animate().scale().fadeIn(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
