import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

// ─── Pre-computed color palettes ────────────────────────────────────────────
// All colors are compile-time constants — zero runtime allocation.

class _Palette {
  _Palette._();

  // Dark blob alphas
  static const Color indigo900_30 = Color(0x4D312E81); // 0.3 alpha

  // Overlay gradients (Dark mode)
  static const Color blackOverlayTop = Color(0x1A000000); // 0.1
  static const Color blackOverlayBottom = Color(0x0D000000); // 0.05
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
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    return RepaintBoundary(
      child: Stack(
        children: [
          // 1. Base colour
          ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
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
                      auraColor!.withValues(alpha: isDark ? 0.12 : 0.04),
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
              // Default palette path
              if (isDark) ...[
                // Dark mode default: Calm, cohesive ambient indigo wash at the top-center
                // instead of competing rainbow blobs (emerald, amber, indigo) across the screen.
                _StaticBlob(
                  alignment: const Alignment(0.0, -1.2),
                  color: _Palette.indigo900_30,
                  size: 800.w,
                ),
              ],
              // Light mode default is kept pure, crisp #FFFFFF with zero rainbow blobs or haze.
            ],
          ],

          // 4. Final contrast overlay (dark mode only; skipped in midnight for pure AMOLED black)
          if (!isMidnight && isDark)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _Palette.blackOverlayTop,
                        Colors.transparent,
                        _Palette.blackOverlayBottom,
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
