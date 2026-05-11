import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class ReadingInferenceMap extends StatelessWidget {
  const ReadingInferenceMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'readingInference',
      categoryId: 'reading',
    );
  }
}
