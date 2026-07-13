import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/utils/locale_service.dart';

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
          if (user.isAdmin) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE2E8F0),
              indent: 20.w,
              endIndent: 20.w,
            ),
            _buildPreferenceTile(
              context,
              context.tr('profile.admin_dashboard', fallback: 'Admin Dashboard', fallback: 'Admin Dashboard'),
              Icons.admin_panel_settings_rounded,
              Colors.orange,
              () {
                di.sl<HapticService>().light();
                context.push(AppRouter.adminRoute);
              },
            ),
          ],
          Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFE2E8F0),
            indent: 20.w,
            endIndent: 20.w,
          ),
          _buildPreferenceTile(
            context,
            context.tr('settings.title', fallback: 'Settings'),
            Icons.settings_rounded,
            Colors.grey,
            () {
              di.sl<HapticService>().light();
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

    return Semantics(
      button: true,
      label: title,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          // ACCESSIBILITY: guarantees the 48dp minimum touch target even
          // if a future short title/compact font scale would otherwise
          // shrink this row below it.
          constraints: BoxConstraints(minHeight: 48.h),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
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
        ),
      ),
    );
  }
}
