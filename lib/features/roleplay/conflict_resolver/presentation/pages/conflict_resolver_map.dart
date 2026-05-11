import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class ConflictResolverMap extends StatelessWidget {
  const ConflictResolverMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'conflictResolver',
      categoryId: 'roleplay',
    );
  }
}
