import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class SentenceBuilderMap extends StatelessWidget {
  const SentenceBuilderMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'sentenceBuilder',
      categoryId: 'writing',
    );
  }
}
