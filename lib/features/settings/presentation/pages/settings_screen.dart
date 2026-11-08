import 'dart:async';
import 'dart:io';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/settings/presentation/widgets/settings_dialogs.dart';
import 'package:vowl/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:vowl/core/presentation/widgets/loading_overlay.dart';
import 'package:vowl/core/utils/notification_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/settings/presentation/widgets/language_picker_sheet.dart';
import 'package:vowl/core/utils/widgets/language_selection_bottom_sheet.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/age_gate_service.dart';
import 'package:vowl/core/utils/translation_service.dart';
import 'package:vowl/core/utils/tts_voice_helper.dart';
import 'package:vowl/features/settings/presentation/widgets/tts_voice_selection_bottom_sheet.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color9ca3af = Color(0xFF9CA3AF);
  static const Color coloreab308 = Color(0xFFEAB308);
}

/// Central settings and user preferences configuration screen.
///
/// Features a streamlined Command Center architecture:
/// - 3-Way Theme Matrix (Light, Dark, OLED Midnight) + System Sync.
/// - Audio & Speech Studio with inline TTS Voice Audition.
/// - Unified Dual-Language card (App Interface + Game Translation).
/// - Accessibility and Motion optimization.
/// - Live Cache calculation in MB with instant one-tap purge.
/// - Zero profile card redundancy with explicit account sign-out.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersionVal = '1.0.0';
  String _buildNumberVal = '1';
  bool _notificationsEnabledVal = true;
  bool _soundEnabledVal = true;
  bool _gameSoundsEnabledVal = true;
  bool _hapticsEnabledVal = true;
  bool _reduceComplexGesturesVal = false;
  bool _lowAnimationModeVal = false;
  bool _analyticsEnabledVal = true;
  bool _isLoadingVal = true;
  double? _cacheSizeMB;
  bool _isPlayingVoice = false;
  String? _translationLanguageNameVal;
  TtsVoicePreset _voicePresetVal = TtsVoicePreset.clearGuide;
  bool _hasPlayedEntranceAnimation = false;

  late final ValueNotifier<int> _stateHash = ValueNotifier(0);

  void _updateState() {
    _stateHash.value++;
  }

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    _loadTranslationLanguageName();
    _calculateCacheSize();
  }

  @override
  void dispose() {
    if (_isPlayingVoice && di.sl.isRegistered<TtsService>()) {
      unawaited(di.sl<TtsService>().stop());
    }
    _stateHash.dispose();
    super.dispose();
  }

  Future<void> _loadTranslationLanguageName() async {
    final name = await TranslationService().getConfiguredLanguageName();
    if (!mounted) return;
    _translationLanguageNameVal = name;
    _updateState();
  }

  Future<void> _calculateCacheSize() async {
    try {
      double totalBytes = imageCache.currentSizeBytes.toDouble();

      // 1. Scan OS Temporary Directory
      try {
        final tempDir = await getTemporaryDirectory();
        if (tempDir.existsSync()) {
          for (final entity in tempDir.listSync(recursive: true)) {
            if (entity is File) {
              try {
                totalBytes += entity.lengthSync();
              } catch (_) {}
            }
          }
        }
      } catch (_) {}

      // 2. Scan Application Cache Directory (where cached images & disk assets live)
      try {
        final appCacheDir = await getApplicationCacheDirectory();
        if (appCacheDir.existsSync()) {
          for (final entity in appCacheDir.listSync(recursive: true)) {
            if (entity is File) {
              try {
                totalBytes += entity.lengthSync();
              } catch (_) {}
            }
          }
        }
      } catch (_) {}

      // 3. Scan Application Support Cache Directory if present
      try {
        final appSupportDir = await getApplicationSupportDirectory();
        final cacheSub = Directory('${appSupportDir.path}/cache');
        if (cacheSub.existsSync()) {
          for (final entity in cacheSub.listSync(recursive: true)) {
            if (entity is File) {
              try {
                totalBytes += entity.lengthSync();
              } catch (_) {}
            }
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _cacheSizeMB = totalBytes / (1024 * 1024);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    final prefs = await SharedPreferences.getInstance();
    final isGranted = await Permission.notification.isGranted;
    final savedPref = prefs.getBool('notifications_enabled') ?? true;
    final soundPref = prefs.getBool('sound_enabled') ?? true;
    final gameSoundsPref = prefs.getBool('game_sounds_enabled') ?? true;
    final hapticsPref = prefs.getBool('haptics_enabled') ?? true;
    final gesturesPref = prefs.getBool('reduce_complex_gestures') ?? false;
    final lowAnimationPref = prefs.getBool('low_animation_mode') ?? false;
    final analyticsPref = prefs.getBool('analytics_enabled') ?? true;
    final voicePreset = await TtsVoiceHelper.getSavedPreset();

    if (!mounted) return;
    _appVersionVal = info.version;
    _buildNumberVal = info.buildNumber;
    _notificationsEnabledVal = savedPref && isGranted;
    _soundEnabledVal = soundPref;
    _gameSoundsEnabledVal = gameSoundsPref;
    _hapticsEnabledVal = hapticsPref;
    _reduceComplexGesturesVal = gesturesPref;
    _lowAnimationModeVal = lowAnimationPref;
    _analyticsEnabledVal = analyticsPref;
    _voicePresetVal = voicePreset;
    _isLoadingVal = false;
    _updateState();
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final isDenied = await Permission.notification.isPermanentlyDenied;
      if (isDenied) {
        await openAppSettings();
        return;
      }
      final bool isGranted;
      if (di.sl.isRegistered<NotificationService>()) {
        isGranted = await di.sl<NotificationService>().requestPermissions();
      } else {
        final status = await Permission.notification.request();
        isGranted = status.isGranted;
      }
      if (!isGranted) return;
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
    _notificationsEnabledVal = value;
    _updateState();
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

    _soundEnabledVal = value;
    _updateState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);
    di.sl<SoundService>().setMuted(!value);

    if (!value && di.sl.isRegistered<TtsService>()) {
      await di.sl<TtsService>().stop();
      if (_isPlayingVoice) {
        setState(() => _isPlayingVoice = false);
      }
    }
  }

  Future<void> _toggleGameSounds(bool value) async {
    _gameSoundsEnabledVal = value;
    _updateState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('game_sounds_enabled', value);
    di.sl<SoundService>().setGameSoundsEnabled(value);
  }

  Future<void> _toggleHaptics(bool value) async {
    _hapticsEnabledVal = value;
    _updateState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptics_enabled', value);
    if (di.sl.isRegistered<HapticService>()) {
      di.sl<HapticService>().isHapticsEnabled = value;
      if (value) {
        di.sl<HapticService>().light();
      }
    }
  }

  Future<void> _toggleGestures(bool value) async {
    _reduceComplexGesturesVal = value;
    _updateState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reduce_complex_gestures', value);
  }

  Future<void> _toggleLowAnimationMode(bool value) async {
    _lowAnimationModeVal = value;
    _updateState();
    VowlMotion.lowAnimationModeOverride.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('low_animation_mode', value);
  }

  Future<void> _toggleAnalytics(bool value) async {
    _analyticsEnabledVal = value;
    _updateState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('analytics_enabled', value);
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(value);
  }

  Future<void> _testVoicePreset() async {
    di.sl<HapticService>().light();
    if (_isPlayingVoice) {
      if (di.sl.isRegistered<TtsService>()) {
        await di.sl<TtsService>().stop();
      }
      if (mounted) {
        setState(() => _isPlayingVoice = false);
      }
      return;
    }

    setState(() => _isPlayingVoice = true);
    try {
      if (di.sl.isRegistered<TtsService>()) {
        await di.sl<TtsService>().previewPreset(
          _voicePresetVal,
          onDone: () {
            if (mounted) setState(() => _isPlayingVoice = false);
          },
          onError: (_) {
            if (mounted) setState(() => _isPlayingVoice = false);
          },
        );
      } else {
        if (mounted) setState(() => _isPlayingVoice = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isPlayingVoice = false);
    }
  }

  Future<void> _handleSupportLink(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support.vowl.app@gmail.com',
      query: _encodeQueryParameters({
        'subject': 'Support Request: Vowl',
        'body':
            'Describe your issue here...\n\nApp Version: $_appVersionVal\nBuild: $_buildNumberVal',
      }),
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          message: context.tr(
            'settings.email_error',
            fallback: 'Could not open your email app.',
          ),
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
        ? 'https://vowl-official.github.io/vowl-legal/terms.html'
        : 'https://vowl-official.github.io/vowl-legal/privacy.html';

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
      // 1. Flush in-memory raster image cache
      imageCache.clear();
      imageCache.clearLiveImages();

      // 2. Clear OS Temporary Directory
      try {
        final tempDir = await getTemporaryDirectory();
        if (tempDir.existsSync()) {
          for (final entity in tempDir.listSync()) {
            try {
              entity.deleteSync(recursive: true);
            } catch (_) {}
          }
        }
      } catch (_) {}

      // 3. Clear Application Cache Directory (where cached_network_image stores disk files)
      try {
        final appCacheDir = await getApplicationCacheDirectory();
        if (appCacheDir.existsSync()) {
          for (final entity in appCacheDir.listSync()) {
            try {
              entity.deleteSync(recursive: true);
            } catch (_) {}
          }
        }
      } catch (_) {}

      // 4. Clear Application Support Cache Directory
      try {
        final appSupportDir = await getApplicationSupportDirectory();
        final cacheSub = Directory('${appSupportDir.path}/cache');
        if (cacheSub.existsSync()) {
          for (final entity in cacheSub.listSync()) {
            try {
              entity.deleteSync(recursive: true);
            } catch (_) {}
          }
        }
      } catch (_) {}

      // 5. CRUCIAL: Re-measure the REAL filesystem directly instead of fake 0.0 MB!
      await _calculateCacheSize();

      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          message: context.tr(
            'settings.cache_cleared',
            fallback: 'App cache cleared successfully!',
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
            fallback:
                'We couldn\'t clear the cache right now. Please try again.',
          ),
          type: CustomSnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final themeState = context.watch<ThemeCubit>().state;

    return ValueListenableBuilder<int>(
      valueListenable: _stateHash,
      builder: (context, _, child) {
        return Scaffold(
          backgroundColor: bgColor,
          body: BlocListener<AuthBloc, AuthState>(
            listenWhen: (prev, curr) =>
                curr.message != null && prev.message != curr.message,
            listener: (context, authState) {
              final msg = authState.message!;
              final isWarning =
                  msg.contains('security') || msg.contains('cancelled');
              final isSuccessMsg =
                  msg == 'auth.email_verification_sent' ||
                  msg == 'settings_dialogs.account_deleted_success';
              final isErrorMsg =
                  msg.contains('error') ||
                  msg.contains('failed') ||
                  msg.contains('unreachable') ||
                  msg.contains('invalid');
              CustomSnackBar.show(
                context: context,
                message: context.tr(msg),
                type: isSuccessMsg
                    ? CustomSnackBarType.success
                    : (isErrorMsg ||
                            (authState.status == AuthStatus.unauthenticated &&
                                !isWarning))
                    ? CustomSnackBarType.error
                    : isWarning
                    ? CustomSnackBarType.warning
                    : CustomSnackBarType.info,
              );
              context.read<AuthBloc>().add(const AuthClearMessage());
            },
            child: BlocSelector<AuthBloc, AuthState, bool>(
              selector: (state) => state.status == AuthStatus.loggingOut,
              builder: (context, isLoggingOut) {
                return LoadingOverlay(
                  isLoading: isLoggingOut,
                  message: context.tr(
                    'settings.signing_out_overlay',
                    fallback: 'Signing out...',
                  ),
                  child: Stack(
                    children: [
                      const MeshGradientBackground(),
                      CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          _buildAppBar(context, isDark),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                AppSpacing.screen,
                                16.h,
                                AppSpacing.screen,
                                MediaQuery.of(context).padding.bottom + 40.h,
                              ),
                              child: Builder(
                                builder: (context) {
                                  final user =
                                      context.read<AuthBloc>().state.user;
                                  final contentChildren = <Widget>[
                                    // 1. Appearance & Theme Matrix
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SettingsSectionTitle(
                                          title: context.tr(
                                            'settings.appearance_theme',
                                            fallback: 'Appearance & Theme',
                                          ),
                                          isDark: isDark,
                                        ),
                                        SettingsThemeMatrix(
                                          themeState: themeState,
                                          onThemeModeChanged: (mode) => context
                                              .read<ThemeCubit>()
                                              .toggleTheme(
                                                mode == ThemeMode.dark,
                                              ),
                                          onMidnightChanged: (val) => context
                                              .read<ThemeCubit>()
                                              .toggleMidnight(val),
                                          onSystemThemeChanged: (val) => context
                                              .read<ThemeCubit>()
                                              .toggleSystemTheme(val),
                                        ),
                                        SizedBox(height: 24.h),
                                      ],
                                    ),

                                    // 2. Audio & Speech Studio
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SettingsSectionTitle(
                                          title: context.tr(
                                            'settings.audio_speech_studio',
                                            fallback: 'Audio & Speech Studio',
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
                                                fallback:
                                                    'App audio, buttons & UI feedback',
                                              ),
                                              icon: Icons.volume_up_rounded,
                                              color:
                                                  IllustrationColors
                                                      .vibrantPink,
                                              value: _soundEnabledVal,
                                              isLoading: _isLoadingVal,
                                              onChanged: _toggleSound,
                                            ),
                                            SettingsSwitchTile(
                                              title: context.tr(
                                                'settings.game_sounds',
                                                fallback: 'Celebration Sounds',
                                              ),
                                              subtitle: context.tr(
                                                'settings.game_sounds_subtitle',
                                                fallback:
                                                    'Fanfares, cheers & stage rewards',
                                              ),
                                              icon: Icons.celebration_rounded,
                                              color: AppColors.amber500,
                                              value: _gameSoundsEnabledVal,
                                              isLoading: _isLoadingVal,
                                              onChanged: _toggleGameSounds,
                                            ),
                                            SettingsTile(
                                              title: context.tr(
                                                'settings.pronunciation_voice',
                                                fallback: 'Pronunciation Voice',
                                              ),
                                              subtitle: _voicePresetVal.title,
                                              icon:
                                                  Icons
                                                      .record_voice_over_rounded,
                                              color: AppColors.indigo500,
                                              onTap: () async {
                                                final newPreset =
                                                    await TtsVoiceSelectionBottomSheet.show(
                                                      context,
                                                      currentPreset:
                                                          _voicePresetVal,
                                                    );
                                                if (newPreset != null &&
                                                    mounted) {
                                                  _voicePresetVal = newPreset;
                                                  _updateState();
                                                }
                                              },
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ScaleButton(
                                                    onTap: _testVoicePreset,
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 10.w,
                                                            vertical: 5.h,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: _isPlayingVoice
                                                            ? AppColors
                                                                  .indigo500
                                                            : AppColors
                                                                  .indigo500
                                                                  .withValues(
                                                                    alpha: 0.12,
                                                                  ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12.r,
                                                            ),
                                                        border: Border.all(
                                                          color: AppColors
                                                              .indigo500
                                                              .withValues(
                                                                alpha: 0.3,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            _isPlayingVoice
                                                                ? Icons
                                                                      .stop_rounded
                                                                : Icons
                                                                      .play_arrow_rounded,
                                                            color: _isPlayingVoice
                                                                ? Colors.white
                                                                : AppColors
                                                                      .indigo500,
                                                            size: 16.r,
                                                          ),
                                                          SizedBox(width: 4.w),
                                                          Text(
                                                            _isPlayingVoice
                                                                ? context.tr(
                                                                    'settings.voice_playing',
                                                                    fallback:
                                                                        'Playing',
                                                                  )
                                                                : context.tr(
                                                                    'settings.voice_test',
                                                                    fallback:
                                                                        'Test',
                                                                  ),
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Outfit',
                                                              fontSize: 12.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: _isPlayingVoice
                                                                  ? Colors.white
                                                                  : AppColors
                                                                        .indigo500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 6.w),
                                                  Icon(
                                                    Icons.chevron_right_rounded,
                                                    color: isDark
                                                        ? Colors.white38
                                                        : Colors.grey[400],
                                                    size: 18.r,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SettingsSwitchTile(
                                              title: context.tr(
                                                'settings.haptic_feedback',
                                                fallback: 'Haptic Feedback',
                                              ),
                                              subtitle: context.tr(
                                                'settings.haptic_feedback_subtitle',
                                                fallback:
                                                    'Tactile vibration on interactions',
                                              ),
                                              icon: Icons.vibration_rounded,
                                              color: AppColors.teal500,
                                              value: _hapticsEnabledVal,
                                              isLoading: _isLoadingVal,
                                              onChanged: _toggleHaptics,
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 24.h),
                                      ],
                                    ),

                                    // 3. Languages & Localization
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SettingsSectionTitle(
                                          title: context.tr(
                                            'settings.languages_title',
                                            fallback:
                                                'Languages & Localization',
                                          ),
                                          isDark: isDark,
                                        ),
                                        SettingsGroup(
                                          children: [
                                            SettingsTile(
                                              title: context.tr(
                                                'settings.language_selection',
                                                fallback:
                                                    'App Interface Language',
                                              ),
                                              subtitle: context.tr(
                                                'settings.language_selection_subtitle',
                                                fallback:
                                                    'Menu labels, buttons & notifications',
                                              ),
                                              icon: Icons.language_rounded,
                                              color: AppColors.teal500,
                                              onTap: () =>
                                                  LanguagePickerSheet.show(
                                                    context,
                                                  ),
                                              trailing: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 10.w,
                                                  vertical: 5.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.teal500
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        10.r,
                                                      ),
                                                  border: Border.all(
                                                    color: AppColors.teal500
                                                        .withValues(
                                                          alpha: 0.25,
                                                        ),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      '${di.sl<LocaleService>().currentLocaleFlag} '
                                                      '${di.sl<LocaleService>().currentLocaleName}',
                                                      style: TextStyle(
                                                        fontFamily: 'Outfit',
                                                        fontSize: 12.sp,
                                                        color:
                                                            AppColors.teal500,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                    SizedBox(width: 4.w),
                                                    Icon(
                                                      Icons
                                                          .chevron_right_rounded,
                                                      size: 14.r,
                                                      color: AppColors.teal500,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            SettingsTile(
                                              title: context.tr(
                                                'settings.translation_language',
                                                fallback:
                                                    'Game Hint Translation',
                                              ),
                                              subtitle: context.tr(
                                                'settings.translation_language_subtitle',
                                                fallback:
                                                    'Word definitions and explanations',
                                              ),
                                              icon: Icons.g_translate_rounded,
                                              color: AppColors.amber500,
                                              onTap: () async {
                                                await LanguageSelectionBottomSheet.show(
                                                  context,
                                                  currentLanguage:
                                                      _translationLanguageNameVal,
                                                );
                                                if (!mounted) return;
                                                _loadTranslationLanguageName();
                                              },
                                              trailing:
                                                  _translationLanguageNameVal !=
                                                      null
                                                  ? Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 10.w,
                                                            vertical: 5.h,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                            .amber500
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10.r,
                                                            ),
                                                        border: Border.all(
                                                          color: AppColors
                                                              .amber500
                                                              .withValues(
                                                                alpha: 0.25,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            '${TranslationService.getFlag(_translationLanguageNameVal!)} $_translationLanguageNameVal',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Outfit',
                                                              fontSize: 12.sp,
                                                              color: AppColors
                                                                  .amber500,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                          ),
                                                          SizedBox(width: 4.w),
                                                          Icon(
                                                            Icons
                                                                .chevron_right_rounded,
                                                            size: 14.r,
                                                            color: AppColors
                                                                .amber500,
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 24.h),
                                      ],
                                    ),

                                    // 4. Accessibility & Motion
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SettingsSectionTitle(
                                          title: context.tr(
                                            'settings.accessibility_motion',
                                            fallback: 'Accessibility & Motion',
                                          ),
                                          isDark: isDark,
                                        ),
                                        SettingsGroup(
                                          children: [
                                            SettingsSwitchTile(
                                              title: context.tr(
                                                'settings.low_animation_mode',
                                                fallback: 'Low Animation Mode',
                                              ),
                                              subtitle: context.tr(
                                                'settings.low_animation_mode_subtitle',
                                                fallback:
                                                    'Reduce motion, transitions & save battery',
                                              ),
                                              icon: Icons.battery_saver_rounded,
                                              color: AppColors.rose500,
                                              value: _lowAnimationModeVal,
                                              isLoading: _isLoadingVal,
                                              onChanged:
                                                  _toggleLowAnimationMode,
                                            ),
                                            SettingsSwitchTile(
                                              title: context.tr(
                                                'settings.reduce_complex_gestures',
                                                fallback:
                                                    'Simplify Complex Gestures',
                                              ),
                                              subtitle: context.tr(
                                                'settings.reduce_complex_gestures_subtitle',
                                                fallback:
                                                    'Replace swiping with tap-to-select actions',
                                              ),
                                              icon:
                                                  Icons
                                                      .accessibility_new_rounded,
                                              color: AppColors.emerald500,
                                              value: _reduceComplexGesturesVal,
                                              isLoading: _isLoadingVal,
                                              onChanged: _toggleGestures,
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 24.h),
                                      ],
                                    ),

                                    // 5. Account, Storage & Privacy
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SettingsSectionTitle(
                                          title: context.tr(
                                            'settings.account_storage_privacy',
                                            fallback:
                                                'Account, Storage & Privacy',
                                          ),
                                          isDark: isDark,
                                        ),
                                        SettingsGroup(
                                          children: [
                                            SettingsTile(
                                              title: context.tr(
                                                'settings.security_password',
                                                fallback: 'Security & Password',
                                              ),
                                              subtitle: context.tr(
                                                'settings.security_password_subtitle',
                                                fallback:
                                                    'Send recovery email to reset password',
                                              ),
                                              icon: Icons.lock_person_rounded,
                                              color: AppColors.blue500,
                                              onTap: () =>
                                                  SettingsDialogs.showPasswordReset(
                                                    context,
                                                    user?.email ?? '',
                                                  ),
                                            ),
                                            SettingsTile(
                                              title: context.tr(
                                                'settings.age_verification',
                                                fallback: 'Age Verification',
                                              ),
                                              subtitle: context.tr(
                                                'settings.age_verification_subtitle',
                                                fallback:
                                                    'Recalibrate age settings & parental gate',
                                              ),
                                              icon: Icons.verified_user_rounded,
                                              color: AppColors.violet500,
                                              onTap: () async {
                                                final confirm =
                                                    await SettingsDialogs.showAgeVerificationReset(
                                                      context,
                                                    );
                                                if (confirm == true &&
                                                    context.mounted) {
                                                  await AgeGateService.resetAgeGate();
                                                  if (context.mounted) {
                                                    context.go('/age-gate');
                                                  }
                                                }
                                              },
                                            ),
                                            SettingsSwitchTile(
                                              title: context.tr(
                                                'settings.push_notifications',
                                                fallback: 'Push Notifications',
                                              ),
                                              subtitle: context.tr(
                                                'settings.push_notifications_subtitle',
                                                fallback:
                                                    'Daily streaks, quest alerts & bonuses',
                                              ),
                                              icon:
                                                  Icons
                                                      .notifications_active_rounded,
                                              color:
                                                  IllustrationColors.warmOrange,
                                              value: _notificationsEnabledVal,
                                              isLoading: _isLoadingVal,
                                              onChanged: _toggleNotifications,
                                            ),
                                            if (Platform.isAndroid)
                                              SettingsTile(
                                                title: context.tr(
                                                  'settings.battery_optimization',
                                                  fallback:
                                                      'Background Delivery & Battery',
                                                ),
                                                subtitle: context.tr(
                                                  'settings.battery_optimization_subtitle',
                                                  fallback:
                                                      'Ensure reminders arrive on Xiaomi, POCO & Samsung',
                                                ),
                                                icon: Icons.battery_saver_rounded,
                                                color: AppColors.amber500,
                                                onTap: () => SettingsDialogs
                                                    .showBatteryOptimizationHelp(
                                                  context,
                                                ),
                                              ),
                                            SettingsSwitchTile(
                                              title: context.tr(
                                                'settings.analytics',
                                                fallback: 'Anonymous Analytics',
                                              ),
                                              subtitle: context.tr(
                                                'settings.analytics_subtitle',
                                                fallback:
                                                    'Share anonymous crash & usage telemetry',
                                              ),
                                              icon: Icons.analytics_rounded,
                                              color: AppColors.blue500,
                                              value: _analyticsEnabledVal,
                                              isLoading: _isLoadingVal,
                                              onChanged: _toggleAnalytics,
                                            ),
                                            SettingsTile(
                                              title: context.tr(
                                                'settings.clear_cache',
                                                fallback: 'Clear App Cache',
                                              ),
                                              subtitle: _cacheSizeMB != null
                                                  ? context.tr(
                                                      'settings.cache_size_desc',
                                                      fallback:
                                                          '{0} MB temporary files',
                                                      args: [
                                                        _cacheSizeMB!
                                                            .toStringAsFixed(1),
                                                      ],
                                                    )
                                                  : context.tr(
                                                      'settings.clear_cache_subtitle',
                                                      fallback:
                                                          'Purge images and temporary data',
                                                    ),
                                              icon:
                                                  Icons
                                                      .cleaning_services_rounded,
                                              color: _LocalPalette.coloreab308,
                                              onTap: () =>
                                                  _handleClearCache(context),
                                              trailing: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 10.w,
                                                  vertical: 4.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _LocalPalette
                                                      .coloreab308
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        10.r,
                                                      ),
                                                  border: Border.all(
                                                    color: _LocalPalette
                                                        .coloreab308
                                                        .withValues(
                                                          alpha: 0.35,
                                                        ),
                                                  ),
                                                ),
                                                child: Text(
                                                  _cacheSizeMB != null
                                                      ? '${_cacheSizeMB!.toStringAsFixed(1)} MB'
                                                      : context.tr(
                                                          'settings.clear',
                                                          fallback: 'Clear',
                                                        ),
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.w700,
                                                    color: _LocalPalette
                                                        .coloreab308,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 24.h),
                                      ],
                                    ),

                                    // 6. Support & Legal
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _SettingsSupportGroup(
                                          isDark: isDark,
                                          appVersion: _appVersionVal,
                                          buildNumber: _buildNumberVal,
                                          onSupportTap: () =>
                                              _handleSupportLink(context),
                                          onLegalTap: (title) =>
                                              _handleLegalLink(context, title),
                                        ),
                                        SizedBox(height: 24.h),
                                      ],
                                    ),

                                    // 7. Danger Zone
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const _SettingsDangerGroup(),
                                        SizedBox(height: 24.h),
                                      ],
                                    ),

                                    // 8. Explicit Sign Out Button with User Email
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SettingsLogoutButton(
                                          email: user?.email,
                                        ),
                                      ],
                                    ),
                                  ];

                                  final shouldAnimate =
                                      !_hasPlayedEntranceAnimation &&
                                      !VowlMotion.shouldReduceMotion(context);
                                  if (shouldAnimate) {
                                    _hasPlayedEntranceAnimation = true;
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: contentChildren
                                          .animate(interval: 25.ms)
                                          .fadeIn(
                                            duration: 280.ms,
                                            curve: Curves.easeOutCubic,
                                          )
                                          .slideY(
                                            begin: 0.02,
                                            end: 0,
                                            duration: 280.ms,
                                            curve: Curves.easeOutCubic,
                                          ),
                                    );
                                  }

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: contentChildren,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final barBg = isMidnight
        ? Colors.black
        : (isDark ? AppColors.slate900 : AppColors.white);
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppColors.slate100);

    return SliverAppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      centerTitle: true,
      toolbarHeight: 50.h,
      leadingWidth: 70.w,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        color: barBg.withValues(alpha: 0.95),
      ),
      leading: Padding(
        padding: EdgeInsets.only(left: AppSpacing.screen),
        child: Center(
          child: ScaleButton(
            onTap: () {
              di.sl<HapticService>().selection();
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile');
              }
            },
            child: Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18.r,
                  color: isDark ? Colors.white : AppColors.slate900,
                ),
              ),
            ),
          ),
        ),
      ),
      title: Text(
        context.tr('settings.title', fallback: 'Settings'),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18.sp,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.onSurface,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: AppSpacing.screen),
          child: Center(
            child: ScaleButton(
              onTap: () {
                di.sl<HapticService>().selection();
                context.push('/about');
              },
              child: Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: 1.0,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 20.r,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Private Section Groups
// ---------------------------------------------------------------------------

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
              subtitle: context.tr(
                'settings.help_center_subtitle',
                fallback: 'Contact team support & send feedback',
              ),
              icon: Icons.help_center_rounded,
              color: AppColors.emerald500,
              onTap: onSupportTap,
            ),
            SettingsTile(
              title: context.tr(
                'settings.terms_of_service',
                fallback: 'Terms of Service',
              ),
              icon: Icons.description_rounded,
              color: AppColors.slate500,
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
              color: AppColors.slate400,
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
              color: _LocalPalette.color9ca3af,
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
  const _SettingsDangerGroup();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionTitle(
          title: context.tr('settings.danger_zone', fallback: 'Danger Zone'),
          isDark: isDark,
          tintColor: AppColors.red500,
        ),
        SettingsGroup(
          children: [
            SettingsTile(
              title: context.tr(
                'settings.delete_account',
                fallback: 'Delete Account',
              ),
              subtitle: context.tr(
                'settings.delete_account_subtitle',
                fallback: 'Permanently erase all progress, stats and data',
              ),
              icon: Icons.delete_forever_rounded,
              color: AppColors.red500,
              onTap: () async {
                final networkInfo = di.sl.isRegistered<NetworkInfo>()
                    ? di.sl<NetworkInfo>()
                    : null;
                if (networkInfo != null &&
                    !await networkInfo.hasRealConnection) {
                  if (context.mounted) {
                    CustomSnackBar.show(
                      context: context,
                      message: context.tr(
                        'auth.error.network_unreachable',
                        fallback:
                            'No internet connection. Please check your network and try again.',
                      ),
                      type: CustomSnackBarType.error,
                    );
                  }
                  return;
                }
                if (context.mounted) {
                  SettingsDialogs.showDeleteAccount(context);
                }
              },
              isDestructive: true,
            ),
          ],
        ),
      ],
    );
  }
}
