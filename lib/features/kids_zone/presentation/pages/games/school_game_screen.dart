import 'package:flutter/material.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_picker_template.dart';

class SchoolGameScreen extends StatelessWidget {
  final int level;
  const SchoolGameScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return KidsPickerTemplate(
      title: "School Time",
      gameType: "school",
      level: level,
      primaryColor: const Color(0xFF6366F1), // Indigo 500
      backgroundColors: const [], // Using Unified Background
      fallbackIcon: Icons.school_rounded,
    );
  }
}
