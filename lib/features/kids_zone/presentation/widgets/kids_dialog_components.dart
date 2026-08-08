import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:auto_size_text/auto_size_text.dart';

/// AAA Rotating Sunburst Background for Victory Screens
class KidsSunburstBackground extends StatelessWidget {
  final Color color;
  const KidsSunburstBackground({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Center(
        child:
            Container(
                  width: 800.w,
                  height: 800.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.1, 0.8],
                    ),
                  ),
                )
                .animate(onPlay: (c) => c.repeat())
                .rotate(duration: 10.seconds, curve: Curves.linear),
      ),
    );
  }
}

/// AAA 3D Button with Shine and Solid Shadows
class Kids3DButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isGolden;
  final Color? textColor;

  const Kids3DButton({
    super.key,
    required this.text,
    required this.color,
    required this.onTap,
    this.icon,
    this.isGolden = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final shadowColor = isGolden
        ? const Color(0xFFD97706)
        : color.withValues(alpha: 0.7);

    return ScaleButton(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            height: 60.h,
            decoration: BoxDecoration(
              color: shadowColor,
              borderRadius: BorderRadius.circular(30.r),
            ),
          ),
          Container(
            width: double.infinity,
            height: 54.h, // Less height leaves bottom shadow visible
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              gradient: isGolden
                  ? const LinearGradient(
                      colors: [Color(0xFFFFEA70), Color(0xFFFFD700)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : LinearGradient(
                      colors: [color.withValues(alpha: 0.7), color],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(
                color: isGolden
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
                width: 3.w,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color:
                          textColor ??
                          (isGolden ? const Color(0xFF8B4513) : Colors.white),
                      size: 26.sp,
                    ),
                    SizedBox(width: 8.w),
                  ],
                  Flexible(
                    child: AutoSizeText(
                      text.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w900,
                        color:
                            textColor ??
                            (isGolden ? const Color(0xFF8B4513) : Colors.white),
                        fontSize: 18.sp,
                        letterSpacing: 1.5,
                      ),
                      maxLines: 1,
                      minFontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// AAA Dialog Frame with Ribbon Header and Chunky Borders
class KidsDialogContainer extends StatelessWidget {
  final Color primaryColor;
  final Widget child;
  final String title;
  final Color? ribbonColor;
  final Color? ribbonTextColor;

  const KidsDialogContainer({
    super.key,
    required this.primaryColor,
    required this.child,
    required this.title,
    this.ribbonColor,
    this.ribbonTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Color.lerp(const Color(0xFF1E293B), primaryColor, 0.15)!
        : Colors.white;

    final usedRibbonColor = ribbonColor ?? primaryColor;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            margin: EdgeInsets.only(top: 24.h),
            padding: EdgeInsets.fromLTRB(24.w, 48.h, 24.w, 24.w),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(40.r),
              border: Border.all(color: primaryColor, width: 8.w),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.5),
                  offset: Offset(0, 16.h),
                  blurRadius: 0,
                ),
              ],
            ),
            child: child,
          ),
          // Overlapping Ribbon Header
          Positioned(
            top: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: usedRibbonColor,
                borderRadius: BorderRadius.circular(30.r),
                border: Border.all(color: Colors.white, width: 5.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: Offset(0, 6.h),
                  ),
                ],
              ),
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w900,
                  color: ribbonTextColor ?? Colors.white,
                  fontSize: 24.sp,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ).animate().scale(curve: Curves.elasticOut, delay: 200.ms),
          ),
        ],
      ),
    );
  }
}
