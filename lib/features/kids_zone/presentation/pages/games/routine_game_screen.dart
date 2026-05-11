import 'package:flutter/material.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_picker_template.dart';

class RoutineGameScreen extends StatelessWidget {
  final int level;
  const RoutineGameScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return KidsPickerTemplate(
      title: "My Day",
      gameType: "routine",
      level: level,
      primaryColor: const Color(0xFFF97316), // Orange 500
      backgroundColors: const [], // Using Unified Background
      fallbackIcon: Icons.wb_sunny_rounded,
    );
  }
}
