import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Instruction banner guiding users to trace or tap preposition paths.
class PrepositionChoiceInstruction extends StatelessWidget {
  /// The primary theme accent color.
  final Color primaryColor;

  /// The instruction text describing the objective.
  final String? instruction;

  /// Creates a [PrepositionChoiceInstruction] widget.
  const PrepositionChoiceInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  static const _defaultLabel = "Trace or tap the correct preposition";

  String _cleanInstruction(String? raw) {
    if (raw == null || raw.trim().isEmpty) return _defaultLabel;
    final trimmed = raw.trim();
    if (trimmed.toUpperCase() == 'TRACE OR TAP A NODE') {
      return 'Trace or tap the correct preposition';
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final text = _cleanInstruction(instruction);
    return Semantics(
      label: text,
      child: Container(
        key: const ValueKey('preposition_choice_instruction'),
        margin: EdgeInsets.symmetric(horizontal: 24.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.touch_app_rounded, size: 16.r, color: primaryColor),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                  letterSpacing: 0.4,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
