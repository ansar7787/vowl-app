import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/profile/domain/models/trophy_metadata.dart';
import 'package:vowl/features/profile/presentation/bloc/trophy_room_cubit.dart';
import 'package:vowl/features/profile/presentation/widgets/trophy_dossier_sheet.dart';
import 'package:vowl/features/profile/presentation/widgets/trophy_medallion_artwork.dart';

/// Hero showcase displaying the user's top 3 crowning achievements
/// on floating 3D frosted-glass pedestals with ambient illumination.
class TrophyHeroShowcase extends StatelessWidget {
  /// Pinned badge identifiers (up to 3).
  final List<String> pinnedBadgeIds;

  /// Authenticated user entity.
  final UserEntity? user;

  /// Callback when a badge's pinned state is toggled.
  final void Function(String badgeId) onTogglePin;

  const TrophyHeroShowcase({
    super.key,
    required this.pinnedBadgeIds,
    this.user,
    required this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppColors.slate200);

    final cardBgColor = isMidnight
        ? AppColors.midnightSurface
        : (isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.85)
            : Colors.white);

    // Arrange slots: [Left (Index 1), Center (Index 0 - Main), Right (Index 2)]
    final mainBadgeId = pinnedBadgeIds.isNotEmpty ? pinnedBadgeIds[0] : null;
    final leftBadgeId = pinnedBadgeIds.length > 1 ? pinnedBadgeIds[1] : null;
    final rightBadgeId = pinnedBadgeIds.length > 2 ? pinnedBadgeIds[2] : null;

    return GlassTile(
      blur: 0,
      color: cardBgColor,
      borderRadius: BorderRadius.circular(18.r),
      borderColor: borderColor,
      showShadow: !isDark,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 5.r,
                height: 5.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'FEATURED TROPHIES',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.slate900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                'Your Highlights',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 8.5.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : AppColors.slate500,
                ),
              ),
            ],
          ),

          SizedBox(height: 6.h),

          // 3 Floating Showcase Slots Layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Left Slot (Rank #2)
              Expanded(
                child: _buildPedestalSlot(
                  context: context,
                  badgeId: leftBadgeId,
                  rankLabel: '#2',
                  heightMultiplier: 0.85,
                  isMain: false,
                  isDark: isDark,
                  borderColor: borderColor,
                ),
              ),
              SizedBox(width: 8.w),

              // Center Slot (Rank #1 - Featured)
              Expanded(
                child: _buildPedestalSlot(
                  context: context,
                  badgeId: mainBadgeId,
                  rankLabel: '#1',
                  heightMultiplier: 1.0,
                  isMain: true,
                  isDark: isDark,
                  borderColor: borderColor,
                ),
              ),
              SizedBox(width: 8.w),

              // Right Slot (Rank #3)
              Expanded(
                child: _buildPedestalSlot(
                  context: context,
                  badgeId: rightBadgeId,
                  rankLabel: '#3',
                  heightMultiplier: 0.75,
                  isMain: false,
                  isDark: isDark,
                  borderColor: borderColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPedestalSlot({
    required BuildContext context,
    required String? badgeId,
    required String rankLabel,
    required double heightMultiplier,
    required bool isMain,
    required bool isDark,
    required Color borderColor,
  }) {
    if (badgeId == null) {
      return _buildEmptyDais(rankLabel, isDark, borderColor);
    }

    final metadata = TrophyMetadata.forId(badgeId);
    final canonical = TrophyRoomCubit.canonicalizeBadgeId(badgeId);
    final parts = canonical.split('_');
    final tier = parts.isNotEmpty ? parts[0].toUpperCase() : 'NOVICE';
    final category = parts.length > 1 ? parts.sublist(1).join(' ').toUpperCase() : metadata.category.toUpperCase();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Haptics.vibrate(HapticsType.light);
        TrophyDossierSheet.show(
          context: context,
          metadata: metadata,
          isEarned: true,
          user: user,
          isPinned: true,
          onTogglePin: () => onTogglePin(badgeId),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Crown Label / Tier
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              tier,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: isMain ? 8.5.sp : 8.sp,
                fontWeight: FontWeight.w900,
                color: isMain
                    ? AppColors.gold
                    : (isDark ? Colors.white70 : AppColors.slate700),
                letterSpacing: 1.0,
              ),
            ),
          ),
          SizedBox(height: 3.h),

          // Medallion Artwork
          TrophyMedallionArtwork(
            metadata: metadata,
            isEarned: true,
            size: isMain ? 38.0 : 32.0,
          ),

          SizedBox(height: 3.h),

          // Category
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              category,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: isMain ? 9.5.sp : 8.5.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),
          ),

          SizedBox(height: 3.h),

          // Glowing Pedestal Base
          Container(
            height: (7 * heightMultiplier).h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.r),
              color: isMain
                  ? AppColors.gold
                  : (isDark ? const Color(0xFF1E293B) : AppColors.slate300),
              boxShadow: [
                if (isMain)
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDais(String rankLabel, bool isDark, Color borderColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          rankLabel,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 8.sp,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white30 : Colors.black26,
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          width: 44.r,
          height: 44.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              style: BorderStyle.solid,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.add_rounded,
              color: isDark ? Colors.white24 : Colors.black26,
              size: 20.r,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Empty Slot',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 8.5.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white30 : Colors.black38,
          ),
        ),
        SizedBox(height: 4.h),
        Container(
          height: 7.h,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.r),
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.04),
          ),
        ),
      ],
    );
  }
}
