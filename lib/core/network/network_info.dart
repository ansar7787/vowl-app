import 'dart:async';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Represents standard application-level network connection statuses.
///
/// Decouples the presentation and domain logic from third-party library classes,
/// ensuring high compliance with the Dependency Inversion Principle.
enum AppNetworkStatus { online, offline }

/// Abstract contract for verifying internet connectivity status.
abstract class NetworkInfo {
  /// Resolves the current network connectivity status in a future.
  Future<bool> get isConnected;

  /// Emits real-time, deduped network connectivity status updates.
  Stream<AppNetworkStatus> get onStatusChange;

  /// Sets a persistent override that forces network checks to return online.
  ///
  /// ### Why this exists (Premium Offline Play)
  /// Premium users are never shown offline gates, banners, or quota blocks.
  /// This override makes all bloc-level network checks pass, allowing
  /// Firestore write operations to proceed even when the device is offline.
  ///
  /// ### Why a custom queue isn't needed
  /// The Firestore SDK has **built-in offline persistence** on mobile
  /// (Android/iOS). When a premium user writes data while offline:
  /// 1. The SDK queues the write in its local SQLite cache.
  /// 2. When the device reconnects, the SDK automatically syncs.
  /// 3. Reads are served from the local cache (no stale data risk).
  ///
  /// Operations that truly require live network (Firebase Auth: delete account,
  /// sign out) are caught by [FirebaseFailureHandlerMixin] and surfaced as
  /// [NetworkFailure] → the user sees a clear "No internet" error message.
  void setPremiumOverride(bool isPremium);
}

/// Concrete high-performance implementation of the [NetworkInfo] contract.
class NetworkInfoImpl implements NetworkInfo {
  final InternetConnection _connectionChecker;
  bool _isPremiumOverride = false;

  NetworkInfoImpl(this._connectionChecker);

  @override
  void setPremiumOverride(bool isPremium) {
    _isPremiumOverride = isPremium;
  }

  @override
  Future<bool> get isConnected async {
    if (_isPremiumOverride) return true;
    try {
      // Defensive timeout protection: increased to 10 seconds to gracefully handle
      // slow 3G/Edge networks without prematurely punishing the user.
      return await _connectionChecker.hasInternetAccess.timeout(
        const Duration(seconds: 10),
        onTimeout: () => false,
      );
    } catch (_) {
      return false; // Fail-safe fallback: treat any socket exception or timeout as offline
    }
  }

  @override
  Stream<AppNetworkStatus> get onStatusChange {
    // Dynamic mapping: converts third-party InternetStatus into application-specific AppNetworkStatus.
    return _connectionChecker.onStatusChange.map(
      (status) {
        if (_isPremiumOverride) return AppNetworkStatus.online;

        switch (status) {
          case InternetStatus.connected:
            return AppNetworkStatus.online;
          case InternetStatus.disconnected:
            return AppNetworkStatus.offline;
        }
      },
    ).distinct(); // DSA Optimization: distinct() ignores redundant duplicate status changes to save widget rebuilds.
  }
}
