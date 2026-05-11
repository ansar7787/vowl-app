import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class SpeedSpellingMap extends StatelessWidget {
  const SpeedSpellingMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'speedSpelling',
      categoryId: 'elitemastery',
    );
  }
}
