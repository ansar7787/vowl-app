import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Instruction banner guiding users to connect relative clauses.
class RelativeClausesInstruction extends StatelessWidget {
  /// The instruction text describing the objective.
  final String? instruction;

  /// The primary theme accent color.
  final Color primaryColor;

  /// Creates a [RelativeClausesInstruction] widget.
  const RelativeClausesInstruction({
    super.key,
    this.instruction,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = instruction ?? "Tap or drag to connect the clause";

    return Container(
      key: const ValueKey('relative_clauses_instruction'),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.link_rounded, size: 15.r, color: primaryColor),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: primaryColor,
                letterSpacing: 0.2,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
