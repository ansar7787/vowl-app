import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// 3D metallic laurel trophy & medallion artwork with radial ambient rays,
/// specular sheen, and tier-specific heraldry (Rank 1 Gold Trophy, Rank 2 Silver,
/// Rank 3 Bronze, Ranks 4-10 Star Shield).
class LaurelTrophy3DArtwork extends StatelessWidget {
  final int rank;
  final double size;
  final AnimationController? rotationController;

  const LaurelTrophy3DArtwork({
    super.key,
    required this.rank,
    this.size = 150.0,
    this.rotationController,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getTierColors(rank);

    return RepaintBoundary(
      child: SizedBox(
        width: size.r,
        height: size.r,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // 1. Ambient Rotating Sunburst Rays (Hardware rasterized once, matrix-rotated on GPU)
            if (rotationController != null)
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: rotationController!,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: Size(size.r * 1.25, size.r * 1.25),
                      painter: _SunburstPainter(
                        rayColor: colors.highlight.withValues(alpha: 0.18),
                        rayCount: 16,
                      ),
                    ),
                  ),
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: rotationController!.value * 2 * math.pi,
                      child: child,
                    );
                  },
                ),
              ),

            // 2. Ambient Soft Radial Glow
            Container(
              width: size.r * 0.9,
              height: size.r * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.primary.withValues(alpha: 0.35),
                    colors.shadow.withValues(alpha: 0.0),
                  ],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),

            // 3. Laurel Wreath Leaves (Left and Right Wings - Static Layer)
            RepaintBoundary(
              child: CustomPaint(
                size: Size(size.r, size.r),
                painter: _LaurelWreathPainter(tierColors: colors),
              ),
            ),

            // 4. Center Trophy Cup or Tier Medallion (Static Layer)
            RepaintBoundary(
              child: _buildCenterEmblem(colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterEmblem(_TierPalette colors) {
    if (rank == 1) {
      return _buildGoldTrophy(colors);
    } else if (rank == 2) {
      return _buildMedallion(colors, '2', 'SILVER');
    } else if (rank == 3) {
      return _buildMedallion(colors, '3', 'BRONZE');
    } else {
      return _buildTop10Shield(colors, rank);
    }
  }

  /// Sculpted 3D Gold Trophy Cup with handles and pedestal
  Widget _buildGoldTrophy(_TierPalette colors) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Trophy Cup Top + Handles
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Handle
              _buildHandle(isLeft: true, colors: colors),

              // Cup Body
              Container(
                width: (size * 0.42).r,
                height: (size * 0.44).r,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors.highlight, colors.primary, colors.shadow],
                    stops: const [0.1, 0.5, 0.95],
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(10.r),
                    bottom: Radius.circular(22.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Specular Rim Sheen
                    Positioned(
                      top: 2.h,
                      left: 4.w,
                      right: 4.w,
                      child: Container(
                        height: 3.h,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),

                    // Crown / #1 Star Emblem on Cup
                    Positioned.fill(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.star,
                                size: (size * 0.14).r,
                                color: const Color(0xFF78350F),
                              ),
                              Text(
                                '#1',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: (size * 0.12).sp,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF78350F),
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Right Handle
              _buildHandle(isLeft: false, colors: colors),
            ],
          ),

          // Stem
          Container(
            width: (size * 0.10).r,
            height: (size * 0.08).r,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [colors.shadow, colors.highlight, colors.shadow],
              ),
            ),
          ),

          // Stepped Pedestal Base
          Container(
            width: (size * 0.48).r,
            height: (size * 0.12).r,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.highlight, colors.primary, colors.shadow],
              ),
              borderRadius: BorderRadius.circular(6.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'CHAMPION',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: (size * 0.065).sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF78350F),
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle({required bool isLeft, required _TierPalette colors}) {
    return Container(
      width: (size * 0.10).r,
      height: (size * 0.26).r,
      decoration: BoxDecoration(
        border: Border.all(color: colors.primary, width: 3.5.w),
        borderRadius: BorderRadius.horizontal(
          left: isLeft ? Radius.circular(16.r) : Radius.zero,
          right: !isLeft ? Radius.circular(16.r) : Radius.zero,
        ),
      ),
    );
  }

  /// Sculpted 3D Silver / Bronze Medallion
  Widget _buildMedallion(
    _TierPalette colors,
    String rankText,
    String tierName,
  ) {
    return Container(
      width: (size * 0.55).r,
      height: (size * 0.55).r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.highlight, colors.primary, colors.shadow],
          stops: const [0.05, 0.5, 0.95],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.5),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: (size * 0.44).r,
          height: (size * 0.44).r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 2.w,
            ),
            gradient: RadialGradient(
              colors: [colors.highlight.withValues(alpha: 0.9), colors.primary],
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.medal,
                    size: (size * 0.16).r,
                    color: colors.textColor,
                  ),
                  Text(
                    '#$rankText',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: (size * 0.13).sp,
                      fontWeight: FontWeight.w900,
                      color: colors.textColor,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    tierName,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: (size * 0.06).sp,
                      fontWeight: FontWeight.w800,
                      color: colors.textColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Star Champion Shield for Ranks 4-10
  Widget _buildTop10Shield(_TierPalette colors, int rank) {
    return Container(
      width: (size * 0.56).r,
      height: (size * 0.58).r,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.highlight, colors.primary, colors.shadow],
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16.r),
          bottom: Radius.circular(28.r),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.award,
                size: (size * 0.18).r,
                color: Colors.white,
              ),
              SizedBox(height: 2.h),
              Text(
                '#$rank',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: (size * 0.15).sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'TOP 10',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: (size * 0.065).sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _TierPalette _getTierColors(int rank) {
    switch (rank) {
      case 1:
        return const _TierPalette(
          highlight: Color(0xFFFFF59D),
          primary: Color(0xFFFFD54F),
          shadow: Color(0xFFD97706),
          textColor: Color(0xFF78350F),
        );
      case 2:
        return const _TierPalette(
          highlight: Color(0xFFFFFFFF),
          primary: Color(0xFFCBD5E1),
          shadow: Color(0xFF64748B),
          textColor: Color(0xFF1E293B),
        );
      case 3:
        return const _TierPalette(
          highlight: Color(0xFFFFE0B2),
          primary: Color(0xFFD97706),
          shadow: Color(0xFF78350F),
          textColor: Color(0xFF451A03),
        );
      default:
        return const _TierPalette(
          highlight: Color(0xFFA5B4FC),
          primary: Color(0xFF6366F1),
          shadow: Color(0xFF3730A3),
          textColor: Colors.white,
        );
    }
  }
}

class _TierPalette {
  final Color highlight;
  final Color primary;
  final Color shadow;
  final Color textColor;

  const _TierPalette({
    required this.highlight,
    required this.primary,
    required this.shadow,
    required this.textColor,
  });
}

/// Custom painter for ambient sunburst rays rotating behind the trophy
class _SunburstPainter extends CustomPainter {
  final Color rayColor;
  final int rayCount;

  const _SunburstPainter({required this.rayColor, this.rayCount = 16});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = rayColor
      ..style = PaintingStyle.fill;

    final angleStep = (2 * math.pi) / rayCount;
    final halfRay = angleStep * 0.25;

    for (int i = 0; i < rayCount; i++) {
      final baseAngle = i * angleStep;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + radius * math.cos(baseAngle - halfRay),
          center.dy + radius * math.sin(baseAngle - halfRay),
        )
        ..lineTo(
          center.dx + radius * math.cos(baseAngle + halfRay),
          center.dy + radius * math.sin(baseAngle + halfRay),
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SunburstPainter oldDelegate) =>
      oldDelegate.rayColor != rayColor || oldDelegate.rayCount != rayCount;
}

/// Custom painter for golden curving laurel branches (left and right)
class _LaurelWreathPainter extends CustomPainter {
  final _TierPalette tierColors;

  const _LaurelWreathPainter({required this.tierColors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;

    final leafFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [tierColors.highlight, tierColors.primary, tierColors.shadow],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final stemPaint = Paint()
      ..color = tierColors.primary.withValues(alpha: 0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw left and right arcs
    _drawBranch(
      canvas,
      center,
      radius,
      isLeft: true,
      stemPaint: stemPaint,
      leafPaint: leafFill,
    );
    _drawBranch(
      canvas,
      center,
      radius,
      isLeft: false,
      stemPaint: stemPaint,
      leafPaint: leafFill,
    );
  }

  void _drawBranch(
    Canvas canvas,
    Offset center,
    double radius, {
    required bool isLeft,
    required Paint stemPaint,
    required Paint leafPaint,
  }) {
    // 5 leaf clusters along the arch (from bottom to top)
    final startAngle = isLeft ? math.pi * 0.65 : math.pi * 0.35;
    final endAngle = isLeft ? math.pi * 1.15 : math.pi * -0.15;
    final leafCount = 5;

    for (int i = 0; i <= leafCount; i++) {
      final t = i / leafCount;
      final angle = startAngle + (endAngle - startAngle) * t;
      final leafCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      // Draw leaf pair
      final leafAngle = angle + (isLeft ? math.pi * 0.2 : -math.pi * 0.2);
      _drawLeaf(canvas, leafCenter, leafAngle, 9.0, 4.5, leafPaint);
      _drawLeaf(
        canvas,
        leafCenter,
        leafAngle + (isLeft ? 0.35 : -0.35),
        7.5,
        3.5,
        leafPaint,
      );
    }
  }

  void _drawLeaf(
    Canvas canvas,
    Offset center,
    double angle,
    double length,
    double width,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * 0.5, -width, length, 0)
      ..quadraticBezierTo(length * 0.5, width, 0, 0)
      ..close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LaurelWreathPainter oldDelegate) =>
      oldDelegate.tierColors != tierColors;
}
