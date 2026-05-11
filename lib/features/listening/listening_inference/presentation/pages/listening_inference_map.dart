import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class ListeningInferenceMap extends StatelessWidget {
  const ListeningInferenceMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'listeningInference',
      categoryId: 'listening',
    );
  }
}
