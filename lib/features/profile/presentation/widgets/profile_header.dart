import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_image.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:auto_size_text/auto_size_text.dart';

class ProfileHeader extends StatelessWidget {
  final UserEntity user;
  final VoidCallback onEditName;
  final VoidCallback onEditPhoto;

  /// When non-null, takes priority over [user.photoUrl] — used to display the
  /// freshly-uploaded profile picture immediately after a successful upload,
  /// before the Firestore user-stream round-trip completes.
  final String? immediatePhotoUrl;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.onEditName,
    required this.onEditPhoto,
    this.immediatePhotoUrl,
  });

  /// Returns a human-readable rank title based on the user's level.
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
    final isPremium = user.isPremium;
    final glowColor = isPremium
        ? const Color(0xFFF59E0B)
        : const Color(0xFF6366F1);

    // XP progress within current level (0.0 - 1.0)
    final xpProgress = (user.totalExp % 100) / 100;

    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              // Level progress ring around avatar
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: isPremium ? 0.4 : 0.1),
                      blurRadius: isPremium ? 40 : 30,
                      spreadRadius: isPremium ? 2 : 0,
                      offset: const Offset(0, 10),
                    ),
                    if (user.level >= 200)
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                  ],
                ),
                child: SizedBox(
                  width: 132.r,
                  height: 132.r,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // XP progress ring
                      SizedBox(
                        width: 132.r,
                        height: 132.r,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: xpProgress),
                          duration: const Duration(milliseconds: 1500),
                          curve: Curves.easeOutCubic,
                          onEnd: () {
                            if (xpProgress > 0) {
                              di.sl<HapticService>().light();
                            }
                          },
                          builder: (context, value, child) {
                            return CircularProgressIndicator(
                              value: value,
                              strokeWidth: 3.5,
                              strokeCap: StrokeCap.round,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.06),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(glowColor),
                            );
                          },
                        ),
                      ),
                      // Avatar
                      Hero(
                        tag: 'profile_pic',
                        child: Container(
                          width: 118.r,
                          height: 118.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (isPremium || user.level >= 200)
                                  ? const Color(0xFFF59E0B)
                                  : Colors.transparent,
                              width: 3.r,
                            ),
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : const Color(0xFFF1F5F9),
                          ),
                          child: ClipOval(
                            child: (immediatePhotoUrl ?? user.photoUrl) != null
                                ? ((immediatePhotoUrl ?? user.photoUrl)!.startsWith('http')
                                    ? ShimmerImage(
                                        imageUrl:
                                            (immediatePhotoUrl ?? user.photoUrl)!,
                                      )
                                    : Image.file(
                                        File((immediatePhotoUrl ?? user.photoUrl)!),
                                        fit: BoxFit.cover,
                                        width: 118.r,
                                        height: 118.r,
                                      ))
                                : Icon(
                                    Icons.person_rounded,
                                    color: const Color(0xFF94A3B8),
                                    size: 60.r,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 5.h,
                right: 5.w,
                // ACCESSIBILITY FIX: the original badge was an ~32dp tap
                // target (8r padding + 16r icon), under the 48x48dp
                // minimum. Wrapping it in a 48x48 SizedBox + Center
                // expands the *tappable* area to the accessible minimum
                // while keeping the *visible* badge exactly the same
                // size/position it was designed at.
                child: SizedBox(
                  width: 48.r,
                  height: 48.r,
                  child: Center(
                    child: Semantics(
                      button: true,
                      label: isPremium
                          ? context.tr(
                              'profile.edit_photo_premium',
                              fallback: 'Edit Photo (Premium)',
                            )
                          : context.tr(
                              'profile.edit_photo',
                              fallback: 'Edit Photo',
                            ),
                      child: ScaleButton(
                        onTap: () {
                          di.sl<HapticService>().light();
                          onEditPhoto();
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: glowColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            isPremium
                                ? Icons.star_rounded
                                : Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16.r,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        Center(
          child: ConstrainedBox(
            // RESPONSIVENESS FIX: bounds the name pill so an unusually
            // long display name can ellipsize instead of forcing the Row
            // wider than the screen (horizontal overflow).
            constraints: BoxConstraints(maxWidth: 0.85.sw),
            child: ScaleButton(
              onTap: () {
                di.sl<HapticService>().selection();
                onEditName();
              },
              child: GlassTile(
                borderRadius: BorderRadius.circular(20.r),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: AutoSizeText(
                        user.displayName ??
                            context.tr(
                              'profile.default_name',
                              fallback: 'Explorer',
                            ),
                        maxLines: 1,
                        minFontSize: 18,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    // Rank badge showing actual level rank
                    Builder(
                      builder: (context) {
                        final badgeColor = isPremium
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF6366F1);
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: badgeColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shield_rounded,
                                color: badgeColor,
                                size: 10.r,
                              ),
                              SizedBox(width: 4.w),
                              Flexible(
                                child: AutoSizeText(
                                  _getRankTitle(context, user.level),
                                  maxLines: 1,
                                  minFontSize: 6,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w900,
                                    color: badgeColor,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 6.h),
        // Level indicator
        Center(
          child: Text(
            context.tr(
              'profile.level_label',
              fallback: 'Level {0}',
              args: ['${user.level}'],
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: glowColor.withValues(alpha: 0.8),
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isPremium) ...[
                Icon(
                  Icons.verified_rounded,
                  color: const Color(0xFFF59E0B),
                  size: 16.r,
                ),
                SizedBox(width: 4.w),
                AutoSizeText(
                  context.tr(
                    'profile.premium_member_badge',
                    fallback: 'Premium Member',
                  ),
                  maxLines: 1,
                  minFontSize: 6,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    color: const Color(0xFFF59E0B),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  width: 4.r,
                  height: 4.r,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8.w),
              ],
              // RESPONSIVENESS FIX: the email can be long; Flexible +
              // ellipsis keeps this row from overflowing horizontally on
              // small screens instead of clipping past the edge.
              Flexible(
                child: Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
