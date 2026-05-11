import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class ShadowingChallengeMap extends StatelessWidget {
  const ShadowingChallengeMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'shadowingChallenge',
      categoryId: 'accent',
    );
  }
}
