import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
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
        tintColor ?? (isDark ? Colors.white70 : AppColors.slate700);
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4.w,
            height: 20.h,
            decoration: BoxDecoration(
              color: effectiveColor,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                color: effectiveColor,
                letterSpacing: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate200);

    return GlassTile(
      borderRadius: BorderRadius.circular(24.r),
      borderColor: borderColor,
      borderWidth: 1.0,
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
// SettingsThemeMatrix
// ---------------------------------------------------------------------------

/// Visual 2x2 Bento matrix allowing users to pick System (Auto), Light, Dark,
/// or OLED Midnight appearance with one-tap clarity.
class SettingsThemeMatrix extends StatelessWidget {
  final ThemeState themeState;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<bool> onMidnightChanged;
  final ValueChanged<bool> onSystemThemeChanged;

  const SettingsThemeMatrix({
    super.key,
    required this.themeState,
    required this.onThemeModeChanged,
    required this.onMidnightChanged,
    required this.onSystemThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate200);

    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final isPlatformDark = platformBrightness == Brightness.dark;

    final isSystemActive = themeState.isSystem;
    final isMidnightActive =
        !themeState.isSystem && themeState.isDark && themeState.isMidnight;
    final isDarkActive =
        !themeState.isSystem && themeState.isDark && !themeState.isMidnight;
    final isLightActive = !themeState.isSystem && !themeState.isDark;

    return GlassTile(
      borderRadius: BorderRadius.circular(24.r),
      borderColor: borderColor,
      borderWidth: 1.0,
      blur: 0,
      padding: EdgeInsets.all(AppSpacing.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: System (Auto-sync) & Light ──
          Row(
            children: [
              Expanded(
                child: _ThemeOptionCard(
                  title: context.tr(
                    'settings.theme_system',
                    fallback: 'System',
                  ),
                  subtitle: isSystemActive
                      ? (isPlatformDark
                            ? context.tr(
                                'settings.theme_auto_dark',
                                fallback: 'Auto (Dark)',
                              )
                            : context.tr(
                                'settings.theme_auto_light',
                                fallback: 'Auto (Light)',
                              ))
                      : context.tr(
                          'settings.theme_system_sub',
                          fallback: 'Match Device',
                        ),
                  icon: Icons.brightness_auto_rounded,
                  iconColor: AppColors.blue500,
                  isSelected: isSystemActive,
                  badgeText: isSystemActive
                      ? (isPlatformDark ? 'DARK' : 'LIGHT')
                      : null,
                  onTap: () {
                    di.sl<HapticService>().selection();
                    onSystemThemeChanged(true);
                    onMidnightChanged(false);
                  },
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _ThemeOptionCard(
                  title: context.tr('settings.theme_light', fallback: 'Light'),
                  subtitle: context.tr(
                    'settings.theme_light_sub',
                    fallback: 'Always Bright',
                  ),
                  icon: Icons.light_mode_rounded,
                  iconColor: AppColors.amber500,
                  isSelected: isLightActive,
                  onTap: () {
                    di.sl<HapticService>().selection();
                    onSystemThemeChanged(false);
                    onMidnightChanged(false);
                    onThemeModeChanged(ThemeMode.light);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // ── Row 2: Dark (Slate) & Midnight (OLED) ──
          Row(
            children: [
              Expanded(
                child: _ThemeOptionCard(
                  title: context.tr('settings.theme_dark', fallback: 'Dark'),
                  subtitle: context.tr(
                    'settings.theme_dark_sub',
                    fallback: 'Deep Slate',
                  ),
                  icon: Icons.dark_mode_rounded,
                  iconColor: AppColors.indigo400,
                  isSelected: isDarkActive,
                  onTap: () {
                    di.sl<HapticService>().selection();
                    onSystemThemeChanged(false);
                    onMidnightChanged(false);
                    onThemeModeChanged(ThemeMode.dark);
                  },
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _ThemeOptionCard(
                  title: context.tr(
                    'settings.theme_midnight',
                    fallback: 'Midnight',
                  ),
                  subtitle: context.tr(
                    'settings.theme_midnight_sub',
                    fallback: 'Pure OLED Black',
                  ),
                  icon: Icons.nightlight_round,
                  iconColor: Colors.purpleAccent,
                  isSelected: isMidnightActive,
                  badgeText: 'OLED',
                  onTap: () {
                    di.sl<HapticService>().selection();
                    onSystemThemeChanged(false);
                    onThemeModeChanged(ThemeMode.dark);
                    onMidnightChanged(true);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // ── Live Status Banner ──
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSystemActive ? Icons.sync_rounded : Icons.tune_rounded,
                  size: 15.r,
                  color: isSystemActive
                      ? AppColors.blue500
                      : (isDark ? Colors.white60 : AppColors.slate600),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    isSystemActive
                        ? context.tr(
                            'settings.theme_status_system',
                            fallback:
                                'Automatically syncing with device settings ({0})',
                            args: [isPlatformDark ? 'Dark Mode' : 'Light Mode'],
                          )
                        : context.tr(
                            'settings.theme_status_manual',
                            fallback:
                                'Manual appearance locked. Tap System to re-sync.',
                          ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : AppColors.slate700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final String? badgeText;
  final VoidCallback onTap;

  const _ThemeOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
    this.badgeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate200);

    return ScaleButton(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.indigo500.withValues(alpha: isDark ? 0.20 : 0.10)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isSelected ? AppColors.indigo500 : borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.indigo500.withValues(
                      alpha: isDark ? 0.25 : 0.15,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(7.r),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(icon, color: iconColor, size: 20.r),
                ),
                if (isSelected)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.indigo500,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 11.r,
                        ),
                        if (badgeText != null) ...[
                          SizedBox(width: 3.w),
                          Text(
                            badgeText!,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                else if (badgeText != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      badgeText!,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white60 : AppColors.slate600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.5.sp,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.slate900)
                    : (isDark ? Colors.white70 : AppColors.slate700),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? AppColors.indigo500
                    : (isDark ? Colors.white38 : AppColors.slate400),
              ),
            ),
          ],
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
  final String? email;

  const SettingsLogoutButton({super.key, this.email});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.tr('settings.sign_out', fallback: 'SIGN OUT ACCOUNT'),
      button: true,
      child: SizedBox(
        width: double.infinity,
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
                width: 1.0,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  di.sl<HapticService>().warning();
                  SettingsDialogs.showLogout(context);
                },
                borderRadius: BorderRadius.circular(24.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 18.h,
                    horizontal: 16.w,
                  ),
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
                      SizedBox(width: 14.w),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AutoSizeText(
                              context.tr(
                                'settings.sign_out',
                                fallback: 'SIGN OUT ACCOUNT',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.red,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              minFontSize: 10,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (email != null && email!.trim().isNotEmpty) ...[
                              SizedBox(height: 2.h),
                              Text(
                                email!.trim(),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red.withValues(alpha: 0.75),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
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
        padding: EdgeInsets.all(AppSpacing.cardSpacious),
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
