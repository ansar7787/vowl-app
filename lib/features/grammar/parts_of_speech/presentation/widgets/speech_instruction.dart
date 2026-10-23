import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Pill-shaped instruction label guiding the user to sort or match the word
/// with its part of speech.
class SpeechInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;
  final bool isCompact;

  const SpeechInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
    this.isCompact = false,
  });

  static const _defaultInstruction = 'Choose the correct part of speech';

  /// Normalizes instruction text so it uses clear, natural English
  /// without robotic AI phrasing or game jargon.
  static String _resolveInstruction(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return _defaultInstruction;
    }
    final trimmed = raw.trim();
    final upper = trimmed.toUpperCase();
    if (upper == 'IDENTIFY THE FUNCTION' || upper == 'FLICK OR TAP TO ANSWER') {
      return _defaultInstruction;
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final text = _resolveInstruction(instruction);
    final fontSize = isCompact ? 11.sp : 13.sp;

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
          color: primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24.r),
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
            Icon(
              Icons.touch_app_rounded,
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
                  height: 1.3,
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
