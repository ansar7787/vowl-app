import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';

/// Side-by-side pedagogical card contrasting the literal verb meaning with its idiomatic phrasal meaning.
class PhrasalVerbsLiteralComparison extends StatelessWidget {
  /// Multiline explanation contrasting literal versus figurative semantics.
  final String literalVsFigurative;

  /// Theme accent color for borders and figurative chips.
  final Color color;

  /// Creates a [PhrasalVerbsLiteralComparison] widget.
  const PhrasalVerbsLiteralComparison({
    super.key,
    required this.literalVsFigurative,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Split the literal vs figurative text. Format expected: "Literal: ... \nFigurative: ..."
    final parts = literalVsFigurative.split('\n');
    final literalText = parts.isNotEmpty ? parts[0] : literalVsFigurative;
    final figurativeText = parts.length > 1 ? parts.sublist(1).join('\n') : "";

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.25 : 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : color.withValues(alpha: 0.06),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows_rounded, color: color, size: 18.r),
              SizedBox(width: 8.w),
              Text(
                "LITERAL VS FIGURATIVE",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildComparisonRow(
            context,
            "LITERAL",
            literalText.replaceFirst('Literal: ', ''),
            isDark,
            Colors.blueGrey,
          ),
          SizedBox(height: 10.h),
          _buildComparisonRow(
            context,
            "FIGURATIVE",
            figurativeText.replaceFirst('Figurative: ', ''),
            isDark,
            color,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
  }

  Widget _buildComparisonRow(
    BuildContext context,
    String label,
    String text,
    bool isDark,
    Color accentColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 90.w,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: isDark ? 0.18 : 0.12),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Center(
            child: AutoSizeText(
              label,
              maxLines: 1,
              minFontSize: 9,
              stepGranularity: 0.5,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: accentColor,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            text,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurface.withValues(
                alpha: isDark ? 0.9 : 0.85,
              ),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
