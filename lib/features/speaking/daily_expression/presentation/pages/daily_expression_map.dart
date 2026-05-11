import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class DailyExpressionMap extends StatelessWidget {
  const DailyExpressionMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'dailyExpression',
      categoryId: 'speaking',
    );
  }
}
