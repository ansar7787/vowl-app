import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GlassTile extends StatelessWidget {
  const GlassTile({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.padding,
    this.borderRadius,
    this.glassOpacity,
    this.borderOpacity,
    this.blur,
    this.color,
    this.borderColor,
    this.borderWidth,
    this.usePremiumStyle = true,
    this.showShadow = true,
    this.border,
  });
  
  final bool showShadow;
  final bool usePremiumStyle;

  final Widget child;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final double? glassOpacity;
  final double? borderOpacity;
  final double? blur;
  final Color? color;
  final Color? borderColor;
  final double? borderWidth;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final r = borderRadius ?? BorderRadius.circular(32.r);
    final sigma = blur ?? 14.0;

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: usePremiumStyle
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        (color ?? (isMidnight ? Colors.black : Colors.white)).withValues(alpha: isMidnight ? 0.15 : 0.2),
                        Colors.white.withValues(alpha: isMidnight ? 0.05 : 0.08),
                        (isMidnight ? Colors.white : Colors.black).withValues(alpha: 0.05),
                      ]
                    : [
                        (color ?? Colors.white).withValues(alpha: 0.8),
                        Colors.white.withValues(alpha: 0.4),
                        Colors.white.withValues(alpha: 0.2),
                      ],
                stops: const [0.0, 0.5, 1.0],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        (color ?? (isMidnight ? Colors.black : Colors.white)).withValues(alpha: isMidnight ? 0.1 : 0.12),
                        Colors.white.withValues(alpha: 0.02),
                      ]
                    : [
                        (color ?? Colors.white).withValues(alpha: 0.6),
                        Colors.white.withValues(alpha: 0.2),
                      ],
              ),
        border: border ?? Border.all(
          color: borderColor ??
              (isDark
                  ? Colors.white.withValues(alpha: borderOpacity ?? (isMidnight ? 0.08 : 0.15))
                  : const Color(0xFF0F172A).withValues(alpha: borderOpacity ?? 0.08)),
          width: borderWidth ?? 1.4,
        ),
        boxShadow: showShadow ? [
          // Dynamic shadow based on premium style
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? (isMidnight ? 0.8 : 0.4) : 0.06),
            blurRadius: usePremiumStyle ? 25 : 15,
            spreadRadius: usePremiumStyle ? -3 : 0,
            offset: const Offset(0, 12),
          ),
          if (usePremiumStyle)
            BoxShadow(
              color: Colors.white.withValues(alpha: isDark ? (isMidnight ? 0.03 : 0.05) : 0.3),
              blurRadius: 8,
              spreadRadius: -2,
              offset: const Offset(-4, -4),
            ),
        ] : null,
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: RepaintBoundary(
            child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
          ),
        ),
      ),
    );
  }
}
