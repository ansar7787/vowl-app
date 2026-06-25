import 'package:flutter/material.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/presentation/pages/no_internet_page.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

/// Wraps the app's primary widget tree and intercepts connectivity changes.
///
/// Behaviour:
///  - **Online / initial (no data yet):** renders [child] (optimistic).
///  - **Offline:** replaces [child] with [NoInternetPage].
///  - Transitions are smoothed by [AnimatedSwitcher].
class ConnectivityWrapper extends StatelessWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppNetworkStatus>(
      stream: di.sl<NetworkInfo>().onStatusChange,
      builder: (context, snapshot) {
        final isOffline =
            snapshot.hasData && snapshot.data == AppNetworkStatus.offline;

        final Widget activeWidget = isOffline
            ? NoInternetPage(
                key: const ValueKey('connectivity_offline'),
                onRetry: _handleRetry,
              )
            : KeyedSubtree(
                key: const ValueKey('connectivity_online'),
                child: child,
              );

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: activeWidget,
        );
      },
    );
  }

  /// Triggers an active connectivity check after a short UX delay.
  ///
  /// The UI updates automatically when [NetworkInfo.onStatusChange] emits —
  /// we do not need to act on the [isConnected] return value. The explicit
  /// call forces the underlying implementation to push a new status to the
  /// stream sooner than it would on its own.
  static Future<void> _handleRetry() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    try {
      await di.sl<NetworkInfo>().isConnected;
    } catch (_) {
      // A failed check will manifest as a continued offline stream state.
      // No action needed here — the UI is already showing the offline page.
    }
  }
}
