import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ConnectorSlot extends StatelessWidget {
  final String? connector;
  final bool isCorrect;
  final bool isWrong;
  final Color primaryColor;

  const ConnectorSlot({
    super.key,
    this.connector,
    this.isCorrect = false,
    this.isWrong = false,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          constraints: BoxConstraints(minWidth: 120.w),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: _getBgColor(),
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(
              color: _getBorderColor(),
              width: 2,
              style: connector == null ? BorderStyle.solid : BorderStyle.solid,
            ),
            boxShadow: [
              if (connector == null)
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Center(
            child: Text(
              connector ?? "?",
              style: GoogleFonts.outfit(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: _getTextColor(),
              ),
            ),
          ),
        )
        .animate(target: connector != null ? 1 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.1, 1.1),
          duration: 200.ms,
        )
        .then()
        .scale(begin: const Offset(1.1, 1.1), end: const Offset(1, 1));
  }

  Color _getBgColor() {
    if (isCorrect) return const Color(0xFF10B981).withValues(alpha: 0.2);
    if (isWrong) return const Color(0xFFF43F5E).withValues(alpha: 0.2);
    return primaryColor.withValues(alpha: 0.05);
  }

  Color _getBorderColor() {
    if (isCorrect) return const Color(0xFF10B981);
    if (isWrong) return const Color(0xFFF43F5E);
    return primaryColor.withValues(alpha: connector == null ? 0.3 : 0.6);
  }

  Color _getTextColor() {
    if (isCorrect) return const Color(0xFF10B981);
    if (isWrong) return const Color(0xFFF43F5E);
    return connector == null
        ? primaryColor.withValues(alpha: 0.5)
        : primaryColor;
  }
}
