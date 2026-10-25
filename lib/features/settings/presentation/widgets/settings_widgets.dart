import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/presentation/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/features/settings/presentation/widgets/settings_dialogs.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:auto_size_text/auto_size_text.dart';

// ---------------------------------------------------------------------------
// SettingsSectionTitle
// ---------------------------------------------------------------------------

/// Section title label with optional subtle accent color and divider spacing.
class SettingsSectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  final Color? tintColor;

  const SettingsSectionTitle({
    super.key,
    required this.title,
    required this.isDark,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        tintColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.5)
            : AppColors.slate900.withValues(alpha: 0.4));
    return Padding(
      padding: EdgeInsets.only(left: 8.w, bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: effectiveColor,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            height: 0.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  effectiveColor.withValues(alpha: 0.3),
                  effectiveColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SettingsGroup
// ---------------------------------------------------------------------------

/// Card container grouping a list of settings tiles with subtle dividers.
class SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const SettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassTile(
      borderRadius: BorderRadius.circular(28.r),
      blur: 0,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Padding(
                padding: EdgeInsets.only(left: 62.w),
                child: Divider(
                  height: 0.5,
                  thickness: 0.5,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SettingsTile
// ---------------------------------------------------------------------------

/// Standard interactive list row with an icon, title, subtitle, and trailing widget.
class SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isDestructive;

  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
    this.trailing,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      // FIX (HIGH-5): Each settings tile now has a proper accessibility label
      // and is marked as a button so TalkBack/VoiceOver users can identify
      // and activate it correctly.
      label: title,
      button: onTap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(icon, color: color, size: 20.r),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        title,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: isDestructive
                              ? Colors.red
                              : (Theme.of(context).colorScheme.onSurface),
                        ),
                        maxLines: 1,
                        minFontSize: 11,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 4.h),
                        AutoSizeText(
                          subtitle!,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            height: 1.3,
                            color: isDark ? Colors.white54 : Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                          minFontSize: 9,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null || onTap != null) SizedBox(width: 16.w),
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SettingsSwitchTile
// ---------------------------------------------------------------------------

/// Toggle switch row item supporting asynchronous loading indicators.
class SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool value;
  final bool isLoading;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.value,
    this.isLoading = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      // FIX (HIGH-5): Switch tiles now announce their on/off state.
      label: '$title. $subtitle',
      toggled: value,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading
              ? null
              : () {
                  di.sl<HapticService>().light();
                  onChanged(!value);
                },
          borderRadius: BorderRadius.circular(24.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(icon, color: color, size: 20.r),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AutoSizeText(
                        title,
                        maxLines: 1,
                        minFontSize: 11,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      AutoSizeText(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          height: 1.3,
                          color: isDark ? Colors.white54 : Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 2,
                        minFontSize: 9,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                if (isLoading)
                  SizedBox(
                    width: 50.w,
                    height: 30.h,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                    ),
                  )
                else
                  ExcludeSemantics(
                    // The parent Semantics already announces toggled state.
                    child: Switch.adaptive(
                      value: value,
                      onChanged: (val) {
                        di.sl<HapticService>().light();
                        onChanged(val);
                      },
                      activeThumbColor: AppColors.indigo500,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SettingsLogoutButton
// ---------------------------------------------------------------------------

/// Styled action button that presents the account sign-out confirmation dialog.
class SettingsLogoutButton extends StatelessWidget {
  const SettingsLogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.tr('settings.sign_out', fallback: 'SIGN OUT ACCOUNT'),
      button: true,
      child: Container(
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
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.withValues(alpha: 0.12),
                  Colors.red.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => SettingsDialogs.showLogout(context),
                borderRadius: BorderRadius.circular(24.r),
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
                      Flexible(
                        child: AutoSizeText(
                          context.tr(
                            'settings.sign_out',
                            fallback: 'SIGN OUT ACCOUNT',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          minFontSize: 8,
                          overflow: TextOverflow.ellipsis,
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
    );
  }
}

// ---------------------------------------------------------------------------
// SettingsProfileSection
// ---------------------------------------------------------------------------

/// Header card displaying user profile information, avatar, and edit profile action.
class SettingsProfileSection extends StatelessWidget {
  final UserEntity? user;
  final bool isDark;

  const SettingsProfileSection({
    super.key,
    required this.user,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = user;
    if (currentUser == null) return const SizedBox.shrink();

    return Semantics(
      label:
          '${currentUser.displayName ?? context.tr('settings.explorer', fallback: 'Explorer')}. '
          '${currentUser.email}. '
          '${currentUser.isPremium ? context.tr('settings.premium_quester', fallback: 'PREMIUM QUESTER') : context.tr('settings.free_account', fallback: 'FREE ACCOUNT')}. '
          '${context.tr("settings.tap_to_edit_profile", fallback: "Tap to edit profile")}',
      button: true,
      child: GlassTile(
        padding: EdgeInsets.all(24.r),
        borderRadius: BorderRadius.circular(32.r),
        blur: 0,
        child: Row(
          children: [
            // Avatar with edit overlay
            GestureDetector(
              onTap: () =>
                  SettingsDialogs.showEditProfile(context, currentUser),
              child: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.all(3.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (currentUser.isPremium
                                      ? AppColors.amber500
                                      : AppColors.slate500)
                                  .withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                      gradient: LinearGradient(
                        colors: currentUser.isPremium
                            ? [
                                AppColors.amber500,
                                AppColors.amber500.withValues(alpha: 0.2),
                              ]
                            : [
                                AppColors.slate500,
                                AppColors.slate500.withValues(alpha: 0.2),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: UserAvatar(
                      photoUrl: currentUser.photoUrl,
                      size: 72.r,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(7.r),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: currentUser.isPremium
                              ? [AppColors.amber500, AppColors.amber600]
                              : [AppColors.slate500, AppColors.slate600],
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
            // Name + email + plan badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    // FIX (HIGH-2): Hardcoded 'Explorer' fallback now localised.
                    currentUser.displayName ??
                        context.tr('settings.explorer', fallback: 'Explorer'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    minFontSize: 14,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AutoSizeText(
                    currentUser.email,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      color: isDark
                          ? Colors.white54
                          : AppColors.slate900.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    minFontSize: 10,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 12.h),
                  Builder(
                    builder: (context) {
                      final badgeColor = currentUser.isPremium
                          ? AppColors.amber500
                          : AppColors.slate500;
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: badgeColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              currentUser.isPremium
                                  ? Icons.workspace_premium_rounded
                                  : Icons.person_outline_rounded,
                              color: badgeColor,
                              size: 12.r,
                            ),
                            SizedBox(width: 6.w),
                            Flexible(
                              child: AutoSizeText(
                                currentUser.isPremium
                                    ? context.tr(
                                        'settings.premium_quester',
                                        fallback: 'PREMIUM QUESTER',
                                      )
                                    : context.tr(
                                        'settings.free_account',
                                        fallback: 'FREE ACCOUNT',
                                      ),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w900,
                                  color: badgeColor,
                                  letterSpacing: 1,
                                ),
                                maxLines: 1,
                                minFontSize: 6,
                                overflow: TextOverflow.ellipsis,
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
          ],
        ),
      ),
    );
  }
}
