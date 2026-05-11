import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class SocialSparkMap extends StatelessWidget {
  const SocialSparkMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'socialSpark',
      categoryId: 'roleplay',
    );
  }
}
