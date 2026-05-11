import 'package:flutter/material.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_picker_template.dart';

class ClothingGameScreen extends StatelessWidget {
  final int level;
  const ClothingGameScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return KidsPickerTemplate(
      title: "Dress Up",
      gameType: "clothing",
      level: level,
      primaryColor: const Color(0xFF8B5CF6),
      backgroundColors: const [], // Using Unified Background
      fallbackIcon: Icons.checkroom_rounded,
      centerTextOverride: null,
    );
  }
}
