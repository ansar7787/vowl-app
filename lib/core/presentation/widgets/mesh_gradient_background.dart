import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MeshGradientBackground extends StatelessWidget {
  final List<Color>? colors;
  final bool showLetters;
  final Color? auraColor; // New: For interactive feedback
  const MeshGradientBackground({
    super.key,
    this.colors,
    this.showLetters = true,
    this.auraColor,
  });

  /// Static helper to get the best text color based on the theme
  static Color getContrastColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : const Color(0xFF0F172A);
  }

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeCubit>().state;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isMidnight = themeState.isMidnight && isDark;

    // Vibrant Color Palettes (White, Green, Blue, Yellow)
    final List<Color> backgroundColors;

    if (isMidnight || isDark) {
      // Dark/Midnight Mode: Deep Navy Base with Education Glows
      backgroundColors = [
        const Color(0xFF0F172A), // Deep Navy Base
        const Color(0xFF312E81), // Soft Indigo Glow
        const Color(0xFF064E3B), // Deep Emerald Glow
        const Color(0xFF78350F), // Deep Amber Glow
      ];
    } else {
      // Light Mode: Modern "Aurora Glass" (Vibrant but clean)
      backgroundColors = [
        const Color(0xFFFFFFFF), // Pure White Base
        const Color(0xFFE0F2FE), // Soft Sky Blue
        const Color(0xFFFCE7F3), // Soft Rose Pink
        const Color(0xFFDCFCE7), // Soft Mint Green
      ];
    }

    return RepaintBoundary(
      child: Stack(
        children: [
          // 1. Base Gradient Layer
          Container(
            decoration: BoxDecoration(
              color: isMidnight ? Colors.black : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
            ),
          ),
  
        // 2. Interactive Aura Layer (Focus feedback)
        if (auraColor != null)
          Center(
            child: Container(
              width: 1.sw,
              height: 1.sh,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    auraColor!.withValues(alpha: isDark ? 0.12 : 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

        // 3. Aurora Clouds (Large, soft, modern overlapping gradients)
        if (!isMidnight)
          ...[
            _StaticBlob(
              alignment: const Alignment(-1.2, -0.8),
              color: backgroundColors[1].withValues(alpha: isDark ? 0.25 : 0.45),
              size: 500.w,
            ),
            _StaticBlob(
              alignment: const Alignment(1.2, -0.4),
              color: backgroundColors[2].withValues(alpha: isDark ? 0.15 : 0.35),
              size: 600.w,
            ),
            _StaticBlob(
              alignment: const Alignment(-0.8, 1.2),
              color: backgroundColors[3].withValues(alpha: isDark ? 0.12 : 0.25),
              size: 450.w,
            ),
            if (!isDark) // Extra depth for light mode
              _StaticBlob(
                alignment: const Alignment(0.8, 0.9),
                color: const Color(0xFFFAF5FF).withValues(alpha: 0.3),
                size: 400.w,
              ),
          ],
  
        // 4. Modern Dot Grid Pattern
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _ModernPatternPainter(isDark: isDark)),
          ),
        ),
  
        // 5. Final Contrast & Depth Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isDark ? Colors.black.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                  Colors.transparent,
                  isDark ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.1),
                ],
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
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _ModernPatternPainter extends CustomPainter {
  final bool isDark;
  const _ModernPatternPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..strokeWidth = 1.0;
    
    // 1. Draw Geometric Dot Grid
    const double spacing = 32.0;
    for (double i = spacing / 2; i < size.width; i += spacing) {
      for (double j = spacing / 2; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), 0.6, dotPaint);
      }
    }

    // 2. Add subtle "Tech" lines at the corners
    final linePaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02)
      ..strokeWidth = 1.0;
    
    canvas.drawLine(const Offset(40, 40), const Offset(100, 40), linePaint);
    canvas.drawLine(const Offset(40, 40), const Offset(40, 100), linePaint);
    
    canvas.drawLine(Offset(size.width - 40, size.height - 40), Offset(size.width - 100, size.height - 40), linePaint);
    canvas.drawLine(Offset(size.width - 40, size.height - 40), Offset(size.width - 40, size.height - 100), linePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Removed unused _StaticAlphabet widget to resolve IDE warnings.
