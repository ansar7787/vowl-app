import 'package:flutter/material.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_picker_template.dart';

class NumbersGameScreen extends StatelessWidget {
  final int level;
  const NumbersGameScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return KidsPickerTemplate(
      title: "Number Fun",
      gameType: "numbers",
      level: level,
      primaryColor: const Color(0xFF0EA5E9), // Sky 500
      backgroundColors: const [], // Using Unified Background
      fallbackIcon: Icons.numbers_rounded,
    );
  }
}
