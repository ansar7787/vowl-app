import 'package:flutter/material.dart';

/// Placeholder banner ad widget.
///
/// Returns [SizedBox.shrink] to take up zero space. Replace with the
/// platform ad SDK implementation (e.g. google_mobile_ads) when ads are
/// activated.
class AdBannerWidget extends StatelessWidget {
  const AdBannerWidget({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
