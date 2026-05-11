import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class ModalsSelectionMap extends StatelessWidget {
  const ModalsSelectionMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'modalsSelection',
      categoryId: 'grammar',
    );
  }
}
