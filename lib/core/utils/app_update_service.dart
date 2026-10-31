import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/app_version_helper.dart';
import 'package:vowl/core/utils/injection_container.dart';
import 'package:vowl/core/utils/remote_config_service.dart';

/// Specifies the nature of an application update requirement.
enum AppUpdateType {
  /// The app is up to date or update prompt is silenced.
  none,

  /// An update is available, but the user may dismiss and continue playing.
  flexible,

  /// A critical breaking update is required before the app can be used.
  force,
}

/// Metadata describing available update state.
class AppUpdateInfo {
  final AppUpdateType type;
  final String currentVersion;
  final String latestVersion;
  final String minVersion;
  final String releaseNotes;
  final String storeUrl;

  const AppUpdateInfo({
    required this.type,
    required this.currentVersion,
    required this.latestVersion,
    required this.minVersion,
    required this.releaseNotes,
    required this.storeUrl,
  });

  bool get hasUpdate => type != AppUpdateType.none;
  bool get isForced => type == AppUpdateType.force;
  bool get isFlexible => type == AppUpdateType.flexible;
}

/// Service interface responsible for app version tracking, update gates, and store launching.
abstract class AppUpdateService {
  /// Evaluates remote configuration against the currently installed build.
  /// If [ignoreFrequencyCap] is true, checks update status even if previously dismissed today.
  Future<AppUpdateInfo> checkForUpdate({bool ignoreFrequencyCap = false});

  /// Records that the user dismissed an optional update prompt for [version].
  Future<void> recordDismissal(String version);

  /// Launches the Google Play Store (or custom store URL) for Vowl.
  Future<bool> launchStore({String? customUrl});
}

/// Concrete production implementation of [AppUpdateService].
class AppUpdateServiceImpl implements AppUpdateService {
  static const String _prefKeyDismissedVersion =
      'vowl_last_dismissed_update_version';
  static const String _prefKeyDismissedTimestamp =
      'vowl_last_dismissed_update_timestamp';
  static const String _defaultPackageId = 'com.vowl.app';
  static const String _marketScheme = 'market://details?id=$_defaultPackageId';
  static const String _webPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=$_defaultPackageId';

  final RemoteConfigService _remoteConfig;
  final SharedPreferences? _preferences;

  AppUpdateServiceImpl({
    required RemoteConfigService remoteConfig,
    SharedPreferences? preferences,
  })  : _remoteConfig = remoteConfig,
        _preferences = preferences;

  Future<SharedPreferences> _getPrefs() async {
    return _preferences ?? await SharedPreferences.getInstance();
  }

  @override
  Future<AppUpdateInfo> checkForUpdate({bool ignoreFrequencyCap = false}) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final minVersion = _remoteConfig.minAppVersion;
      final latestVersion = _remoteConfig.latestAppVersion;
      final releaseNotes = _remoteConfig.updateReleaseNotes;
      final storeUrl = _remoteConfig.updateStoreUrl;

      // 1. Force update takes absolute precedence
      if (AppVersionHelper.isBelowMinVersion(currentVersion, minVersion)) {
        return AppUpdateInfo(
          type: AppUpdateType.force,
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          minVersion: minVersion,
          releaseNotes: releaseNotes,
          storeUrl: storeUrl,
        );
      }

      // 2. Check for optional flexible update
      if (AppVersionHelper.isUpdateAvailable(currentVersion, latestVersion)) {
        if (!ignoreFrequencyCap) {
          final prefs = await _getPrefs();
          final dismissedVersion =
              prefs.getString(_prefKeyDismissedVersion) ?? '';
          final dismissedTimestamp =
              prefs.getInt(_prefKeyDismissedTimestamp) ?? 0;

          // If dismissed for the exact same target version in the last 24 hours, suppress
          if (dismissedVersion == latestVersion && dismissedTimestamp > 0) {
            final lastDismissed =
                DateTime.fromMillisecondsSinceEpoch(dismissedTimestamp);
            final hoursSince = DateTime.now().difference(lastDismissed).inHours;
            if (hoursSince < 24) {
              return AppUpdateInfo(
                type: AppUpdateType.none,
                currentVersion: currentVersion,
                latestVersion: latestVersion,
                minVersion: minVersion,
                releaseNotes: releaseNotes,
                storeUrl: storeUrl,
              );
            }
          }
        }

        return AppUpdateInfo(
          type: AppUpdateType.flexible,
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          minVersion: minVersion,
          releaseNotes: releaseNotes,
          storeUrl: storeUrl,
        );
      }

      return AppUpdateInfo(
        type: AppUpdateType.none,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        minVersion: minVersion,
        releaseNotes: releaseNotes,
        storeUrl: storeUrl,
      );
    } catch (e, stack) {
      if (sl.isRegistered<AppLogger>()) {
        sl<AppLogger>().error(
          'AppUpdateService: Error evaluating update availability',
          error: e,
          stackTrace: stack,
        );
      }
      return const AppUpdateInfo(
        type: AppUpdateType.none,
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        minVersion: '1.0.0',
        releaseNotes: '',
        storeUrl: '',
      );
    }
  }

  @override
  Future<void> recordDismissal(String version) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_prefKeyDismissedVersion, version);
      await prefs.setInt(
        _prefKeyDismissedTimestamp,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      if (sl.isRegistered<AppLogger>()) {
        sl<AppLogger>().warning(
          'AppUpdateService: Failed to record update prompt dismissal: $e',
        );
      }
    }
  }

  @override
  Future<bool> launchStore({String? customUrl}) async {
    final target = (customUrl != null && customUrl.trim().isNotEmpty)
        ? customUrl.trim()
        : null;

    if (target != null) {
      final uri = Uri.tryParse(target);
      if (uri != null) {
        try {
          if (await canLaunchUrl(uri)) {
            return await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } catch (_) {}
      }
    }

    // Try native Android market scheme first
    try {
      final marketUri = Uri.parse(_marketScheme);
      if (await canLaunchUrl(marketUri)) {
        return await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    // Fall back to web Play Store link
    try {
      final webUri = Uri.parse(_webPlayStoreUrl);
      if (await canLaunchUrl(webUri)) {
        return await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
      return await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

