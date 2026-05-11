import 'package:flutter/material.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_picker_template.dart';

class ShapesGameScreen extends StatelessWidget {
  final int level;
  const ShapesGameScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return KidsPickerTemplate(
      title: "Shape Fun",
      gameType: "shapes",
      level: level,
      primaryColor: const Color(0xFF10B981), // Emerald 500
      backgroundColors: const [], // Using Unified Background
      fallbackIcon: Icons.category_rounded,
    );
  }
}
