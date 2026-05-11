import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';

class ConsonantWordCard extends StatelessWidget {
  final String word;
  final String? phoneticHint;
  final bool isDark;
  final ThemeResult theme;
  final bool isMidnight;

  const ConsonantWordCard({
    super.key,
    required this.word,
    this.phoneticHint,
    required this.isDark,
    required this.theme,
    this.isMidnight = false,
  });

  static final _regex = RegExp(r'\[(.*?)\]');

  @override
  Widget build(BuildContext context) {
    final match = _regex.firstMatch(word);

    if (match != null) {
      final highlighted = match.group(1)!;
      final parts = word.split(_regex);
      final prefix = parts[0];
      final suffix = parts.length > 1 ? parts[1] : "";

      return _buildCard(
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.outfit(
              fontSize: 48.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: 4,
            ),
            children: [
              TextSpan(text: prefix),
              TextSpan(
                text: highlighted,
                style: TextStyle(color: theme.primaryColor),
              ),
              TextSpan(text: suffix),
            ],
          ),
        ),
      );
    }

    return _buildCard(
      Text(
        word,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: 48.sp,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white : Colors.black87,
          letterSpacing: 4,
        ),
      ),
    );
  }

  Widget _buildCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 24.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(32.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (phoneticHint != null && phoneticHint!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(
                "[ $phoneticHint ]",
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: theme.primaryColor.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                  letterSpacing: 2,
                ),
              ),
            ),
          Center(child: child),
        ],
      ),
    );
  }
}
