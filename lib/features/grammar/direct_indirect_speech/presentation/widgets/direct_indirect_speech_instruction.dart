import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Clean, centered instruction pill for Direct/Indirect Speech game.
/// Formatted with standard typography, no truncation/ellipses, and centered alignment.
class DirectIndirectSpeechInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;
  final bool isCompact;

  const DirectIndirectSpeechInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
    this.isCompact = false,
  });

  static const _defaultInstruction = 'Select the correct indirect speech';

  /// Resolves instruction text into natural, human-written English
  /// avoiding robotic all-caps, buzzwords, or AI jargon.
  static String _resolveInstruction(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return _defaultInstruction;
    }
    final trimmed = raw.trim();
    final upper = trimmed.toUpperCase();
    if (upper == 'CHOOSE THE REPORTED SPEECH' ||
        upper == 'CONVERT TO REPORTED SPEECH' ||
        upper == 'IDENTIFY THE REPORTED SPEECH' ||
        upper == 'SELECT THE REPORTED SPEECH') {
      return _defaultInstruction;
    }
    // Clean up if raw instruction is ALL CAPS
    if (trimmed == upper && trimmed.length > 5) {
      return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final text = _resolveInstruction(instruction);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fontSize = isCompact ? 11.5.sp : 13.sp;

    return Semantics(
      label: text,
      child: Container(
        key: const ValueKey('speech_instruction'),
        margin: EdgeInsets.symmetric(horizontal: 20.w),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 14.w : 18.w,
          vertical: isCompact ? 6.h : 8.h,
        ),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: isDark ? 0.08 : 0.06),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: primaryColor.withValues(alpha: isDark ? 0.22 : 0.18),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: isCompact ? 14.r : 16.r,
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
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                  height: 1.35,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
