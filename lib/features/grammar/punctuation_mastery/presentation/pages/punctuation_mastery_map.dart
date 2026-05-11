import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class PunctuationMasteryMap extends StatelessWidget {
  const PunctuationMasteryMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'punctuationMastery',
      categoryId: 'grammar',
    );
  }
}
