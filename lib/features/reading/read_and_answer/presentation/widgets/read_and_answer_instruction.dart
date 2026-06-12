import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReadAndAnswerInstruction extends StatelessWidget {
  final Color primaryColor;

  /// Instruction copy displayed in the banner.
  /// Defaults to the original design text; pass a translated string for I18n.
  final String label;

  const ReadAndAnswerInstruction({
    super.key,
    required this.primaryColor,
    this.label = 'DIVE THROUGH THE ABYSS TO ANCHOR TRUTH',
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // 'header' signals to TalkBack/VoiceOver that this is a labelled
      // section header — players hear it once on arrival, not on every focus.
      header: true,
      label: label,
      excludeSemantics: true,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decorative icon — excluded from semantics by parent wrapper.
              ExcludeSemantics(
                child: Icon(
                  Icons.scuba_diving_rounded,
                  size: 14.r,
                  color: primaryColor,
                ),
              ),
              SizedBox(width: 12.w),
              Flexible(
                // FlexFit.loose: the text shrinks to its content width
                // without forcing the Row to expand to fill available space.
                fit: FlexFit.loose,
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
