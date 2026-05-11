import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class FindWordMeaningMap extends StatelessWidget {
  const FindWordMeaningMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'findWordMeaning',
      categoryId: 'reading',
    );
  }
}
