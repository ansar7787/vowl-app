import 'package:safe_device/safe_device.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Abstract contract defining the device integrity and security protection layer.
///
/// Decouples client verification libraries from calling boot orchestration pipelines,
/// satisfying the Dependency Inversion Principle (DIP).
abstract class SecurityService {
  /// Factory mapping constructor supporting seamless backwards compatibility for DI callers.
  factory SecurityService() = SecurityServiceImpl;

  /// Backward-compatible static delegation method to check device security.
  static Future<bool> isDeviceSecure() => SecurityServiceImpl().checkDeviceSecurity();

  /// Backward-compatible static delegation method to check developer mode.
  static Future<bool> isDeveloperModeEnabled() => SecurityServiceImpl().checkDeveloperMode();

  /// Evaluates device integrity by checking for rooted/jailbroken signatures and emulators.
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
      debugPrint('SecurityService: Device security verification exception: $e');
      return true;
    }
  }

  @override
  Future<bool> checkDeveloperMode() async {
    try {
      return await SafeDevice.isDevelopmentModeEnable;
    } catch (e) {
      debugPrint('SecurityService: Developer mode verification exception: $e');
      return false;
    }
  }
}
