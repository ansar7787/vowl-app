import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

class SentenceBuilderInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;

  const SentenceBuilderInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Instruction: Assemble the jigsaw of logic',
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
            // ACCESSIBILITY: icon is decorative — excluded from a11y tree.
            ExcludeSemantics(
              child: Icon(
                Icons.carpenter_rounded,
                size: 14.r,
                color: primaryColor,
              ),
            ),
            SizedBox(width: 12.w),
            // FIX: Flexible prevents overflow when localized text is longer.
            // MediaQuery clamp prevents the 10.sp label from overflowing the
            // pill at large accessibility font scales.
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
                        'games.sentenceBuilder_instruction',
                        fallback:
                            instruction ??
                            'Assemble the fragments into a correct sentence',
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
