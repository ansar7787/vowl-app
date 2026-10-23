import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ModifierPlacementInstruction extends StatelessWidget {
  final String instructionText;
  final Color primaryColor;
  final double? horizontalMargin;

  const ModifierPlacementInstruction({
    super.key,
    required this.primaryColor,
    required this.instructionText,
    this.horizontalMargin,
  });

  String _formatInstruction(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text.toUpperCase() == 'PLACE THE MODIFIER') {
      return 'Place the modifier';
    }
    // If the text is screaming in all-caps, convert to clean sentence case
    if (text == text.toUpperCase() && text.length > 1) {
      return text[0].toUpperCase() + text.substring(1).toLowerCase();
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _formatInstruction(instructionText);

    return Semantics(
      label: displayText,
      child: Container(
        key: const ValueKey('modifier_placement_instruction'),
        margin: EdgeInsets.symmetric(horizontal: horizontalMargin ?? 20.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.2),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.tune_rounded, size: 16.r, color: primaryColor),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                displayText,
                key: const ValueKey('modifier_placement_instruction_text'),
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                  letterSpacing: 0.3,
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
