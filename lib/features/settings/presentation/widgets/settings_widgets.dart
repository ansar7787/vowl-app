import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/features/settings/presentation/widgets/settings_dialogs.dart';

class SettingsSectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;

  const SettingsSectionTitle({
    super.key,
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w, bottom: 12.h),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 13.sp,
          fontWeight: FontWeight.w900,
          color: isDark
              ? Colors.white.withValues(alpha: 0.6)
              : const Color(0xFF0F172A).withValues(alpha: 0.5),
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}

class SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const SettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      borderRadius: BorderRadius.circular(28.r),
      child: Column(children: children),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isDestructive;

  const SettingsTile({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    this.onTap,
    this.trailing,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: color, size: 20.r),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: isDestructive
                        ? Colors.red
                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14.r,
                  color: isDark ? Colors.white24 : Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 20.r),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 11.sp,
                    color: isDark ? Colors.white38 : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: (val) {
              Haptics.vibrate(HapticsType.light);
              onChanged(val);
            },
            activeThumbColor: const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }
}

class SettingsLogoutButton extends StatelessWidget {
  const SettingsLogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.withValues(alpha: 0.1),
                  Colors.red.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => SettingsDialogs.showLogout(context),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          size: 18.r,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Text(
                        'SIGN OUT ACCOUNT',
                        style: GoogleFonts.outfit(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.red,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }
}

class SettingsProfileSection extends StatelessWidget {
  final dynamic user;
  final bool isDark;

  const SettingsProfileSection({
    super.key,
    required this.user,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();

    return GlassTile(
      padding: EdgeInsets.all(24.r),
      borderRadius: BorderRadius.circular(32.r),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => SettingsDialogs.showEditProfile(context, user),
            child: Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(3.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue,
                        Colors.blue.withValues(alpha: 0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 36.r,
                    backgroundColor: const Color(0xFF1E293B),
                    backgroundImage: user.photoUrl != null &&
                            user.photoUrl!.isNotEmpty
                        ? (user.photoUrl!.startsWith('http')
                            ? NetworkImage(user.photoUrl!)
                            : FileImage(File(user.photoUrl!)) as ImageProvider)
                        : null,
                    child: user.photoUrl == null || user.photoUrl!.isEmpty
                        ? Icon(
                            Icons.person_rounded,
                            size: 36.r,
                            color: Colors.white24,
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(7.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue, Colors.blue.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 10.r,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 20.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'Explorer',
                  style: GoogleFonts.outfit(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  user.email,
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    color: isDark
                        ? Colors.white54
                        : const Color(0xFF0F172A).withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: Colors.blue,
                        size: 12.r,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        user.isPremium ? 'PREMIUM QUESTER' : 'FREE ACCOUNT',
                        style: GoogleFonts.outfit(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.blue,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, curve: Curves.easeOut);
  }
}
