import 'package:flutter/material.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/presentation/pages/no_internet_page.dart';
import 'package:vowl/core/presentation/pages/offline_quota_exhausted_page.dart';
import 'package:vowl/core/presentation/widgets/offline_banner.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/offline_play_gate_service.dart';

/// Wraps the app's primary widget tree and intercepts connectivity changes.
///
/// ### Behaviour (Smart Hybrid Model with Offline Quota)
///
///  - **Online:** renders [child] normally. If a reconnect-ad is pending,
///    shows an interstitial ad and then resets the offline quota.
///  - **Offline + auth route:** full-screen [NoInternetPage] (hard block).
///  - **Offline + gameplay, quota remaining:** [OfflineBanner] (soft, non-blocking).
///  - **Offline + gameplay, quota exhausted:** [OfflineQuotaExhaustedPage]
///    with "Watch Ad" / "Reconnect" / "Go Premium" options.
///  - **Premium users:** never see offline restrictions because
///    [NetworkInfo.setPremiumOverride] forces the stream to always emit online.
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  String _currentLocation = '';
  bool _wasOffline = false;

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

  /// Routes where even the soft offline banner should be suppressed.
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
        setState(() => _currentLocation = location);
      }
    }
  }

  /// Triggers an active connectivity check after a short UX delay.
  Future<void> _handleRetry() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    try {
      await di.sl<NetworkInfo>().isConnected;
    } catch (_) {
      // Ignore
    }
  }

  /// Called when the user comes back online after being offline.
  /// Shows an interstitial ad and then resets the offline quota.
  void _handleReconnectWithAd() {
    final gate = OfflinePlayGateService.instance;
    if (!gate.hasPendingReconnectReset) return;

    final adService = di.sl<AdService>();
    adService.showInterstitialAd(
      isPremium: false,
      onDismissed: () {
        gate.resetQuotaAfterAd();
        if (mounted) setState(() {});
      },
    );
  }

  /// Called when user watches a rewarded ad while offline for +3 levels.
  void _handleAdWatchedOffline() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppNetworkStatus>(
      stream: di.sl<NetworkInfo>().onStatusChange,
      builder: (context, snapshot) {
        final isOffline =
            snapshot.hasData && snapshot.data == AppNetworkStatus.offline;

        final gate = OfflinePlayGateService.instance;

        // ── Handle online transition ────────────────────────────────────
        if (!isOffline && _wasOffline) {
          // User came back online
          gate.markReconnected();
          // Schedule ad show after this build frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _handleReconnectWithAd();
          });
        }
        _wasOffline = isOffline;

        // ── Determine overlay strategy ──────────────────────────────────

        // 1. Always hard-block auth/leaderboard routes when offline
        final bool isHardBlockRoute =
            _hardBlockRoutes.contains(_currentLocation);

        // 2. Check if offline quota is exhausted
        final bool isQuotaExhausted = gate.isOfflineQuotaExhausted;

        // 3. Hard block for auth routes (show NoInternetPage)
        final bool shouldShowNoInternet = isOffline && isHardBlockRoute;

        // 4. Quota exhausted block for gameplay routes (show OfflineQuotaExhaustedPage)
        final bool shouldShowQuotaBlock = isOffline &&
            !isHardBlockRoute &&
            isQuotaExhausted &&
            !_offlineSilentRoutes.contains(_currentLocation);

        // 5. Soft banner: offline but within grace period, not on silent route
        final bool shouldShowBanner = isOffline &&
            !shouldShowNoInternet &&
            !shouldShowQuotaBlock &&
            !_offlineSilentRoutes.contains(_currentLocation);

        return Stack(
          textDirection: TextDirection.ltr,
          children: [
            // Always keep the Navigator alive to preserve state
            widget.child,

            // Overlay layer: either NoInternetPage OR OfflineQuotaExhaustedPage
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder:
                    (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: shouldShowNoInternet
                    ? NoInternetPage(
                        key: const ValueKey('connectivity_auth_block'),
                        onRetry: _handleRetry,
                      )
                    : shouldShowQuotaBlock
                        ? OfflineQuotaExhaustedPage(
                            key: const ValueKey('connectivity_quota_block'),
                            onRetry: _handleRetry,
                            onAdWatched: _handleAdWatchedOffline,
                          )
                        : const SizedBox.shrink(
                            key: ValueKey('connectivity_clear'),
                          ),
              ),
            ),

            // Soft banner: non-blocking notification within grace period
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
