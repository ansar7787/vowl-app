import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

class CompleteSentenceInstruction extends StatelessWidget {
  final Color primaryColor;

  const CompleteSentenceInstruction({super.key, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Instruction: Launch the missing fragment',
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
            // Decorative icon — excluded from accessibility tree.
            ExcludeSemantics(
              child: Icon(
                Icons.gps_fixed_rounded,
                size: 14.r,
                color: primaryColor,
              ),
            ),
            SizedBox(width: 12.w),
            // FIX: Flexible prevents overflow on long localized strings.
            // Scale clamp prevents 10.sp label overflowing the pill at
            // large accessibility font sizes.
            Flexible(
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    MediaQuery.of(context).textScaler.scale(1).clamp(0.8, 1.3),
                  ),
                ),
                child: Text(
                  context
                      .tr(
                        'games.completeSentence_instruction',
                        fallback: 'Complete the sentence.',
                      )
                      .toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
