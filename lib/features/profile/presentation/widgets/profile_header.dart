import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/user_avatar.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/presentation/utils/vowl_assets.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/constants/user_game_constants.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:auto_size_text/auto_size_text.dart';

/// Sovereign Dossier Hero Identity Card for the Profile screen.
///
/// Features:
/// - Top Row: Unified Insignia Crest (Rank + Level united, never alone) on the left,
///   and Mascot Companion Pod ("BUDDY") on the right.
/// - Centerpiece Identity Runway:
///   - Centered User Avatar with solid circular XP progress ring and camera edit trigger.
///   - Centered Display Name that spans full width and stretches symmetrically outwards,
///     with zero muddy grey boxes and AutoSizeText scaling.
///   - Centered Brand Player ID pill in authentic Vowl Indigo with zero pen icons.
/// - Integrated Progression Tray:
///   - Level target, Total XP count, percentage, and a solid (zero gradient) progress bar.
/// - Wrapped in a [RepaintBoundary] identified by [repaintKey] for high-DPI social flex sharing.
class ProfileHeader extends StatelessWidget {
  /// Current authenticated [user] entity.
  final UserEntity user;

  /// Callback executed when tapping the name or edit button to update identity.
  final VoidCallback onEditName;

  /// Callback executed when tapping the avatar to change photo.
  final VoidCallback onEditPhoto;

  /// Freshly uploaded local photo path before remote stream sync.
  final String? immediatePhotoUrl;

  /// Whether an avatar upload is currently in progress.
  final bool isUploading;

  /// Optional RepaintBoundary key for capturing high-DPI share cards.
  final GlobalKey? repaintKey;

  /// Creates a [ProfileHeader].
  const ProfileHeader({
    super.key,
    required this.user,
    required this.onEditName,
    required this.onEditPhoto,
    this.immediatePhotoUrl,
    this.isUploading = false,
    this.repaintKey,
  });

  /// Returns a localized human-readable rank title based on user level.
  String _getRankTitle(BuildContext context, int level) {
    if (level >= 500) {
      return context.tr('profile.rank_grandmaster', fallback: 'GRANDMASTER');
    } else if (level >= 400) {
      return context.tr('profile.rank_legend', fallback: 'LEGEND');
    } else if (level >= 300) {
      return context.tr('profile.rank_sovereign', fallback: 'SOVEREIGN');
    } else if (level >= 200) {
      return context.tr('profile.rank_master', fallback: 'MASTER');
    } else if (level >= 100) {
      return context.tr('profile.rank_expert', fallback: 'EXPERT');
    } else if (level >= 50) {
      return context.tr('profile.rank_adept', fallback: 'ADEPT');
    } else if (level >= 25) {
      return context.tr('profile.rank_scholar', fallback: 'SCHOLAR');
    } else if (level >= 10) {
      return context.tr('profile.rank_apprentice', fallback: 'APPRENTICE');
    } else {
      return context.tr('profile.rank_explorer', fallback: 'EXPLORER');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final isPremium = user.isPremium;
    final isHighLevel = user.level >= 200;
    final primaryAccent = (isPremium || isHighLevel)
        ? AppColors.amber500
        : AppColors.indigo500;

    final standardBorderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate200);

    // XP progress within current level (0.0 - 1.0)
    final xpProgress =
        ((user.totalExp % UserGameConstants.kXpPerLevel) /
                UserGameConstants.kXpPerLevel)
            .clamp(0.0, 1.0);
    final rankTitle = _getRankTitle(context, user.level);

    final cardContent = GlassTile(
      borderRadius: BorderRadius.circular(24.r),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      blur: 0,
      borderColor: (isPremium || isHighLevel)
          ? primaryAccent.withValues(alpha: 0.3)
          : standardBorderColor,
      borderWidth: 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── 1. Top Row: Unified Insignia Crest (Left) + Mascot Companion Pod (Right) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Unified Insignia Crest: Rank + Level united horizontally, responsive & never overflows!
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: primaryAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: primaryAccent.withValues(alpha: 0.25),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_rounded,
                        color: primaryAccent,
                        size: 13.r,
                      ),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          rankTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w900,
                            color: primaryAccent,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Text(
                          '•',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : AppColors.slate400,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.bolt_rounded,
                        color: AppColors.indigo500,
                        size: 13.r,
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        context
                            .tr(
                              'profile.level_tag',
                              fallback: 'LVL {0}',
                              args: ['${user.level}'],
                            )
                            .toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.indigo500,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),

              // Right: Mascot Companion Pod (Clean solid design, "BUDDY" label, NO "CO-PILOT")
              ScaleButton(
                onTap: () {
                  di.sl<HapticService>().light();
                  context.push(AppRouter.vowlMascotRoute);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.amber500.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.amber500.withValues(alpha: 0.25),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VowlMascot(
                        state: VowlMascotState.happy,
                        size: 22.r,
                        mascotId: user.vowlMascot,
                        accessoryId: user.vowlEquippedAccessory,
                      ),
                      SizedBox(width: 5.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            VowlAssets.getMascotName(
                              user.vowlMascot ?? 'vowl_prime',
                            ).toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 8.5.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.amber500,
                              letterSpacing: 0.8,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            context.tr(
                              'profile.mascot_buddy',
                              fallback: 'BUDDY',
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.slate600,
                              letterSpacing: 0.6,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // ── 2. Centerpiece Identity Runway: Avatar + Symmetrically Centered Name + Brand ID Pill ──
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Clean circular progress indicator (Solid color, NO glow, NO gradient)
                SizedBox(
                  width: 74.r,
                  height: 74.r,
                  child: CircularProgressIndicator(
                    value: xpProgress,
                    strokeWidth: 3.2.r,
                    strokeCap: StrokeCap.round,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.slate200,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
                  ),
                ),
                UserAvatar(
                  photoUrl: immediatePhotoUrl ?? user.photoUrl,
                  size: 62.r,
                  border: Border.all(
                    color: (isPremium || isHighLevel)
                        ? AppColors.amber500
                        : AppColors.indigo500.withValues(alpha: 0.25),
                    width: 2.0.r,
                  ),
                ),
                if (isUploading)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black54,
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: ScaleButton(
                    onTap: () {
                      di.sl<HapticService>().light();
                      onEditPhoto();
                    },
                    child: Container(
                      padding: EdgeInsets.all(5.5.r),
                      decoration: BoxDecoration(
                        color: primaryAccent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).cardColor,
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isPremium
                            ? Icons.star_rounded
                            : Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 11.r,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),

          // Symmetrically Centered Name inside a Sleek Identity Card with a Tiny Filled Brand-Color "EDIT" Pill
          ScaleButton(
            onTap: () {
              di.sl<HapticService>().selection();
              onEditName();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : AppColors.slate50,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.slate200,
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    fit: FlexFit.loose,
                    child: AutoSizeText(
                      (user.displayName != null &&
                              user.displayName!.trim().isNotEmpty)
                          ? user.displayName!.trim()
                          : user.getSafeDisplayName(
                              fallback: context.tr(
                                'profile.default_name',
                                fallback: 'Hero Explorer',
                              ),
                            ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      minFontSize: 13,
                      stepGranularity: 0.5,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.indigo500,
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                    child: Text(
                      context.tr('common.edit', fallback: 'EDIT').toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 8.5.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 18.h),

          // ── 3. Integrated Lower Progression Tray (Solid Brand Color, ZERO Gradients!) ──
          Divider(
            height: 1,
            thickness: 0.5,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.slate200,
          ),
          SizedBox(height: 12.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  context.tr(
                    'profile.progress_to_level',
                    fallback: 'Progress to Level {0}',
                    args: ['${user.level + 1}'],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.slate400 : AppColors.slate600,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                context.tr(
                  'profile.total_xp_compact',
                  fallback: '{0} Total XP',
                  args: ['${user.totalExp}'],
                ),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.slate400 : AppColors.slate600,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '${(xpProgress * 100).toInt()}%',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  color: primaryAccent,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 6.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.slate100,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    height: 6.h,
                    width: constraints.maxWidth * xpProgress,
                    decoration: BoxDecoration(
                      color: primaryAccent, // Solid brand color, NO gradients!
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    if (repaintKey != null) {
      return RepaintBoundary(key: repaintKey, child: cardContent);
    }

    return cardContent;
  }
}
