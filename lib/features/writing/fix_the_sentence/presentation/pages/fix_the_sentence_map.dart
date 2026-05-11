import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class FixTheSentenceMap extends StatelessWidget {
  const FixTheSentenceMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'fixTheSentence',
      categoryId: 'writing',
    );
  }
}
