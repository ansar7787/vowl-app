import 'package:safe_device/safe_device.dart';
import 'dart:io';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart';

/// Abstract contract defining the device integrity and security protection layer.
///
/// Decouples client verification libraries from calling boot orchestration pipelines,
/// satisfying the Dependency Inversion Principle (DIP).
abstract class SecurityService {
  /// Factory mapping constructor supporting seamless backwards compatibility for DI callers.
  factory SecurityService() = SecurityServiceImpl;

  /// Backward-compatible static delegation method to check device security.
  static Future<bool> isDeviceSecure() =>
      SecurityServiceImpl().checkDeviceSecurity();

  /// Backward-compatible static delegation method to check developer mode.
  static Future<bool> isDeveloperModeEnabled() =>
      SecurityServiceImpl().checkDeveloperMode();

  /// Evaluates device integrity by checking for rooted/jailbroken signatures and emulators.
  ///
  /// SECURITY TRADEOFF (intentionally left as-is - flagging for your
  /// explicit decision rather than silently changing it): if the
  /// underlying `safe_device` plugin throws on a given device, this
  /// **fails open** (returns `true`, i.e. "secure"/"allowed"). That means
  /// a plugin-incompatible jailbroken/rooted device would slip through.
  /// The alternative (fail closed - return `false` on error) would
  /// instead risk blocking legitimate purchases on otherwise-fine low-end
  /// or unusual Android hardware where the plugin simply errors. Which
  /// direction is correct depends on whether this is your *only* anti-
  /// fraud layer (in which case fail-closed is usually safer) or one of
  /// several layers backed by server-side validation (in which case
  /// fail-open avoids false-positive lockouts of paying users). I did not
  /// change this without your sign-off since it's a product/risk
  /// decision, not a code defect.
  Future<bool> checkDeviceSecurity();

  /// Checks if developer mode options are enabled on the operating system.
  Future<bool> checkDeveloperMode();
}

/// Concrete implementation of [SecurityService] using the `safe_device` plugin.
class SecurityServiceImpl implements SecurityService {
  const SecurityServiceImpl();

  @override
  Future<bool> checkDeviceSecurity() async {
    try {
      // 1. Inspect device for Root/Jailbreak configurations
      final bool jailbroken = await SafeDevice.isJailBroken;

      // 2. Inspect device for simulated emulator signatures
      final bool isEmulator = await SafeDevice.isRealDevice == false;

      // Restrict economy access on jailbroken hardware to secure transactions
      if (jailbroken) return false;

      // Prevent automatic botting scripts on mobile emulators (allowing Desktop for testing)
      if (isEmulator && !Platform.isWindows && !Platform.isMacOS) {
        return false;
      }

      return true;
    } catch (e) {
      // Fall back to permissive access if plugin execution fails on target hardware
      sl<AppLogger>().error(
        'SecurityService: Device security verification exception',
        error: e,
      );
      return true;
    }
  }

  @override
  Future<bool> checkDeveloperMode() async {
    try {
      return await SafeDevice.isDevelopmentModeEnable;
    } catch (e) {
      sl<AppLogger>().error(
        'SecurityService: Developer mode verification exception',
        error: e,
      );
      return false;
    }
  }
}
