import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';

class BranchingDialogueMap extends StatelessWidget {
  const BranchingDialogueMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernCategoryMap(
      gameType: 'branchingDialogue',
      categoryId: 'roleplay',
    );
  }
}
