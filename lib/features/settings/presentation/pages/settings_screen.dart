import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/features/settings/presentation/widgets/settings_dialogs.dart';
import 'package:vowl/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:vowl/core/utils/notification_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/settings/presentation/widgets/language_picker_sheet.dart';
import 'package:vowl/core/utils/widgets/language_selection_bottom_sheet.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_audio_service.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/age_gate_service.dart';
import 'package:vowl/core/utils/translation_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '1.0.0';
  String _buildNumber = '1';
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _isLoading = true;
  String? _translationLanguageName;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    _loadTranslationLanguageName();
  }

  Future<void> _loadTranslationLanguageName() async {
    final name = await TranslationService().getConfiguredLanguageName();
    if (!mounted) return;
    setState(() => _translationLanguageName = name);
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    final prefs = await SharedPreferences.getInstance();
    final isGranted = await Permission.notification.isGranted;
    final savedPref = prefs.getBool('notifications_enabled') ?? true;
    final soundPref = prefs.getBool('sound_enabled') ?? true;

    if (!mounted) return;
    setState(() {
      _appVersion = info.version;
      _buildNumber = info.buildNumber;
      _notificationsEnabled = savedPref && isGranted;
      _soundEnabled = soundPref;
      _isLoading = false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final isGranted = await Permission.notification.isGranted;
      final isDenied = await Permission.notification.isPermanentlyDenied;
      if (!isGranted) {
        if (isDenied) {
          await openAppSettings();
          return;
        }
        final status = await Permission.notification.request();
        if (!status.isGranted) return;
      }
    } else {
      if (!mounted) return;
      final confirm = await SettingsDialogs.showDisableNotificationConfirmation(
        context,
      );
      if (confirm != true) return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    if (!mounted) return;
    setState(() => _notificationsEnabled = value);
    di.sl<NotificationService>().onNotificationPreferenceChanged(value);
  }

  Future<void> _toggleSound(bool value) async {
    if (!value) {
      if (!mounted) return;
      final confirmed = await SettingsDialogs.showDisableSoundConfirmation(
        context,
      );
      if (confirmed != true) return;
    }

    setState(() => _soundEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);
    di.sl<SoundService>().setMuted(!value);

    if (!value) {
      await di.sl<KidsAudioService>().stopBgm();
      await di.sl<KidsTTSService>().stop();
    }
  }

  Future<void> _handleSupportLink(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support.vowl.app@gmail.com',
      query: _encodeQueryParameters({
        'subject': 'Support Request: Vowl',
        'body':
            'Describe your issue here...\n\nApp Version: $_appVersion\nBuild: $_buildNumber',
      }),
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          message: context.tr('settings.email_error', fallback: 'Email Error'),
          type: CustomSnackBarType.error,
        );
      }
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }

  Future<void> _handleLegalLink(BuildContext context, String title) async {
    final isTerms =
        title ==
        context.tr('settings.terms_of_service', fallback: 'Terms of Service');

    final urlString = isTerms
        ? 'https://ansar7787.github.io/vowl-legal/terms.html'
        : 'https://ansar7787.github.io/vowl-legal/privacy.html';

    final Uri url = Uri.parse(urlString);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          message: context.tr(
            'settings.link_error',
            fallback: 'Could not open link',
          ),
          type: CustomSnackBarType.error,
        );
      }
    }
  }

  Future<void> _handleClearCache(BuildContext context) async {
    di.sl<HapticService>().light();
    try {
      // FIX (CRITICAL-2): Never call SharedPreferences.clear() from a
      // "clear cache" action. User preferences (notifications, sound, locale)
      // are NOT cache — destroying them silently is a critical UX regression.
      //
      // True cache = in-memory image cache + temporary files on disk.
      imageCache.clear();
      imageCache.clearLiveImages();

      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        for (final entity in tempDir.listSync()) {
          try {
            entity.deleteSync(recursive: true);
          } catch (_) {
            // Skip files that are locked or in use.
          }
        }
      }

      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          message: context.tr(
            'settings.cache_cleared',
            fallback: 'Cache Cleared',
          ),
          type: CustomSnackBarType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          message: context.tr(
            'settings.cache_clear_error',
            fallback: 'Error clearing cache',
          ),
          type: CustomSnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // FIX (MEDIUM-1): context.select to scope rebuilds to isMidnight only.
    final isMidnight = context.select<ThemeCubit, bool>(
      (c) => c.state.isMidnight,
    );
    final bgColor = isMidnight
        ? Colors.black
        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          const MeshGradientBackground(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, isDark),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20.w, 10.h, 20.w,
                    MediaQuery.of(context).padding.bottom + 32.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SettingsProfileSection(
                            user: context.watch<AuthBloc>().state.user,
                            isDark: isDark,
                          ),
                          SizedBox(height: 32.h),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // FIX (HIGH-4): Sections extracted to private widgets.
                          _SettingsAccountGroup(isDark: isDark),
                          SizedBox(height: 32.h),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SettingsPreferencesGroup(
                            translationLanguageName: _translationLanguageName,
                            isDark: isDark,
                            soundEnabled: _soundEnabled,
                            notificationsEnabled: _notificationsEnabled,
                            isLoading: _isLoading,
                            onToggleSound: _toggleSound,
                            onToggleNotifications: _toggleNotifications,
                            onTapTranslationLanguage: () async {
                              await LanguageSelectionBottomSheet.show(context);
                              if (!mounted) return;
                              _loadTranslationLanguageName();
                            },
                          ),
                          SizedBox(height: 32.h),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SettingsSupportGroup(
                            isDark: isDark,
                            appVersion: _appVersion,
                            buildNumber: _buildNumber,
                            onSupportTap: () => _handleSupportLink(context),
                            onLegalTap: (title) => _handleLegalLink(context, title),
                          ),
                          SizedBox(height: 32.h),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SettingsDangerGroup(
                            onClearCache: () => _handleClearCache(context),
                          ),
                          SizedBox(height: 40.h),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SettingsLogoutButton(),
                        ],
                      ),
                    ]
                        .animate(interval: 80.ms)
                        .fadeIn(
                          duration: 600.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .scaleXY(
                          begin: 0.95,
                          end: 1.0,
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        )
                        .slideY(
                          begin: 0.05,
                          end: 0,
                          duration: 600.ms,
                          curve: Curves.easeOutCubic,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      centerTitle: true,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC))
                .withValues(alpha: 0.7),
          ),
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16.r,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
      title: Text(
        context.tr('settings.title', fallback: 'Settings'),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 22.sp,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private section widgets
// FIX (HIGH-4): Extracted to bring SettingsScreen under the 300-line limit.
// ---------------------------------------------------------------------------

class _SettingsAccountGroup extends StatelessWidget {
  final bool isDark;
  const _SettingsAccountGroup({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionTitle(
          title: context.tr('settings.account', fallback: 'Account'),
          isDark: isDark,
        ),
        SettingsGroup(
          children: [
            SettingsTile(
              title: context.tr(
                'settings.security_password',
                fallback: 'Security & Password',
              ),
              icon: Icons.lock_person_rounded,
              color: const Color(0xFF3B82F6),
              onTap: () => SettingsDialogs.showPasswordReset(
                context,
                context.read<AuthBloc>().state.user?.email ?? '',
              ),
            ),
            SettingsTile(
              title: context.tr(
                'settings.age_verification',
                fallback: 'Age Verification',
              ),
              icon: Icons.verified_user_rounded,
              color: const Color(0xFF8B5CF6),
              onTap: () async {
                final confirm =
                    await SettingsDialogs.showAgeVerificationReset(context);
                if (confirm == true && context.mounted) {
                  await AgeGateService.resetAgeGate();
                  if (context.mounted) {
                    context.go('/age-gate');
                  }
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsPreferencesGroup extends StatelessWidget {
  final bool isDark;
  final bool soundEnabled;
  final bool notificationsEnabled;
  final bool isLoading;
  final String? translationLanguageName;
  final VoidCallback onTapTranslationLanguage;
  final ValueChanged<bool> onToggleSound;
  final ValueChanged<bool> onToggleNotifications;

  const _SettingsPreferencesGroup({
    required this.isDark,
    required this.soundEnabled,
    required this.notificationsEnabled,
    required this.isLoading,
    required this.translationLanguageName,
    required this.onTapTranslationLanguage,
    required this.onToggleSound,
    required this.onToggleNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionTitle(
          title: context.tr(
            'settings.app_preferences',
            fallback: 'App Preferences',
          ),
          isDark: isDark,
        ),
        SettingsGroup(
          children: [
            SettingsSwitchTile(
              title: context.tr(
                'settings.sound_effects',
                fallback: 'Sound Effects',
              ),
              subtitle: context.tr(
                'settings.sound_effects_subtitle',
                fallback: 'Game sounds and music',
              ),
              icon: Icons.volume_up_rounded,
              color: const Color(0xFFEC4899),
              value: soundEnabled,
              isLoading: isLoading,
              onChanged: onToggleSound,
            ),
            SettingsSwitchTile(
              title: context.tr(
                'settings.push_notifications',
                fallback: 'Push Notifications',
              ),
              subtitle: context.tr(
                'settings.push_notifications_subtitle',
                fallback: 'Daily reminders and alerts',
              ),
              icon: Icons.notifications_active_rounded,
              color: const Color(0xFFF97316),
              value: notificationsEnabled,
              isLoading: isLoading,
              onChanged: onToggleNotifications,
            ),
            if (isDark)
              SettingsSwitchTile(
                title: context.tr(
                  'settings.midnight_mode',
                  fallback: 'Midnight Mode',
                ),
                subtitle: context.tr(
                  'settings.midnight_mode_subtitle',
                  fallback: 'True black background for OLED screens',
                ),
                icon: Icons.nightlight_round,
                color: const Color(0xFF6366F1),
                value: context.watch<ThemeCubit>().state.isMidnight,
                isLoading: false,
                onChanged: (val) =>
                    context.read<ThemeCubit>().toggleMidnight(val),
              ),
            SettingsTile(
              title: context.tr(
                'settings.language_selection',
                fallback: 'Language Selection',
              ),
              icon: Icons.language_rounded,
              color: const Color(0xFF14B8A6),
              onTap: () => LanguagePickerSheet.show(context),
              trailing: Text(
                '${di.sl<LocaleService>().currentLocaleFlag} '
                '${di.sl<LocaleService>().currentLocaleName}',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  color: const Color(0xFF14B8A6),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SettingsTile(
              title: context.tr(
                'settings.translation_language',
                fallback: 'Translation Language',
              ),
              subtitle: context.tr(
                'settings.translation_language_subtitle',
                fallback: 'Used for hints and explanations in games',
              ),
              icon: Icons.g_translate_rounded,
              color: const Color(0xFFF59E0B),
              onTap: onTapTranslationLanguage,
              trailing: translationLanguageName != null
                  ? Text(
                      translationLanguageName!,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        color: const Color(0xFFF59E0B),
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsSupportGroup extends StatelessWidget {
  final bool isDark;
  final String appVersion;
  final String buildNumber;
  final VoidCallback onSupportTap;
  final ValueChanged<String> onLegalTap;

  const _SettingsSupportGroup({
    required this.isDark,
    required this.appVersion,
    required this.buildNumber,
    required this.onSupportTap,
    required this.onLegalTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionTitle(
          title: context.tr(
            'settings.support_legal',
            fallback: 'Support & Legal',
          ),
          isDark: isDark,
        ),
        SettingsGroup(
          children: [
            SettingsTile(
              title: context.tr(
                'settings.help_center',
                fallback: 'Help Center',
              ),
              icon: Icons.help_center_rounded,
              color: const Color(0xFF10B981),
              onTap: onSupportTap,
            ),
            SettingsTile(
              title: context.tr(
                'settings.terms_of_service',
                fallback: 'Terms of Service',
              ),
              icon: Icons.description_rounded,
              color: const Color(0xFF64748B),
              onTap: () => onLegalTap(
                context.tr(
                  'settings.terms_of_service',
                  fallback: 'Terms of Service',
                ),
              ),
            ),
            SettingsTile(
              title: context.tr(
                'settings.privacy_policy',
                fallback: 'Privacy Policy',
              ),
              icon: Icons.policy_rounded,
              color: const Color(0xFF94A3B8),
              onTap: () => onLegalTap(
                context.tr(
                  'settings.privacy_policy',
                  fallback: 'Privacy Policy',
                ),
              ),
            ),
            SettingsTile(
              title: context.tr(
                'settings.app_version',
                fallback: 'App Version',
              ),
              icon: Icons.info_outline_rounded,
              color: const Color(0xFF9CA3AF),
              trailing: Text(
                '$appVersion ($buildNumber)',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  color: isDark ? Colors.white38 : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsDangerGroup extends StatelessWidget {
  final VoidCallback onClearCache;

  const _SettingsDangerGroup({required this.onClearCache});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionTitle(
          title: context.tr('settings.danger_zone', fallback: 'Danger Zone'),
          isDark: isDark,
          tintColor: const Color(0xFFEF4444),
        ),
        SettingsGroup(
          children: [
            SettingsTile(
              title: context.tr(
                'settings.clear_cache',
                fallback: 'Clear Cache',
              ),
              icon: Icons.cleaning_services_rounded,
              color: const Color(0xFFEAB308),
              onTap: onClearCache,
            ),
            SettingsTile(
              title: context.tr(
                'settings.delete_account',
                fallback: 'Delete Account',
              ),
              icon: Icons.delete_forever_rounded,
              color: const Color(0xFFEF4444),
              onTap: () => SettingsDialogs.showDeleteAccount(context),
              isDestructive: true,
            ),
          ],
        ),
      ],
    );
  }
}
