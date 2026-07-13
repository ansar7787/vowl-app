import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_image.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class ProfileHeader extends StatelessWidget {
  final UserEntity user;
  final VoidCallback onEditName;
  final VoidCallback onEditPhoto;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.onEditName,
    required this.onEditPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPremium = user.isPremium;
    final glowColor = isPremium
        ? const Color(0xFFF59E0B)
        : const Color(0xFF2563EB);

    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: Border.all(
                    color: glowColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
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
                child: Hero(
                  tag: 'profile_pic',
                  child: Container(
                    width: 120.r,
                    height: 120.r,
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
                      child: user.photoUrl != null
                          ? ShimmerImage(imageUrl: user.photoUrl!)
                          : Icon(
                              Icons.person_rounded,
                              color: const Color(0xFF94A3B8),
                              size: 60.r,
                            ),
                    ),
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
                // size/position it was designed at - the badge isn't
                // made visually bigger, only easier to actually hit.
                child: SizedBox(
                  width: 48.r,
                  height: 48.r,
                  child: Center(
                    child: Semantics(
                      button: true,
                      label: isPremium
                          ? context.tr('profile.edit_photo_premium', fallback: 'Edit Photo (Premium)', fallback: 'Edit Photo (Premium)')
                          : context.tr('profile.edit_photo', fallback: 'Edit Photo', fallback: 'Edit Photo'),
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
                      child: Text(
                        user.displayName ?? context.tr('profile.default_name', fallback: 'Explorer', fallback: 'Explorer'),
                        maxLines: 1,
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
                    SizedBox(width: 12.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        context.tr('profile.id_badge', fallback: 'ID Badge', fallback: 'ID Badge'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
                Text(
                  context.tr('profile.premium_member_badge', fallback: 'Premium Member', fallback: 'Premium Member'),
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
