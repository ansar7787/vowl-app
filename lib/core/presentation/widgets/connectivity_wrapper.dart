import 'package:flutter/material.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/presentation/pages/no_internet_page.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class ConnectivityWrapper extends StatelessWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppNetworkStatus>(
      stream: di.sl<NetworkInfo>().onStatusChange,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == AppNetworkStatus.offline) {
          return NoInternetPage(
            onRetry: () async {
              await Future.delayed(const Duration(seconds: 1)); // UX delay
              await di.sl<NetworkInfo>().isConnected;
            },
          );
        }
        return child;
      },
    );
  }
}
