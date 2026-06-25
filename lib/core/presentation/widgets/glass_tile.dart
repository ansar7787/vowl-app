import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    final sigma = blur ?? 14.0;
    final hasBlur = sigma > 0;

    // border prop takes precedence; otherwise build from color/width fields.
    final resolvedBorder =
        border ??
        Border.all(
          color:
              borderColor ??
              (isDark
                  ? Colors.white.withValues(
                      alpha: borderOpacity ?? (isMidnight ? 0.08 : 0.15),
                    )
                  : const Color(
                      0xFF0F172A,
                    ).withValues(alpha: borderOpacity ?? 0.08)),
          width: borderWidth ?? 1.4,
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
                    alpha: isDark ? (isMidnight ? 0.8 : 0.4) : 0.06,
                  ),
                  blurRadius: usePremiumStyle ? 25 : 15,
                  spreadRadius: usePremiumStyle ? -3 : 0,
                  offset: const Offset(0, 12),
                ),
                if (usePremiumStyle)
                  BoxShadow(
                    color: Colors.white.withValues(
                      alpha: isDark ? (isMidnight ? 0.03 : 0.05) : 0.3,
                    ),
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
                      ),
                    )
                  : _GlassOverlay(
                      isDark: isDark,
                      isMidnight: isMidnight,
                      usePremiumStyle: usePremiumStyle,
                      color: color,
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

  const _GlassOverlay({
    required this.isDark,
    required this.isMidnight,
    required this.usePremiumStyle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: usePremiumStyle
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        (color ?? (isMidnight ? Colors.black : Colors.white))
                            .withValues(alpha: isMidnight ? 0.15 : 0.20),
                        Colors.white.withValues(
                          alpha: isMidnight ? 0.05 : 0.08,
                        ),
                        (isMidnight ? Colors.white : Colors.black).withValues(
                          alpha: 0.05,
                        ),
                      ]
                    : [
                        (color ?? Colors.white).withValues(alpha: 0.80),
                        Colors.white.withValues(alpha: 0.40),
                        Colors.white.withValues(alpha: 0.20),
                      ],
                stops: const [0.0, 0.5, 1.0],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        (color ?? (isMidnight ? Colors.black : Colors.white))
                            .withValues(alpha: isMidnight ? 0.10 : 0.12),
                        Colors.white.withValues(alpha: 0.02),
                      ]
                    : [
                        (color ?? Colors.white).withValues(alpha: 0.60),
                        Colors.white.withValues(alpha: 0.20),
                      ],
              ),
      ),
    );
  }
}
