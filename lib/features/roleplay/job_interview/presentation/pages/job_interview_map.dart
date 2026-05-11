import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class JobInterviewMap extends StatelessWidget {
  const JobInterviewMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'jobInterview',
      categoryId: 'roleplay',
    );
  }
}
