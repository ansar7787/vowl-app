import 'package:flutter/material.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_picker_template.dart';

class NatureGameScreen extends StatelessWidget {
  final int level;
  const NatureGameScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return KidsPickerTemplate(
      title: "Nature Walk",
      gameType: "nature",
      level: level,
      primaryColor: const Color(0xFF16A34A), // Green 600
      backgroundColors: const [], // Using Unified Background
      fallbackIcon: Icons.park_rounded,
    );
  }
}
