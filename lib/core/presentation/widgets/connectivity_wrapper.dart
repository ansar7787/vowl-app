import 'package:flutter/material.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/presentation/pages/no_internet_page.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

/// A connectivity gatekeeper wrapper with premium visual transitions and layout keying.
class ConnectivityWrapper extends StatelessWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppNetworkStatus>(
      stream: di.sl<NetworkInfo>().onStatusChange,
      builder: (context, snapshot) {
        Widget activeWidget;

        if (snapshot.hasData && snapshot.data == AppNetworkStatus.offline) {
          activeWidget = NoInternetPage(
            key: const ValueKey('connectivity_offline'),
            onRetry: () async {
              await Future.delayed(const Duration(seconds: 1)); // UX delay
              await di.sl<NetworkInfo>().isConnected;
            },
          );
        } else {
          activeWidget = KeyedSubtree(
            key: const ValueKey('connectivity_online'),
            child: child,
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: activeWidget,
        );
      },
    );
  }
}
