import 'package:flutter/material.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_picker_template.dart';

class AnimalsGameScreen extends StatelessWidget {
  final int level;
  const AnimalsGameScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return KidsPickerTemplate(
      title: "Animal Friends",
      gameType: "animals",
      level: level,
      primaryColor: const Color(0xFF6366F1), // Indigo 500
      backgroundColors: const [], // Using Unified Background
      fallbackIcon: Icons.pets_rounded,
    );
  }
}
