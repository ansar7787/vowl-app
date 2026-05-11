import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class StoryBuilderMap extends StatelessWidget {
  const StoryBuilderMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'storyBuilder',
      categoryId: 'elitemastery',
    );
  }
}
