import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Instruction banner guiding users to identify or toggle active and passive voice.
class VoiceSwapInstruction extends StatelessWidget {
  /// The primary theme accent color.
  final Color primaryColor;

  /// The instruction text describing the objective.
  final String? instruction;

  /// Creates a [VoiceSwapInstruction] widget.
  const VoiceSwapInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  String _cleanInstruction() {
    final raw = instruction?.trim();
    if (raw == null || raw.isEmpty) {
      return "Choose whether the sentence is in Active or Passive voice";
    }
    final upper = raw.toUpperCase();
    if (upper.contains("TRANSMUTER") || upper.contains("FLIP THE VOICE")) {
      return "Choose whether the sentence is in Active or Passive voice";
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = _cleanInstruction();

    return Semantics(
      label: 'Instruction: $text',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.22),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz_rounded, size: 18.r, color: primaryColor),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.95)
                      : AppColors.slate800,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
