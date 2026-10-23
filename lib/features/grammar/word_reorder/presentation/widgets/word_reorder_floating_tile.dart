import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

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
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    final button = ScaleButton(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isHighlighted
              ? Colors.amber.withValues(alpha: isDark ? 0.18 : 0.12)
              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isHighlighted
                ? Colors.amber
                : (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : primaryColor.withValues(alpha: 0.15)),
            width: isHighlighted ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isHighlighted
                  ? Colors.amber.withValues(alpha: 0.25)
                  : (isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : primaryColor.withValues(alpha: 0.06)),
              blurRadius: isHighlighted ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          word,
          softWrap: true,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: isHighlighted
                ? (isDark ? Colors.amber.shade300 : Colors.amber.shade900)
                : (Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ),
    );

    if (reduceMotion) return button;

    return button
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(
          begin: -3,
          end: 3,
          duration: (2000 + (index * 200)).ms,
          curve: Curves.easeInOutSine,
        );
  }
}
