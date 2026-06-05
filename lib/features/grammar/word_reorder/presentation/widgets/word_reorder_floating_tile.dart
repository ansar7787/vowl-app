import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class WordReorderFloatingTile extends StatelessWidget {
  final String word;
  final int index;
  final VoidCallback onTap;
  final Color primaryColor;
  final bool isDark;
  final bool isHighlighted;

  const WordReorderFloatingTile({
    super.key,
    required this.word,
    required this.index,
    required this.onTap,
    required this.primaryColor,
    required this.isDark,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isHighlighted
              ? Colors.amber.withValues(alpha: isDark ? 0.15 : 0.1)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isHighlighted
                ? Colors.amber
                : primaryColor.withValues(alpha: 0.2),
            width: isHighlighted ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isHighlighted
                  ? Colors.amber.withValues(alpha: 0.3)
                  : primaryColor.withValues(alpha: 0.05),
              blurRadius: isHighlighted ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          word,
          style: TextStyle(fontFamily: 'Outfit', 
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: isHighlighted
                ? Colors.amber
                : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ),
    )
    .animate(onPlay: (c) => c.repeat(reverse: true))
    .moveY(
      begin: -5,
      end: 5,
      duration: (2000 + (index * 200)).ms,
      curve: Curves.easeInOutSine,
    )
    .shimmer(
      delay: (index * 100).ms,
      duration: 2.seconds,
      color: Colors.white10,
    );
  }
}
