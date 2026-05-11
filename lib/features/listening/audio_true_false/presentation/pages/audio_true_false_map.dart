import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class AudioTrueFalseMap extends StatelessWidget {
  const AudioTrueFalseMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'audioTrueFalse',
      categoryId: 'listening',
    );
  }
}
