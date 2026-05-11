import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class AgreementVerbTile extends StatelessWidget {
  final String verb;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final VoidCallback onTap;
  final Color primaryColor;
  final bool isDark;
  final bool isMidnight;

  const AgreementVerbTile({
    super.key,
    required this.verb,
    required this.isSelected,
    required this.isCorrect,
    required this.showResult,
    required this.onTap,
    required this.primaryColor,
    required this.isDark,
    this.isMidnight = false,
  });

  @override
  Widget build(BuildContext context) {
    Color? tileColor;
    Color borderColor = primaryColor.withValues(alpha: 0.2);

    if (showResult) {
      if (isCorrect) {
        tileColor = const Color(0xFF10B981);
        borderColor = const Color(0xFF10B981).withValues(alpha: 0.5);
      } else if (isSelected) {
        tileColor = const Color(0xFFF43F5E);
        borderColor = const Color(0xFFF43F5E).withValues(alpha: 0.5);
      }
    } else if (isSelected) {
      tileColor = primaryColor.withValues(alpha: 0.2);
      borderColor = primaryColor;
    }

    return ScaleButton(
      onTap: showResult ? null : onTap,
      child: GlassTile(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        borderRadius: BorderRadius.circular(16.r),
        color: tileColor?.withValues(alpha: 0.8),
        borderColor: borderColor,
        child: Center(
          child: Text(
            verb,
            style: GoogleFonts.outfit(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: (isSelected || (showResult && isCorrect))
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}
