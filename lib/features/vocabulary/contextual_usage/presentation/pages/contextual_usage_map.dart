import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class ContextualUsageMap extends StatelessWidget {
  const ContextualUsageMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'contextualUsage',
      categoryId: 'vocabulary',
    );
  }
}
