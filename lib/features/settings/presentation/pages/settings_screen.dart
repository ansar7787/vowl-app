import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vowl/features/settings/presentation/pages/legal_content_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/features/settings/presentation/widgets/settings_dialogs.dart';
import 'package:vowl/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:vowl/features/settings/presentation/widgets/legal_constants.dart';
import 'package:vowl/core/utils/notification_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '1.0.0';
  String _buildNumber = '1';
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _appVersion = info.version;
      _buildNumber = info.buildNumber;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => _notificationsEnabled = value);
    // Actually enable/disable notifications in the service
    di.sl<NotificationService>().onNotificationPreferenceChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
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
                  padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 120.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SettingsProfileSection(
                        user: context.watch<AuthBloc>().state.user, 
                        isDark: isDark,
                      ),
                      SizedBox(height: 32.h),
                      SettingsSectionTitle(title: 'Account', isDark: isDark),
                      SettingsGroup(children: [
                        SettingsTile(
                          title: 'Security & Password',
                          icon: Icons.lock_person_rounded,
                          color: Colors.blue,
                          onTap: () => SettingsDialogs.showPasswordReset(
                            context, 
                            context.read<AuthBloc>().state.user?.email ?? '',
                          ),
                        ),
                      ]),

                      SizedBox(height: 32.h),
                      SettingsSectionTitle(title: 'App Preferences', isDark: isDark),
                      SettingsGroup(children: [
                        SettingsSwitchTile(
                          title: 'Push Notifications',
                          subtitle: 'Stay updated with daily quests',
                          icon: Icons.notifications_active_rounded,
                          color: Colors.orange,
                          value: _notificationsEnabled,
                          onChanged: _toggleNotifications,
                        ),
                        SettingsTile(
                          title: 'Language Selection',
                          icon: Icons.language_rounded,
                          color: Colors.teal,
                          onTap: () => SettingsDialogs.showComingSoon(context),
                          trailing: Text(
                            'English (US)',
                            style: GoogleFonts.outfit(
                              fontSize: 12.sp,
                              color: Colors.blue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ]),

                      SizedBox(height: 32.h),
                      SettingsSectionTitle(title: 'Support & Legal', isDark: isDark),
                      SettingsGroup(children: [
                        SettingsTile(
                          title: 'Help Center',
                          icon: Icons.help_center_rounded,
                          color: Colors.green,
                          onTap: () => _handleSupportLink(context),
                        ),
                        SettingsTile(
                          title: 'Terms of Service',
                          icon: Icons.description_rounded,
                          color: Colors.blueGrey,
                          onTap: () => _handleLegalLink(context, 'Terms of Service'),
                        ),
                        SettingsTile(
                          title: 'Privacy Policy',
                          icon: Icons.policy_rounded,
                          color: Colors.blueGrey,
                          onTap: () => _handleLegalLink(context, 'Privacy Policy'),
                        ),
                        SettingsTile(
                          title: 'App Version',
                          icon: Icons.info_outline_rounded,
                          color: Colors.grey,
                          trailing: Text(
                            '$_appVersion ($_buildNumber)',
                            style: GoogleFonts.outfit(
                              fontSize: 12.sp,
                              color: isDark ? Colors.white38 : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ]),

                      SizedBox(height: 32.h),
                      SettingsSectionTitle(title: 'Danger Zone', isDark: isDark),
                      SettingsGroup(children: [
                        SettingsTile(
                          title: 'Clear App Cache',
                          icon: Icons.cleaning_services_rounded,
                          color: Colors.amber,
                          onTap: () => _handleClearCache(context),
                        ),
                        SettingsTile(
                          title: 'Delete Account',
                          icon: Icons.delete_forever_rounded,
                          color: Colors.red,
                          onTap: () => SettingsDialogs.showDeleteAccount(context),
                          isDestructive: true,
                        ),
                      ]),

                      SizedBox(height: 40.h),
                      const SettingsLogoutButton(),
                    ],
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
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Settings',
        style: GoogleFonts.outfit(
          fontSize: 22.sp,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Future<void> _handleSupportLink(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support.vowl.app@gmail.com',
      query: _encodeQueryParameters({
        'subject': 'Support Request: Vowl',
        'body': 'Describe your issue here...\n\nApp Version: $_appVersion\nBuild: $_buildNumber',
      }),
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app')),
        );
      }
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  void _handleLegalLink(BuildContext context, String title) {
    final content = title == 'Terms of Service' 
        ? LegalConstants.termsOfService 
        : LegalConstants.privacyPolicy;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LegalContentScreen(title: title, content: content),
      ),
    );
  }

  Future<void> _handleClearCache(BuildContext context) async {
    Haptics.vibrate(HapticsType.light);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cache cleared successfully!',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing cache: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
