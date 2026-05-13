import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:vowl/core/presentation/pages/no_internet_page.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class ConnectivityWrapper extends StatelessWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<InternetStatus>(
      stream: di.sl<InternetConnection>().onStatusChange,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == InternetStatus.disconnected) {
          return NoInternetPage(
            onRetry: () async {
              await Future.delayed(const Duration(seconds: 1)); // UX delay
              await di.sl<InternetConnection>().hasInternetAccess;
            },
          );
        }
        return child;
      },
    );
  }
}
