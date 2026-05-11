import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class OpinionWritingMap extends StatelessWidget {
  const OpinionWritingMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'opinionWriting',
      categoryId: 'writing',
    );
  }
}
