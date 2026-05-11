import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class PrepositionChoiceMap extends StatelessWidget {
  const PrepositionChoiceMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'prepositionChoice',
      categoryId: 'grammar',
    );
  }
}
