import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PunctuationMasteryInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;

  const PunctuationMasteryInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  String _cleanInstruction(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return "Place the correct punctuation";
    }
    final trimmed = raw.trim();
    final upper = trimmed.toUpperCase();
    if (upper.contains("HOLOGRAPHIC") ||
        upper.contains("DECAL") ||
        upper.contains("SECTOR CALIBRATION")) {
      return "Place the correct punctuation";
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final cleanText = _cleanInstruction(instruction);

    return Container(
      key: const ValueKey('punctuation_mastery_instruction'),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.edit_note_rounded, size: 16.r, color: primaryColor),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              cleanText,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: primaryColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
