import 'package:flutter/material.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_picker_template.dart';

class FamilyGameScreen extends StatelessWidget {
  final int level;
  const FamilyGameScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return KidsPickerTemplate(
      title: "My Family",
      gameType: "family",
      level: level,
      primaryColor: const Color(0xFFEC4899), // Pink 500
      backgroundColors: const [], // Using Unified Background
      fallbackIcon: Icons.people_alt_rounded,
    );
  }
}
