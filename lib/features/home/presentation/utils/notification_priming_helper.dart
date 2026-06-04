import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vowl/core/presentation/widgets/modern_game_dialog.dart';
import 'package:vowl/core/utils/notification_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class NotificationPrimingHelper {
  static bool _isPrompting = false;

  static Future<void> checkAndPrompt(BuildContext context, int currentStreak) async {
    if (_isPrompting) return;
    _isPrompting = true;

    try {
      // Delay slightly to let the home screen render and daily chest dialog show first
      await Future.delayed(const Duration(milliseconds: 3000));
      
      // Check if widget context is still active/mounted
      if (!context.mounted) return;

      final prefs = await SharedPreferences.getInstance();
      
      // 1. Get the last time the user was prompted (in ms since epoch)
      final int? lastPromptedMs = prefs.getInt('notification_last_prompted_time');
      final bool oldPrimed = prefs.getBool('notification_primed') ?? false;

      // Check current native notification status
      final bool isNotificationGranted = await Permission.notification.isGranted;

      if (isNotificationGranted) {
        // User already enabled notifications, no need to show any dialogs!
        return;
      }

      if (!context.mounted) return;

      final now = DateTime.now();

      if (lastPromptedMs == null && !oldPrimed) {
        // Very first time launching the app: show standard habit-building priming
        await _showDialog(context, isRePrompt: false);
      } else {
        // Cooldown rule: It must be at least 7 days since the last prompt or first opt-out
        final lastPromptedDate = lastPromptedMs != null 
            ? DateTime.fromMillisecondsSinceEpoch(lastPromptedMs)
            : now.subtract(const Duration(days: 8)); // fallback if they pressed Not Now in the old version

        final daysDifference = now.difference(lastPromptedDate).inDays;

        if (daysDifference >= 7) {
          // High motivation rule: Only re-prompt if they have a streak of 3+ days worth protecting!
          if (currentStreak >= 3) {
            final isBlocked = await Permission.notification.isPermanentlyDenied;
            if (!context.mounted) return;
            await _showDialog(
              context,
              isRePrompt: true, 
              isSystemBlocked: isBlocked,
              streak: currentStreak,
            );
          }
        }
      }
    } finally {
      _isPrompting = false;
    }
  }

  static Future<void> _showDialog(
    BuildContext context, {
    required bool isRePrompt, 
    bool isSystemBlocked = false,
    int streak = 0,
  }) {
    String title = "Owly is Waiting! 🦉⏰";
    String description = "Enable daily notifications so your friendly tutor can help you protect your streaks and keep learning!";
    String buttonText = "YES, REMIND ME! 🔥";

    if (isRePrompt) {
      title = "Streak Shield! 🦉🛡️";
      buttonText = isSystemBlocked ? "OPEN SETTINGS ⚙️" : "PROTECT MY STREAK! 🔥";
      description = isSystemBlocked
          ? "You have a super $streak-day streak! Enable notifications in settings so you never accidentally lose your progress."
          : "You have an awesome $streak-day streak! Enable reminders so Owly can remind you before it's too late.";
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ModernGameDialog(
        title: title,
        description: description,
        buttonText: buttonText,
        secondaryButtonText: "NOT NOW",
        isSuccess: true,
        onButtonPressed: () async {
          if (di.sl.isRegistered<HapticService>()) {
            di.sl<HapticService>().selection();
          }
          Navigator.of(dialogContext).pop();

          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('notification_last_prompted_time', DateTime.now().millisecondsSinceEpoch);
          await prefs.setBool('notification_primed', true);

          if (isSystemBlocked) {
            await openAppSettings();
          } else {
            if (di.sl.isRegistered<NotificationService>()) {
              await di.sl<NotificationService>().requestPermissions();
            }
          }
        },
        onSecondaryPressed: () async {
          if (di.sl.isRegistered<HapticService>()) {
            di.sl<HapticService>().light();
          }
          Navigator.of(dialogContext).pop();
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('notification_last_prompted_time', DateTime.now().millisecondsSinceEpoch);
          await prefs.setBool('notification_primed', true);
        },
      ),
    );
  }
}
