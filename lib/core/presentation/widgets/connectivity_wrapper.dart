import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/presentation/pages/offline_quota_exhausted_page.dart';
import 'package:vowl/core/presentation/widgets/offline_banner.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/offline_play_gate_service.dart';
import 'package:vowl/core/utils/offline_reward_sync_service.dart';
import 'package:vowl/features/games/game_routes.dart';

/// Wraps the app's primary widget tree and intercepts connectivity changes.
///
/// ### Behaviour (Smart Hybrid Model with Offline Quota)
///
///  - **Online:** renders [child] normally.
///  - **Offline + gameplay, quota remaining:** [OfflineBanner] (soft, non-blocking pill).
///  - **Offline + gameplay, quota exhausted:** [OfflineQuotaExhaustedPage]
///    with "Watch Ad" / "Reconnect" / "Go Premium" options.
///  - **Offline + non-gameplay routes:** no blocking overlay; screens handle their
///    own error/cached states without obstructing navigation.
///  - **Premium users:** never see offline restrictions.
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  final ValueNotifier<String> _currentLocation = ValueNotifier('');
  final ValueNotifier<int> _refreshTrigger = ValueNotifier(0);
  bool _wasOffline = false;

  /// Routes where the soft offline banner should be suppressed.
  static const _offlineSilentRoutes = <String>{
    AppRouter.premiumRoute,
    AppRouter.splashRoute,
    AppRouter.loginRoute,
    AppRouter.signupRoute,
    AppRouter.forgotPasswordRoute,
    AppRouter.verifyEmailRoute,
  };

  /// Positive whitelist of active gameplay routes where the offline quota blocker applies.
  /// All other screens (maps, home, settings, profile, etc.) are never blocked.
  static bool _isGameplayRoute(String path) {
    if (path.isEmpty) return false;
    return path.startsWith('/game') ||
        path.startsWith(GameRoutes.questSequenceRoute);
  }

  @override
  void initState() {
    super.initState();
    try {
      final matches =
          AppRouter.router.routerDelegate.currentConfiguration.matches;
      if (matches.isNotEmpty) {
        _currentLocation.value = matches.last.matchedLocation;
      } else {
        _currentLocation.value =
            AppRouter.router.routerDelegate.currentConfiguration.uri.path;
      }
    } catch (_) {}
    AppRouter.router.routerDelegate.addListener(_onRouteChange);
  }

  @override
  void dispose() {
    AppRouter.router.routerDelegate.removeListener(_onRouteChange);
    _currentLocation.dispose();
    _refreshTrigger.dispose();
    super.dispose();
  }

  void _onRouteChange() {
    final matches =
        AppRouter.router.routerDelegate.currentConfiguration.matches;
    if (matches.isNotEmpty) {
      final location = matches.last.matchedLocation;
      if (location != _currentLocation.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _currentLocation.value = location;
          }
        });
      }
    }
  }

  /// Triggers an active connectivity check after a short UX delay.
  Future<void> _handleRetry() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    try {
      await di.sl<NetworkInfo>().isConnected;
    } catch (_) {
      // Ignore
    }
  }

  /// Called when user watches a rewarded ad while offline for +3 levels.
  void _handleAdWatchedOffline() {
    if (mounted) _refreshTrigger.value++;
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.select(
      (AuthBloc bloc) => bloc.state.user?.isPremium ?? false,
    );

    return StreamBuilder<AppNetworkStatus>(
      stream: di.sl<NetworkInfo>().onStatusChange,
      builder: (context, snapshot) {
        final isNetworkOffline =
            snapshot.hasData && snapshot.data == AppNetworkStatus.offline;

        // Ensure premium users are never blocked by offline restrictions
        final isOffline = isNetworkOffline && !isPremium;
        final gate = OfflinePlayGateService.instance;

        // Online transition: online play is always free and unlimited.
        // We intentionally do NOT reset the daily offline quota on reconnect;
        // this eliminates the "toggle airplane mode" loophole.
        if (!isOffline && _wasOffline) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _refreshTrigger.value++;
            if (di.sl.isRegistered<OfflineRewardSyncService>()) {
              unawaited(di.sl<OfflineRewardSyncService>().syncPendingRewards());
            }
          });
        }
        _wasOffline = isOffline;

        return ListenableBuilder(
          listenable: gate,
          builder: (context, _) {
            return ValueListenableBuilder(
              valueListenable: _refreshTrigger,
              builder: (context, _, child) {
                return ValueListenableBuilder<String>(
                  valueListenable: _currentLocation,
                  builder: (context, currentLocation, child) {
                    final bool isQuotaExhausted = gate.isOfflineQuotaExhausted;

                    // Positive whitelist: quota block only applies on gameplay routes
                    final bool shouldShowQuotaBlock =
                        isOffline &&
                        isQuotaExhausted &&
                        _isGameplayRoute(currentLocation);

                    // Soft banner: offline with plays remaining, suppressed on silent routes
                    final bool shouldShowBanner =
                        isOffline &&
                        !shouldShowQuotaBlock &&
                        !_offlineSilentRoutes.contains(currentLocation);

                    return Stack(
                      textDirection: TextDirection.ltr,
                      children: [
                        widget.child,
                        Positioned.fill(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            child: shouldShowQuotaBlock
                                ? OfflineQuotaExhaustedPage(
                                    key: const ValueKey(
                                      'connectivity_quota_block',
                                    ),
                                    onRetry: _handleRetry,
                                    onAdWatched: _handleAdWatchedOffline,
                                    onClose: () {
                                      if (AppRouter.router.canPop()) {
                                        AppRouter.router.pop();
                                      } else {
                                        AppRouter.router.go(AppRouter.homeRoute);
                                      }
                                    },
                                  )
                                : const SizedBox.shrink(
                                    key: ValueKey('connectivity_clear'),
                                  ),
                          ),
                        ),
                        if (shouldShowBanner)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: OfflineBanner(
                              key: ValueKey(
                                'connectivity_soft_banner_${gate.remainingOfflinePlays}',
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
