import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class ClauseConnectorMap extends StatelessWidget {
  const ClauseConnectorMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'clauseConnector',
      categoryId: 'grammar',
    );
  }
}
