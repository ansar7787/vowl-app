import 'package:flutter/material.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/presentation/pages/no_internet_page.dart';
import 'package:vowl/core/presentation/widgets/offline_banner.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/offline_play_gate_service.dart';

/// Wraps the app's primary widget tree and intercepts connectivity changes.
///
/// ### Behaviour (Smart Hybrid Model with Offline Quota)
///
///  - **Online:** renders [child] normally. Resets offline play quota.
///  - **Offline on a network-critical route** (login, leaderboard, etc.):
///    full-screen [NoInternetPage] block.
///  - **Offline on gameplay route, quota remaining:** shows a slim [OfflineBanner]
///    — user can keep playing. Game data is local, so no internet needed.
///  - **Offline on gameplay route, quota exhausted:** full-screen [NoInternetPage]
///    block — free users must reconnect to continue (protects ad revenue).
///  - **Premium users:** never see offline restrictions because
///    [NetworkInfo.setPremiumOverride] makes the stream always emit online.
///
/// ### Why this approach?
/// Game data loads from local JSON assets, so blocking gameplay on every
/// network blip (rain, slow 3G) is unnecessarily punitive. But allowing
/// unlimited offline play for free users would eliminate ad revenue entirely.
/// The compromise: a small offline grace period (3 levels), then block.
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  /// The current route location, tracked via router listener.
  String _currentLocation = '';

  /// Routes that genuinely require an active internet connection and should
  /// ALWAYS display a full-screen block when offline (regardless of quota).
  static const _hardBlockRoutes = <String>{
    AppRouter.loginRoute,
    AppRouter.signupRoute,
    AppRouter.forgotPasswordRoute,
    AppRouter.verifyEmailRoute,
    AppRouter.leaderboardRoute,
    AppRouter.kidsLeaderboardRoute,
  };

  /// Routes where even the soft offline banner should be suppressed
  /// (e.g., the Premium purchase screen should be accessible offline
  /// so users can view plans and purchase when back online).
  static const _offlineSilentRoutes = <String>{
    AppRouter.premiumRoute,
    AppRouter.splashRoute,
    AppRouter.ageGateRoute,
  };

  @override
  void initState() {
    super.initState();
    AppRouter.router.routerDelegate.addListener(_onRouteChange);
  }

  @override
  void dispose() {
    AppRouter.router.routerDelegate.removeListener(_onRouteChange);
    super.dispose();
  }

  void _onRouteChange() {
    final matches =
        AppRouter.router.routerDelegate.currentConfiguration.matches;
    if (matches.isNotEmpty) {
      final location = matches.last.matchedLocation;
      if (location != _currentLocation) {
        setState(() {
          _currentLocation = location;
        });
      }
    }
  }

  /// Triggers an active connectivity check after a short UX delay.
  static Future<void> _handleRetry() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    try {
      await di.sl<NetworkInfo>().isConnected;
    } catch (_) {
      // Ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppNetworkStatus>(
      stream: di.sl<NetworkInfo>().onStatusChange,
      builder: (context, snapshot) {
        final isOffline =
            snapshot.hasData && snapshot.data == AppNetworkStatus.offline;

        // Reset offline quota when back online
        if (!isOffline) {
          OfflinePlayGateService.instance.resetQuota();
        }

        // --- Determine overlay strategy ---

        // 1. Always hard-block auth/leaderboard routes
        final bool isHardBlockRoute =
            _hardBlockRoutes.contains(_currentLocation);

        // 2. Check if offline quota is exhausted (free users played 3+ levels offline)
        final bool isQuotaExhausted =
            OfflinePlayGateService.instance.isOfflineQuotaExhausted;

        // 3. Final decision: hard block if offline AND (critical route OR quota exhausted)
        final bool shouldHardBlock =
            isOffline && (isHardBlockRoute || isQuotaExhausted);

        // 4. Soft banner: offline but still within grace period, not on silent route
        final bool shouldShowBanner = isOffline &&
            !shouldHardBlock &&
            !_offlineSilentRoutes.contains(_currentLocation);

        return Stack(
          textDirection: TextDirection.ltr,
          children: [
            // Always keep the Navigator (child) alive to preserve state
            // (audio playback, game progress, animation controllers).
            widget.child,

            // Hard block: full-screen NoInternetPage
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder:
                    (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: shouldHardBlock
                    ? NoInternetPage(
                        key: const ValueKey('connectivity_hard_block'),
                        onRetry: _handleRetry,
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('connectivity_clear'),
                      ),
              ),
            ),

            // Soft banner: non-blocking notification for gameplay routes
            // (within the offline grace period)
            if (shouldShowBanner)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: OfflineBanner(
                  key: ValueKey('connectivity_soft_banner'),
                ),
              ),
          ],
        );
      },
    );
  }
}
