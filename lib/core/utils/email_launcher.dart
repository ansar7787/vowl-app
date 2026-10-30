import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Cross-platform utility to launch the device's native email client directly to the inbox/dashboard.
class EmailLauncher {
  EmailLauncher._();

  static const MethodChannel _channel = MethodChannel('com.vowl.app/email_launcher');

  /// Opens the device's default email client directly to the inbox dashboard.
  ///
  /// - On Android: Uses native `Intent.ACTION_MAIN` + `Intent.CATEGORY_APP_EMAIL`
  ///   to launch the email client directly to its main inbox view (not the compose screen).
  /// - On iOS: Launches Apple Mail's `message://` inbox protocol directly.
  /// - Fallback: Gracefully attempts `mailto:` if native inbox intents are unavailable.
  ///
  /// Returns `true` if an email app or inbox was successfully opened, `false` otherwise.
  static Future<bool> openInbox() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final bool? success = await _channel.invokeMethod<bool>('openEmailInbox');
        if (success == true) return true;
      } else if (!kIsWeb && Platform.isIOS) {
        final Uri iosInboxUri = Uri.parse('message://');
        if (await canLaunchUrl(iosInboxUri)) {
          return await launchUrl(iosInboxUri, mode: LaunchMode.externalApplication);
        }
      }

      // Universal fallback: mailto
      final Uri mailtoUri = Uri(scheme: 'mailto');
      if (await canLaunchUrl(mailtoUri)) {
        return await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
      }

      return false;
    } catch (_) {
      // In case of platform exception, attempt mailto as last resort
      try {
        final Uri mailtoUri = Uri(scheme: 'mailto');
        if (await canLaunchUrl(mailtoUri)) {
          return await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {
        return false;
      }
      return false;
    }
  }
}

