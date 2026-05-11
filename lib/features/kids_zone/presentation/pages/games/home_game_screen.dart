import 'package:flutter/material.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_picker_template.dart';

class HomeGameScreen extends StatelessWidget {
  final int level;
  const HomeGameScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return KidsPickerTemplate(
      title: "My Home",
      gameType: "home_kids",
      level: level,
      primaryColor: const Color(0xFF8B5CF6), // Violet 500
      backgroundColors: const [], // Using Unified Background
      fallbackIcon: Icons.home_rounded,
    );
  }
}
