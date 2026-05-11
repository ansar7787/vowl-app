import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class SummarizeStoryWritingMap extends StatelessWidget {
  const SummarizeStoryWritingMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'summarizeStoryWriting',
      categoryId: 'writing',
    );
  }
}
