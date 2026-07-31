import 'package:flutter/material.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/presentation/pages/no_internet_page.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

/// Wraps the app's primary widget tree and intercepts connectivity changes.
///
/// Behaviour:
///  - **Online / initial (no data yet):** renders [child] (optimistic).
///  - **Offline:** overlays [child] with [NoInternetPage] (preserves state).
///  - Transitions are smoothed by [AnimatedSwitcher].
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  bool _isOfflineAllowedRoute = false;

  @override
  void initState() {
    super.initState();
    // Listen to route changes to allow offline browsing of specific routes (e.g., Premium screen)
    AppRouter.router.routerDelegate.addListener(_onRouteChange);
  }

  @override
  void dispose() {
    AppRouter.router.routerDelegate.removeListener(_onRouteChange);
    super.dispose();
  }

  void _onRouteChange() {
    final matches = AppRouter.router.routerDelegate.currentConfiguration.matches;
    if (matches.isNotEmpty) {
      final location = matches.last.matchedLocation;
      final isPremium = location == AppRouter.premiumRoute;
      
      if (isPremium != _isOfflineAllowedRoute) {
        setState(() {
          _isOfflineAllowedRoute = isPremium;
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
            
        // Show the overlay ONLY if they are offline AND not on an allowed offline route
        final showOverlay = isOffline && !_isOfflineAllowedRoute;

        return Stack(
          textDirection: TextDirection.ltr,
          children: [
            // Always keep the Navigator (child) alive to preserve state (audio, game progress)
            widget.child,
            
            // Fade the overlay in and out
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: showOverlay
                    ? NoInternetPage(
                        key: const ValueKey('connectivity_offline'),
                        onRetry: _handleRetry,
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('connectivity_online'),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
