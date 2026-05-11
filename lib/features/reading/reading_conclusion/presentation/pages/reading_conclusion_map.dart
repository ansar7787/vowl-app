import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class ReadingConclusionMap extends StatelessWidget {
  const ReadingConclusionMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'readingConclusion',
      categoryId: 'reading',
    );
  }
}
