import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class VoiceSwapMap extends StatelessWidget {
  const VoiceSwapMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'voiceSwap',
      categoryId: 'grammar',
    );
  }
}
