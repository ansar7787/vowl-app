import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'context_clues_painters.dart';

class ContextCluesCaseFileBackground extends StatelessWidget {
  final Color? accentColor;

  const ContextCluesCaseFileBackground({
    super.key,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark
            ? (tokens?.surface ?? const Color(0xFF161822))
            : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark
              ? (tokens?.borderSubtle ?? Colors.white.withValues(alpha: 0.1))
              : (accentColor?.withValues(alpha: 0.18) ??
                  Colors.black.withValues(alpha: 0.08)),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : (accentColor?.withValues(alpha: 0.08) ??
                    Colors.black.withValues(alpha: 0.05)),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.5.r),
        child: CustomPaint(painter: PaperGridPainter(isDark: isDark)),
      ),
    );
  }
}
