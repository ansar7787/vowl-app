import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class SentenceCorrectionMap extends StatelessWidget {
  const SentenceCorrectionMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'correctionWriting',
      categoryId: 'writing',
    );
  }
}
