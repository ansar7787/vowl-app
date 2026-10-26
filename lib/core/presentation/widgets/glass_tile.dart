import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Premium frosted-glass card with physically realistic blur and gradient overlay.
///
/// PERFORMANCE NOTE: [BackdropFilter] is Flutter's most expensive compositing
/// operation. Each active [GlassTile] adds a full-screen offscreen render target.
/// Avoid stacking more than 3–4 simultaneously on low-end devices.
/// Set [blur] to `0` to skip the filter entirely and fall back to a solid card
/// (useful for scroll lists or lower-performance targets).
class GlassTile extends StatelessWidget {
  final Widget child;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final double? glassOpacity;
  final double? borderOpacity;

  /// Backdrop blur sigma. Set to `0` to disable [BackdropFilter] entirely.
  final double? blur;
  final Color? color;
  final Color? borderColor;
  final double? borderWidth;
  final bool usePremiumStyle;
  final bool showShadow;

  /// Explicit [BoxBorder]. If provided, [borderColor] and [borderWidth] are
  /// ignored to avoid conflicting decoration sources.
  final BoxBorder? border;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Detect midnight variant: scaffold background is fully black in dark mode.
    // Using colorScheme.surface avoids a fragile `== Colors.black` comparison.
    final isMidnight =
        isDark && theme.scaffoldBackgroundColor.computeLuminance() < 0.02;

    final r = borderRadius ?? BorderRadius.circular(32.r);

    // PERF: Force disable expensive blur on low-end devices / low animation mode
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    final sigma = reduceMotion ? 0.0 : (blur ?? 14.0);
    final hasBlur = sigma > 0;

    // border prop takes precedence; otherwise build from color/width fields.
    final resolvedBorder =
        border ??
        Border.all(
          color:
              borderColor ??
              (isDark
                  ? (isMidnight
                      ? const Color(0x24FFFFFF)
                      : const Color(0xFF334155)) // Crisp Slate 700 standard border
                  : const Color(
                      0xFF0F172A,
                    ).withValues(alpha: borderOpacity ?? 0.08)),
          width: borderWidth ?? (isDark ? 1.0 : 1.4),
        );

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: r,
        border: resolvedBorder,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDark ? (isMidnight ? 0.7 : 0.25) : 0.06,
                  ),
                  blurRadius: usePremiumStyle ? 20 : 12,
                  spreadRadius: usePremiumStyle ? -2 : 0,
                  offset: const Offset(0, 8),
                ),
                if (usePremiumStyle && !isDark)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: -2,
                    offset: const Offset(-4, -4),
                  ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          children: [
            // 1. Frosted background (conditionally skip for performance)
            Positioned.fill(
              child: hasBlur
                  ? BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                      child: _GlassOverlay(
                        isDark: isDark,
                        isMidnight: isMidnight,
                        usePremiumStyle: usePremiumStyle,
                        color: color,
                        hasBlur: hasBlur,
                        glassOpacity: glassOpacity,
                      ),
                    )
                  : _GlassOverlay(
                      isDark: isDark,
                      isMidnight: isMidnight,
                      usePremiumStyle: usePremiumStyle,
                      color: color,
                      hasBlur: hasBlur,
                      glassOpacity: glassOpacity,
                    ),
            ),
            // 2. Content — isolated in its own repaint boundary so child
            //    repaints do not invalidate the expensive blur layer.
            RepaintBoundary(
              child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal overlay — separated to keep the main build method readable.
// ---------------------------------------------------------------------------

class _GlassOverlay extends StatelessWidget {
  final bool isDark;
  final bool isMidnight;
  final bool usePremiumStyle;
  final Color? color;
  final bool hasBlur;
  final double? glassOpacity;

  const _GlassOverlay({
    required this.isDark,
    required this.isMidnight,
    required this.usePremiumStyle,
    required this.color,
    required this.hasBlur,
    this.glassOpacity,
  });

  @override
  Widget build(BuildContext context) {
    final defaultDarkSurface = isMidnight
        ? const Color(0xFF0B0F19)
        : const Color(0xFF1E293B);

    final isWhiteBased = color != null &&
        (color == Colors.white ||
            (color!.r > 0.85 && color!.g > 0.85 && color!.b > 0.85));

    if (!hasBlur) {
      final reduceMotion = VowlMotion.shouldReduceMotion(context);
      final baseColor = isDark
          ? ((color == null || isWhiteBased) ? defaultDarkSurface : color!)
          : (color ?? Colors.white);

      final opacity = reduceMotion
          ? 1.0
          : (glassOpacity ?? (isDark ? (isMidnight ? 0.98 : 0.94) : 0.88));

      return Container(
        decoration: BoxDecoration(
          color: isDark ? baseColor.withValues(alpha: opacity) : null,
          gradient: isDark
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    baseColor.withValues(
                      alpha: (opacity * 1.02).clamp(0.0, 1.0),
                    ),
                    baseColor.withValues(alpha: opacity),
                    baseColor.withValues(
                      alpha: (opacity * 0.95).clamp(0.0, 1.0),
                    ),
                  ],
                ),
        ),
      );
    }

    if (isDark) {
      final c = (color != null && !isWhiteBased) ? color! : null;
      return Container(
        decoration: BoxDecoration(
          gradient: usePremiumStyle
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: c != null
                      ? [
                          c.withValues(alpha: 0.35),
                          c.withValues(alpha: 0.20),
                          c.withValues(alpha: 0.10),
                        ]
                      : (isMidnight
                          ? const [
                              Color(0xFF141926),
                              Color(0xFF0B0F19),
                              Color(0xFF070A11),
                            ]
                          : const [
                              Color(0xFF243044),
                              Color(0xFF1E293B),
                              Color(0xFF16202E),
                            ]),
                  stops: const [0.0, 0.5, 1.0],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: c != null
                      ? [
                          c.withValues(alpha: 0.25),
                          c.withValues(alpha: 0.12),
                        ]
                      : (isMidnight
                          ? const [
                              Color(0xFF101622),
                              Color(0xFF0B0F19),
                            ]
                          : const [
                              Color(0xFF222D3E),
                              Color(0xFF1E293B),
                            ]),
                ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: usePremiumStyle
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (color ?? Colors.white).withValues(alpha: 0.80),
                  Colors.white.withValues(alpha: 0.40),
                  Colors.white.withValues(alpha: 0.20),
                ],
                stops: const [0.0, 0.5, 1.0],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (color ?? Colors.white).withValues(alpha: 0.60),
                  Colors.white.withValues(alpha: 0.20),
                ],
              ),
      ),
    );
  }
}
