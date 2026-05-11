import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class ConnectorOptionGrid extends StatelessWidget {
  final List<String> options;
  final int? selectedIndex;
  final int? correctIndex;
  final bool isDark;
  final bool isMidnight;
  final Color primaryColor;
  final Function(int) onSelected;

  const ConnectorOptionGrid({
    super.key,
    required this.options,
    this.selectedIndex,
    this.correctIndex,
    required this.isDark,
    this.isMidnight = false,
    required this.primaryColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (context, index) {
        final isSelected = selectedIndex == index;
        final isCorrect = correctIndex == index;
        final showResult = selectedIndex != null;

        Color? cardColor;
        if (showResult) {
          if (isCorrect) {
            cardColor = const Color(0xFF10B981);
          } else if (isSelected) {
            cardColor = const Color(0xFFF43F5E);
          }
        }

        return ScaleButton(
          onTap: () => onSelected(index),
          child: GlassTile(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            borderRadius: BorderRadius.circular(20.r),
            color: cardColor?.withValues(alpha: 0.8),
            borderColor: isSelected && showResult
                ? Colors.white54
                : primaryColor.withValues(alpha: 0.1),
            child: Center(
              child: Text(
                options[index],
                style: GoogleFonts.outfit(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: (isSelected || showResult)
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.2);
      },
    );
  }
}
