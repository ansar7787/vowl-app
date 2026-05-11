import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class PictureDescriptionWriteMap extends StatelessWidget {
  const PictureDescriptionWriteMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'describeSituationWriting',
      categoryId: 'writing',
    );
  }
}
