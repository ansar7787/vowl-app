import 'package:safe_device/safe_device.dart';
import 'dart:io';

class SecurityService {
  static Future<bool> isDeviceSecure() async {
    try {
      // 1. Check for Jailbreak/Root using safe_device
      bool jailbroken = await SafeDevice.isJailBroken;
      
      // 2. Check for Emulator
      bool isEmulator = await SafeDevice.isRealDevice == false;

      // Logic: Block Jailbroken/Rooted devices for economy safety
      if (jailbroken) return false;
      
      // Optional: Block emulators in production to prevent botting
      // We allow them on Desktop platforms for testing
      if (isEmulator && !Platform.isWindows && !Platform.isMacOS) return false;

      return true;
    } catch (e) {
      // If check fails, we default to secure but log it
      return true;
    }
  }

  static Future<bool> isDeveloperModeEnabled() async {
    try {
      return await SafeDevice.isDevelopmentModeEnable;
    } catch (e) {
      return false;
    }
  }
}
