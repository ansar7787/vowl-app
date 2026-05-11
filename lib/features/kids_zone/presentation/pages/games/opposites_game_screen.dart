import 'package:flutter/material.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_picker_template.dart';

class OppositesGameScreen extends StatelessWidget {
  final int level;
  const OppositesGameScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return KidsPickerTemplate(
      title: "Opposites",
      gameType: "opposites",
      level: level,
      primaryColor: const Color(0xFF94A3B8), // Slate 400
      backgroundColors: const [], // Using Unified Background
      fallbackIcon: Icons.compare_rounded,
    );
  }
}
