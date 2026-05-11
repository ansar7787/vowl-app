import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class SyllableStressMap extends StatelessWidget {
  const SyllableStressMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'syllableStress',
      categoryId: 'accent',
    );
  }
}
