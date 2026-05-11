import 'package:flutter/material.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_picker_template.dart';

class PrepositionsGameScreen extends StatelessWidget {
  final int level;
  const PrepositionsGameScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return KidsPickerTemplate(
      title: "Prepositions",
      gameType: "prepositions",
      level: level,
      primaryColor: const Color(0xFF64748B), // Slate 500
      backgroundColors: const [], // Using Unified Background
      fallbackIcon: Icons.location_on_rounded,
    );
  }
}
