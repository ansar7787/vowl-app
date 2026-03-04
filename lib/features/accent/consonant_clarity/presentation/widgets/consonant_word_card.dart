import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voxai_quest/core/presentation/themes/level_theme_helper.dart';

class ConsonantWordCard extends StatelessWidget {
  final String word;
  final bool isDark;
  final ThemeResult theme;

  const ConsonantWordCard({
    super.key,
    required this.word,
    required this.isDark,
    required this.theme,
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
      padding: EdgeInsets.symmetric(vertical: 40.h),
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
      child: Center(child: child),
    );
  }
}
