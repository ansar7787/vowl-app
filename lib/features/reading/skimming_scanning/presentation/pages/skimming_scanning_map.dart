import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class SkimmingScanningMap extends StatelessWidget {
  const SkimmingScanningMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'skimmingScanning',
      categoryId: 'reading',
    );
  }
}
