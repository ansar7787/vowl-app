import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SpeakSynonymHeader extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;

  const SpeakSynonymHeader({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final safeCorrectColor = tokens.gameCorrect;

    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            key: const Key('speak_synonym_challenge_badge'),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.eco_rounded, size: 14.r, color: safeCorrectColor),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    "SYNONYM CHALLENGE",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: safeCorrectColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (instruction != null) ...[
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: Text(
                instruction!,
                key: const Key('speak_synonym_instruction_text'),
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: tokens.textSecondary,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
