import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class CompleteSentenceMap extends StatelessWidget {
  const CompleteSentenceMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'completeSentence',
      categoryId: 'writing',
    );
  }
}
