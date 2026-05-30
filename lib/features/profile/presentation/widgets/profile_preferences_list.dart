import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class ProfilePreferencesList extends StatelessWidget {
  final UserEntity user;
  final bool soundEnabled;
  final Function(bool value) onSoundToggle;

  const ProfilePreferencesList({
    super.key,
    required this.user,
    required this.soundEnabled,
    required this.onSoundToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassTile(
      borderRadius: BorderRadius.circular(28.r),
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        children: [
          _buildSwitchTile(
            context,
            'Sound Effects',
            Icons.volume_up_rounded,
            Colors.pink,
            soundEnabled,
            onSoundToggle,
          ),
          if (user.isAdmin) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
              indent: 20.w,
              endIndent: 20.w,
            ),
            _buildPreferenceTile(
              context,
              'Admin Dashboard',
              Icons.admin_panel_settings_rounded,
              Colors.orange,
              () {
                Haptics.vibrate(HapticsType.medium);
                context.push(AppRouter.adminRoute);
              },
            ),
          ],
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
            indent: 20.w,
            endIndent: 20.w,
          ),
          _buildPreferenceTile(
            context,
            'Settings',
            Icons.settings_rounded,
            Colors.grey,
            () {
              Haptics.vibrate(HapticsType.medium);
              context.push(AppRouter.settingsRoute);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 22.r),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              size: 20.r,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    bool value,
    ValueChanged<bool>? onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isDisabled = onChanged == null;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 22.r),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: value,
                onChanged: isDisabled
                    ? null
                    : (v) {
                        Haptics.vibrate(HapticsType.selection);
                        onChanged(v);
                      },
                activeThumbColor: color,
                activeTrackColor: color.withValues(alpha: 0.2),
                inactiveThumbColor: isDark ? Colors.white60 : Colors.white,
                inactiveTrackColor: isDark
                    ? Colors.white24
                    : const Color(0xFFE2E8F0),
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
