import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class IntonationMimicMap extends StatelessWidget {
  const IntonationMimicMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'intonationMimic',
      categoryId: 'accent',
    );
  }
}
