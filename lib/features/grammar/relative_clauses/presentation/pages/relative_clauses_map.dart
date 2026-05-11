import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class RelativeClausesMap extends StatelessWidget {
  const RelativeClausesMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'relativeClauses',
      categoryId: 'grammar',
    );
  }
}
