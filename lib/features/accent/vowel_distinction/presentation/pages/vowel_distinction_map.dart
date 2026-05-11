import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class VowelDistinctionMap extends StatelessWidget {
  const VowelDistinctionMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'vowelDistinction',
      categoryId: 'accent',
    );
  }
}
