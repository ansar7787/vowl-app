import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Instruction chip guiding the learner through consonant enunciation and articulation tasks.
class ConsonantClarityInstruction extends StatelessWidget {
  /// Theme accent color.
  final Color primaryColor;

  /// Custom instruction text, or `null` to use default localization.
  final String? instruction;

  /// Creates a [ConsonantClarityInstruction] widget.
  const ConsonantClarityInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  String _formatInstruction(BuildContext context) {
    final raw = instruction ??
        context.tr(
          'games.consonantClarity_instruction',
          fallback: 'Choose the correct consonant sound.',
        );

    // If text is ALL CAPS from raw curriculum data (e.g. "IDENTIFY THE CONSONANT..."),
    // format to clean sentence case for a natural, human look while preserving phonetics.
    if (raw.length > 5 && raw == raw.toUpperCase() && !raw.contains('/')) {
      return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _formatInstruction(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      constraints: BoxConstraints(maxWidth: 340.w),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.record_voice_over_rounded,
            size: 14.r,
            color: primaryColor,
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              displayText,
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: null,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: primaryColor,
                letterSpacing: 0.3,
                height: 1.3,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Icon(
            Icons.record_voice_over_rounded,
            size: 14.r,
            color: Colors.transparent,
          ),
        ],
      ),
    );
  }
}
