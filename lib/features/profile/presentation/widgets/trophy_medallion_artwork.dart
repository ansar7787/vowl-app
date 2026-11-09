import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/category_colors.dart';
import 'package:vowl/features/profile/domain/models/trophy_metadata.dart';

/// 3D metallic vector medallion artwork for Trophy Room achievements.
///
/// Features authentic metallic bezel framing (Bronze, Silver, Gold, Flame, Amethyst, Crown),
/// radiant jewel-tone filled depth splash with glowing ambient aura, crisp heraldry,
/// and zero distracting specular bars.
class TrophyMedallionArtwork extends StatelessWidget {
  /// Achievement metadata definition.
  final TrophyMetadata metadata;

  /// Whether the badge is unlocked by the user.
  final bool isEarned;

  /// Size of the medallion bounding box.
  final double size;

  /// Creates a [TrophyMedallionArtwork].
  const TrophyMedallionArtwork({
    super.key,
    required this.metadata,
    required this.isEarned,
    this.size = 64.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rSize = size.r;

    if (!isEarned) {
      return _buildLockedMedallion(rSize, isDark);
    }

    if (metadata.isLegendary) {
      return _buildLegendaryMedallion(rSize, isDark);
    }

    return _buildStandardMedallion(rSize, isDark);
  }

  Widget _buildStandardMedallion(double rSize, bool isDark) {
    final catColor = CategoryColors.forCategory(metadata.category);
    final darkVariant = CategoryColors.darkVariant(metadata.category);

    return SizedBox(
      width: rSize,
      height: rSize,
      child: Container(
        width: rSize,
        height: rSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.2, -0.3),
            radius: 0.85,
            colors: [
              catColor.withValues(alpha: isDark ? 0.85 : 0.95),
              darkVariant.withValues(alpha: isDark ? 0.98 : 1.0),
            ],
          ),
          border: Border.all(
            color:
                catColor, // SAME COLOR as background: gives the circle a large, full bleed feel!
            width: 2.2.r,
          ),
          boxShadow: [
            BoxShadow(
              color: catColor.withValues(alpha: isDark ? 0.50 : 0.35),
              blurRadius: 14,
              spreadRadius: 1.5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(metadata.icon, size: rSize * 0.48, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildLegendaryMedallion(double rSize, bool isDark) {
    return SizedBox(
      width: rSize,
      height: rSize,
      child: Container(
        width: rSize,
        height: rSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-0.2, -0.3),
            radius: 0.85,
            colors: [
              Color(0xFFFDE68A), // Radiant Gold
              Color(0xFFB45309), // Deep Amber
              Color(0xFF78350F), // Rich molten bronze
            ],
          ),
          border: Border.all(
            color: AppColors
                .gold, // SAME COLOR as background: big full bleed feel!
            width: 2.5.r,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.50),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '👑',
              style: TextStyle(
                fontSize: (rSize * 0.46).sp,
                shadows: const [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedMedallion(double rSize, bool isDark) {
    final lockedColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    final lockedBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return SizedBox(
      width: rSize,
      height: rSize,
      child: Center(
        child: Container(
          width: rSize * 0.88,
          height: rSize * 0.88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: lockedColor,
            border: Border.all(color: lockedBorder, width: 1.5.r),
          ),
          child: Center(
            child: Icon(
              Icons.lock_rounded,
              size: rSize * 0.44,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
          ),
        ),
      ),
    );
  }
}
