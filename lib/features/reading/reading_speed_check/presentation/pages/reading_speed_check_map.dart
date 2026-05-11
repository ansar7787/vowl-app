import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class ReadingSpeedCheckMap extends StatelessWidget {
  const ReadingSpeedCheckMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'readingSpeedCheck',
      categoryId: 'reading',
    );
  }
}
