import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class WriteMissingWordMap extends StatelessWidget {
  const WriteMissingWordMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'completeSentence',
      categoryId: 'writing',
    );
  }
}
