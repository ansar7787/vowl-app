import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ConnectedSpeechInstruction extends StatelessWidget {
  final Color primaryColor;
  final String instruction;
  final bool isCompact;

  const ConnectedSpeechInstruction({
    super.key,
    required this.primaryColor,
    required this.instruction,
    this.isCompact = false,
  });

  String _cleanInstruction(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return "SELECT HOW THE WORDS CONNECT IN NATURAL SPEECH";
    }
    // Clean up robotic or AI buzzword phrasing if encountered
    if (text.toLowerCase().contains("confirm by speaking")) {
      return "SAY THE PHRASE ALOUD TO PRACTICE";
    }
    return text.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cleanText = _cleanInstruction(instruction);

    return Container(
      constraints: BoxConstraints(maxWidth: 380.w),
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: isCompact ? 7.h : 9.h,
      ),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
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
            Icons.waves_rounded,
            size: isCompact ? 14.r : 16.r,
            color: primaryColor,
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              cleanText,
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: null,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: isCompact ? 11.sp : 12.sp,
                fontWeight: FontWeight.w700,
                color: primaryColor,
                letterSpacing: 0.6,
                height: 1.3,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // Symmetrical invisible icon to guarantee true visual centering even when text wraps onto 2 lines
          Icon(
            Icons.waves_rounded,
            size: isCompact ? 14.r : 16.r,
            color: Colors.transparent,
          ),
        ],
      ),
    );
  }
}
