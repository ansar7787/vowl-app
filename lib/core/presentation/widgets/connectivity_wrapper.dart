import 'package:flutter/material.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/presentation/pages/no_internet_page.dart';
import 'package:vowl/core/presentation/widgets/offline_banner.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

/// Wraps the app's primary widget tree and intercepts connectivity changes.
///
/// ### Behaviour (Smart Hybrid Model)
///
///  - **Online / initial (no data yet):** renders [child] (optimistic).
///  - **Offline on a network-critical route** (login, leaderboard, etc.):
///    overlays [child] with [NoInternetPage] (hard block with retry).
///  - **Offline on a gameplay/content route:** shows a slim, non-blocking
///    [OfflineBanner] at the top — the user can continue playing because
///    game data is loaded from local bundled assets. Progress syncs later.
///  - Transitions are smoothed by [AnimatedSwitcher].
///
/// ### Why not block everything?
/// All curriculum/quest data is loaded from local JSON assets bundled in the
/// APK via [AssetQuestService.getQuests] → `rootBundle.loadString()`. Firestore
/// is only a fallback for missing assets. Blocking gameplay on network loss
/// punishes users unnecessarily — especially on slow 2G/3G connections — and
/// reduces ad impressions (less sessions = less revenue).
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
  /// display a full-screen block when offline. All other routes get a
  /// non-blocking informational banner.
  static const _hardBlockRoutes = <String>{
    AppRouter.loginRoute,
    AppRouter.signupRoute,
    AppRouter.forgotPasswordRoute,
    AppRouter.verifyEmailRoute,
    AppRouter.leaderboardRoute,
    AppRouter.kidsLeaderboardRoute,
  };

  /// Routes where even the soft offline banner should be suppressed
  /// (e.g., the Premium purchase screen needs to be accessible offline
  /// so users can view plans and complete the purchase when back online).
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

        // Determine overlay behaviour based on current route
        final bool shouldHardBlock =
            isOffline && _hardBlockRoutes.contains(_currentLocation);
        final bool shouldShowBanner = isOffline &&
            !shouldHardBlock &&
            !_offlineSilentRoutes.contains(_currentLocation);

        return Stack(
          textDirection: TextDirection.ltr,
          children: [
            // Always keep the Navigator (child) alive to preserve state
            // (audio playback, game progress, animation controllers).
            widget.child,

            // Hard block: full-screen NoInternetPage for auth/leaderboard
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
