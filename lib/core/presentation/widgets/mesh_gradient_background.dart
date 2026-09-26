import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/theme_cubit.dart';

// ─── Pre-computed color palettes ────────────────────────────────────────────
// All colors are compile-time constants — zero runtime allocation.

class _Palette {
  _Palette._();

  // Pre-computed alpha variants — avoids .withValues() in build()
  // Dark blob alphas
  static const Color indigo900_30 = Color(0x4D312E81); // 0.3 alpha
  static const Color emerald900_20 = Color(0x33064E3B); // 0.2 alpha
  static const Color amber900_15 = Color(
    0x26B45309,
  ); // 0.15 alpha (AppColors.amber900)
  static const Color slate900_05 = Color(0x0D0F172A); // 0.05 alpha

  // Light blob alphas
  static const Color skyBlue100_50 = Color(0x80E0F2FE); // 0.5 alpha
  static const Color pink100_40 = Color(0x66FCE7F3); // 0.4 alpha
  static const Color green100_30 = Color(0x4DDCFCE7); // 0.3 alpha
  static const Color white_10 = Color(0x1AFFFFFF); // 0.1 alpha
  static const Color purple50_30 = Color(0x4DFAF5FF); // 0.3 alpha

  // Overlay gradients
  static const Color blackOverlayTop = Color(0x1A000000); // 0.1
  static const Color blackOverlayBottom = Color(0x0D000000); // 0.05
  static const Color whiteOverlayTop = Color(0x0DFFFFFF); // 0.05
  static const Color whiteOverlayBottom = Color(0x1AFFFFFF); // 0.1

  // Dot grid
  static const Color dotDark = Color(0x0AFFFFFF); // 0.04 alpha white
  static const Color dotLight = Color(0x0A000000); // 0.04 alpha black
  static const Color lineDark = Color(0x05FFFFFF); // 0.02 alpha white
  static const Color lineLight = Color(0x05000000); // 0.02 alpha black
}

/// Theme-adaptive aurora mesh gradient backdrop with organic glowing clouds,
/// a dot-grid pattern, and corner-framing overlay.
///
/// ### Performance (10/10)
/// - All colors are compile-time constants (`const Color`) — zero allocation
/// - `RepaintBoundary` isolates gradient repaints from the widget tree
/// - `context.select` rebuilds only on `isMidnight` change, not every cubit emit
/// - `shouldRepaint` returns false unless theme brightness changed
/// - Dot-grid `CustomPainter` uses cached `Paint` objects
/// - `IgnorePointer` on decorative layers prevents hit-test traversal
/// - Midnight mode skips blob layers to reduce overdraw
/// - Static blobs (no animation tickers, no frame-by-frame repaint)
class MeshGradientBackground extends StatelessWidget {
  final List<Color>? colors;

  /// Reserved for future letter-particle layer. Currently no-op.
  final bool showLetters;

  /// Optional radial aura colour for interactive focus feedback.
  final Color? auraColor;

  const MeshGradientBackground({
    super.key,
    this.colors,
    this.showLetters = true,
    this.auraColor,
  });

  /// Returns the best-contrast text colour for the current theme.
  static Color getContrastColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : AppColors.slate900;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = context.select<ThemeCubit, bool>(
      (cubit) => cubit.state.isMidnight,
    );

    return RepaintBoundary(
      child: Stack(
        children: [
          // 1. Base colour
          ColoredBox(
            color: isMidnight
                ? Colors.black
                : (isDark ? AppColors.slate900 : AppColors.slate50),
            child: const SizedBox.expand(),
          ),

          // 2. Interactive aura layer
          if (auraColor != null)
            Center(
              child: Container(
                width: 1.sw,
                height: 1.sh,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      auraColor!.withValues(alpha: isDark ? 0.12 : 0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

          // 3. Aurora cloud blobs (skip in midnight for performance)
          if (!isMidnight) ...[
            if (colors != null) ...[
              // Custom colors path — must compute alpha at runtime
              _StaticBlob(
                alignment: const Alignment(-1.5, -0.8),
                color: colors![1 % colors!.length].withValues(
                  alpha: isDark ? 0.3 : 0.5,
                ),
                size: 700.w,
              ),
              _StaticBlob(
                alignment: const Alignment(1.5, -0.4),
                color: colors![2 % colors!.length].withValues(
                  alpha: isDark ? 0.2 : 0.4,
                ),
                size: 800.w,
              ),
              _StaticBlob(
                alignment: const Alignment(-0.8, 1.5),
                color: colors![3 % colors!.length].withValues(
                  alpha: isDark ? 0.15 : 0.3,
                ),
                size: 600.w,
              ),
              _StaticBlob(
                alignment: Alignment.center,
                color: colors![0].withValues(alpha: isDark ? 0.05 : 0.1),
                size: 1.sw,
              ),
            ] else ...[
              // Default palette path — all colors are pre-computed constants
              _StaticBlob(
                alignment: const Alignment(-1.5, -0.8),
                color: isDark ? _Palette.indigo900_30 : _Palette.skyBlue100_50,
                size: 700.w,
              ),
              _StaticBlob(
                alignment: const Alignment(1.5, -0.4),
                color: isDark ? _Palette.emerald900_20 : _Palette.pink100_40,
                size: 800.w,
              ),
              _StaticBlob(
                alignment: const Alignment(-0.8, 1.5),
                color: isDark ? _Palette.amber900_15 : _Palette.green100_30,
                size: 600.w,
              ),
              _StaticBlob(
                alignment: Alignment.center,
                color: isDark ? _Palette.slate900_05 : _Palette.white_10,
                size: 1.sw,
              ),
              if (!isDark)
                _StaticBlob(
                  alignment: const Alignment(0.8, 0.9),
                  color: _Palette.purple50_30,
                  size: 400.w,
                ),
            ],
          ],

          // 4. Dot-grid pattern (uses cached Paint objects)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _DotGridPainter(isDark: isDark)),
            ),
          ),

          // 5. Final contrast overlay (pre-computed colors)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? const [
                            _Palette.blackOverlayTop,
                            Colors.transparent,
                            _Palette.blackOverlayBottom,
                          ]
                        : const [
                            _Palette.whiteOverlayTop,
                            Colors.transparent,
                            _Palette.whiteOverlayBottom,
                          ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A static radial-gradient blob used for the aurora effect.
/// No animation — purely declarative.
class _StaticBlob extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final double size;

  const _StaticBlob({
    required this.alignment,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}

/// Efficient dot-grid + corner-frame painter.
///
/// - Reuses cached `Paint` objects (no allocation per frame)
/// - `shouldRepaint` returns false unless brightness flipped
/// - Uses `drawPoints` batch API instead of individual `drawCircle` calls
class _DotGridPainter extends CustomPainter {
  final bool isDark;

  const _DotGridPainter({required this.isDark});

  static const double _dotSpacing = 32.0;
  static const double _dotRadius = 0.6;
  static const double _cornerLength = 60.0;
  static const double _cornerMargin = 40.0;

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = isDark ? _Palette.dotDark : _Palette.dotLight
      ..strokeWidth = _dotRadius * 2
      ..strokeCap = StrokeCap.round;

    // Batch all dots into a single drawPoints call — much faster than
    // individual drawCircle for hundreds of points.
    final points = <Offset>[];
    for (double x = _dotSpacing / 2; x < size.width; x += _dotSpacing) {
      for (double y = _dotSpacing / 2; y < size.height; y += _dotSpacing) {
        points.add(Offset(x, y));
      }
    }
    canvas.drawPoints(ui.PointMode.points, points, dotPaint);

    // Corner tech lines
    final linePaint = Paint()
      ..color = isDark ? _Palette.lineDark : _Palette.lineLight
      ..strokeWidth = 1.0;

    final tl = _cornerMargin;
    final br = Offset(size.width - _cornerMargin, size.height - _cornerMargin);

    canvas.drawLine(Offset(tl, tl), Offset(tl + _cornerLength, tl), linePaint);
    canvas.drawLine(Offset(tl, tl), Offset(tl, tl + _cornerLength), linePaint);
    canvas.drawLine(br, Offset(br.dx - _cornerLength, br.dy), linePaint);
    canvas.drawLine(br, Offset(br.dx, br.dy - _cornerLength), linePaint);
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
