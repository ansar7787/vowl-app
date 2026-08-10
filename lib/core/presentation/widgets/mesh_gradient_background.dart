import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Theme-adaptive aurora mesh gradient backdrop with organic glowing clouds,
/// a dot-grid pattern, and corner-framing overlay.
///
/// Uses [context.select] instead of [context.watch] to rebuild only when the
/// `isMidnight` flag or theme brightness changes — not on every ThemeCubit
/// state update.
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
    return isDark ? Colors.white : const Color(0xFF0F172A);
  }

  @override
  Widget build(BuildContext context) {
    // HIGH FIX: context.select rebuilds only when these two fields change.
    // Previously context.watch<ThemeCubit>() triggered a full rebuild on
    // every ThemeCubit state change (e.g., language, font-size changes).
    final isMidnight = context.select<ThemeCubit, bool>(
      (cubit) => cubit.state.isMidnight,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Color> backgroundColors = colors ?? ((isMidnight || isDark)
        ? const [
            Color(0xFF0F172A),
            Color(0xFF312E81),
            Color(0xFF064E3B),
            Color(0xFF78350F),
          ]
        : const [
            Color(0xFFFFFFFF),
            Color(0xFFE0F2FE),
            Color(0xFFFCE7F3),
            Color(0xFFDCFCE7),
          ]);

    return RepaintBoundary(
      child: Stack(
        children: [
          // 1. Base colour
          ColoredBox(
            color: isMidnight
                ? Colors.black
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
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
            _StaticBlob(
              alignment: const Alignment(-1.5, -0.8),
              color: backgroundColors[1 % backgroundColors.length].withValues(alpha: isDark ? 0.3 : 0.5),
              size: 700.w,
            ),
            _StaticBlob(
              alignment: const Alignment(1.5, -0.4),
              color: backgroundColors[2 % backgroundColors.length].withValues(alpha: isDark ? 0.2 : 0.4),
              size: 800.w,
            ),
            _StaticBlob(
              alignment: const Alignment(-0.8, 1.5),
              color: backgroundColors[3 % backgroundColors.length].withValues(alpha: isDark ? 0.15 : 0.3),
              size: 600.w,
            ),
            _StaticBlob(
              alignment: Alignment.center,
              color: backgroundColors[0].withValues(alpha: isDark ? 0.05 : 0.1),
              size: 1.sw,
            ),
            if (!isDark)
              _StaticBlob(
                alignment: const Alignment(0.8, 0.9),
                color: const Color(0xFFFAF5FF).withValues(alpha: 0.3),
                size: 400.w,
              ),
          ],

          // 4. Dot-grid pattern
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ModernPatternPainter(isDark: isDark),
              ),
            ),
          ),

          // 5. Final contrast overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      isDark
                          ? Colors.black.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.05),
                      Colors.transparent,
                      isDark
                          ? Colors.black.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.1),
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
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _ModernPatternPainter extends CustomPainter {
  final bool isDark;

  const _ModernPatternPainter({required this.isDark});

  // Logical-pixel constants — not scaled by ScreenUtil so the grid stays
  // consistent across all device densities and sizes.
  static const double _dotSpacing = 32.0;
  static const double _dotRadius = 0.6;
  static const double _cornerLength = 60.0;
  static const double _cornerMargin = 40.0;

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    // Dot grid
    for (double x = _dotSpacing / 2; x < size.width; x += _dotSpacing) {
      for (double y = _dotSpacing / 2; y < size.height; y += _dotSpacing) {
        canvas.drawCircle(Offset(x, y), _dotRadius, dotPaint);
      }
    }

    // Corner tech lines
    final linePaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02)
      ..strokeWidth = 1.0;

    final tl = _cornerMargin;
    final br = Offset(size.width - _cornerMargin, size.height - _cornerMargin);

    canvas.drawLine(Offset(tl, tl), Offset(tl + _cornerLength, tl), linePaint);
    canvas.drawLine(Offset(tl, tl), Offset(tl, tl + _cornerLength), linePaint);
    canvas.drawLine(br, Offset(br.dx - _cornerLength, br.dy), linePaint);
    canvas.drawLine(br, Offset(br.dx, br.dy - _cornerLength), linePaint);
  }

  @override
  bool shouldRepaint(covariant _ModernPatternPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
