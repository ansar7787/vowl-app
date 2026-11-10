import 'package:flutter/material.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';

/// Centralized DRY helper that validates live network connectivity
/// before entering 1v1 Arena Duels, Matchmaking, or Lobby sessions.
class ArenaNetworkHelper {
  ArenaNetworkHelper._();

  /// Verifies active internet connectivity.
  ///
  /// - Returns `true` if the device has an authentic physical internet connection.
  /// - Returns `false` if offline, triggers warning haptic, and displays a
  ///   user-friendly [CustomSnackBar] explaining that live 1v1 duels require
  ///   an internet connection.
  static Future<bool> ensureOnline(BuildContext context) async {
    final networkInfo = di.sl.isRegistered<NetworkInfo>()
        ? di.sl<NetworkInfo>()
        : null;

    if (networkInfo != null && !await networkInfo.hasRealConnection) {
      if (context.mounted) {
        if (di.sl.isRegistered<HapticService>()) {
          di.sl<HapticService>().warning();
        }
        CustomSnackBar.show(
          context: context,
          message: context.tr(
            'arena.error_offline',
            fallback:
                '1v1 Arena Duels require an active internet connection. Please check your network and try again.',
          ),
          type: CustomSnackBarType.warning,
        );
      }
      return false;
    }
    return true;
  }
}
