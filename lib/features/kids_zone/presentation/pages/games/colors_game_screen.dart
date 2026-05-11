import 'package:flutter/material.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_picker_template.dart';

class ColorsGameScreen extends StatelessWidget {
  final int level;
  const ColorsGameScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return KidsPickerTemplate(
      title: "Color Fun",
      gameType: "colors",
      level: level,
      primaryColor: const Color(0xFFF59E0B), // Amber 500
      backgroundColors: const [], // Using Unified Background
      fallbackIcon: Icons.palette_rounded,
    );
  }
}
