import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class ReadAndMatchMap extends StatelessWidget {
  const ReadAndMatchMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'readAndMatch',
      categoryId: 'reading',
    );
  }
}
