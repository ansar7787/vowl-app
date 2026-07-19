import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';

import 'package:vowl/core/presentation/widgets/pedagogical_rule_box.dart';

class ConsonantClarityExplanationCard extends StatelessWidget {
  final AccentQuest quest;
  final Color color;
  final bool isDark;

  const ConsonantClarityExplanationCard({
    super.key,
    required this.quest,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (quest.mouthPosition == null) return const SizedBox();

    return PedagogicalRuleBox(
      icon: Icons.face_retouching_natural,
      capsKey: 'games.mouth_position_caps',
      capsFallback: 'MOUTH POSITION',
      titleKey: 'games.mouth_position',
      titleFallback: 'Mouth Position',
      rule: quest.mouthPosition!,
      shadowColor: color,
      isDark: isDark,
    ).animate().fadeIn().slideY(begin: 0.2);
  }
}
