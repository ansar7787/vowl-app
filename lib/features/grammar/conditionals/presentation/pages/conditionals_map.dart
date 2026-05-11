import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class ConditionalsMap extends StatelessWidget {
  const ConditionalsMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'conditionals',
      categoryId: 'grammar',
    );
  }
}
