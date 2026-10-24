import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Drop slot or target container displaying the currently inserted connector.
class ConnectorSlot extends StatelessWidget {
  /// The connector text inserted into this slot, or `null` if empty.
  final String? connector;

  /// Whether the inserted connector was validated as correct.
  final bool isCorrect;

  /// Whether the inserted connector was validated as wrong.
  final bool isWrong;

  /// Theme accent color.
  final Color primaryColor;

  /// Creates a [ConnectorSlot] widget.
  const ConnectorSlot({
    super.key,
    this.connector,
    this.isCorrect = false,
    this.isWrong = false,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          constraints: BoxConstraints(minWidth: 140.w, minHeight: 48.h),
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: _getBgColor(),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: _getBorderColor(),
              width: 1.5,
              style: BorderStyle.solid,
            ),
            boxShadow: [
              if (connector == null)
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.08),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Center(
            child: Text(
              connector ?? "Choose connector",
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: connector == null ? 13.sp : 15.sp,
                fontWeight: FontWeight.w600,
                color: _getTextColor(),
                letterSpacing: 0.3,
              ),
            ),
          ),
        )
        .animate(target: connector != null ? 1 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 200.ms,
        )
        .then()
        .scale(begin: const Offset(1.05, 1.05), end: const Offset(1, 1));
  }

  Color _getBgColor() {
    if (isCorrect) return AppColors.emerald500.withValues(alpha: 0.15);
    if (isWrong) return AppColors.rose500.withValues(alpha: 0.15);
    return primaryColor.withValues(alpha: 0.06);
  }

  Color _getBorderColor() {
    if (isCorrect) return AppColors.emerald500;
    if (isWrong) return AppColors.rose500;
    return primaryColor.withValues(alpha: connector == null ? 0.3 : 0.5);
  }

  Color _getTextColor() {
    if (isCorrect) return AppColors.emerald500;
    if (isWrong) return AppColors.rose500;
    return connector == null
        ? primaryColor.withValues(alpha: 0.6)
        : primaryColor;
  }
}
