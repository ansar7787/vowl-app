import 'package:flutter/material.dart';

/// Placeholder banner ad widget (feature-level variant).
///
/// Returns [SizedBox.shrink]. Replace with the platform ad SDK
/// implementation when ads are activated.
///
/// TODO(ads): Consolidate with [AdBannerWidget] into a single shared
/// component under `core/presentation/widgets/` to remove duplication.
class BannerAdWidget extends StatelessWidget {
  const BannerAdWidget({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
