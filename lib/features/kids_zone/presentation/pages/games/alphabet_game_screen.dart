import 'package:flutter/material.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_picker_template.dart';

class AlphabetGameScreen extends StatelessWidget {
  final int level;
  const AlphabetGameScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return KidsPickerTemplate(
      title: "Alphabet Fun",
      gameType: "alphabet",
      level: level,
      primaryColor: const Color(0xFFF43F5E), // Rose 500
      backgroundColors: const [],
      fallbackIcon: Icons.abc_rounded,
      // In Alphabet game, we want to show the Letter in the center if no image is provided
      centerTextOverride: null, // It will use quest.question automatically if needed
    );
  }
}
