import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Instruction chip orienting the learner to connect dependent or independent clauses.
class ClauseConnectorInstruction extends StatelessWidget {
  /// Theme accent color.
  final Color primaryColor;

  /// Custom instruction text, or `null` for fallback copy.
  final String? instructionText;

  /// Creates a [ClauseConnectorInstruction] widget.
  const ClauseConnectorInstruction({
    super.key,
    required this.primaryColor,
    this.instructionText,
  });

  String _formatInstruction(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return "Select the connector that best completes the sentence.";
    }
    final trimmed = raw.trim();
    if (trimmed == trimmed.toUpperCase() && trimmed.length > 3) {
      return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final text = _formatInstruction(instructionText);

    return Container(
      constraints: BoxConstraints(maxWidth: 340.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.link_rounded,
            size: 16.r,
            color: primaryColor,
          ),
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
                color: primaryColor,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
