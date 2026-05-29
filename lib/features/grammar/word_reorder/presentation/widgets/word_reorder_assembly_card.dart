import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class WordReorderAssemblyCard extends StatelessWidget {
  final List<int> assembledIndices;
  final List<String> shuffledWords;
  final Color primaryColor;
  final bool isDark;
  final bool isAnswered;
  final ValueChanged<int> onWordRemove;

  const WordReorderAssemblyCard({
    super.key,
    required this.assembledIndices,
    required this.shuffledWords,
    required this.primaryColor,
    required this.isDark,
    required this.isAnswered,
    required this.onWordRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: 120.h),
        padding: EdgeInsets.all(22.r),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Wrap(
            spacing: 8.w,
            runSpacing: 10.h,
            alignment: WrapAlignment.center,
            children: assembledIndices.isEmpty
                ? [
                    Text(
                      "WAITING FOR DATA...",
                      style: GoogleFonts.outfit(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: primaryColor.withValues(alpha: 0.3),
                        letterSpacing: 2,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .shimmer(duration: 2.seconds),
                  ]
                : assembledIndices.map((idx) {
                    final word = shuffledWords[idx];
                    return ScaleButton(
                      onTap: isAnswered ? null : () => onWordRemove(idx),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          word,
                          style: GoogleFonts.fredoka(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ).animate().scale(
                      duration: 400.ms,
                      curve: Curves.elasticOut,
                    );
                  }).toList(),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }
}
