import 'package:flutter/material.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_picker_template.dart';

class PhonicsGameScreen extends StatelessWidget {
  final int level;
  const PhonicsGameScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return KidsPickerTemplate(
      title: "Phonics Fun",
      gameType: "phonics",
      level: level,
      primaryColor: const Color(0xFFFFCC00), // Yellow 500
      backgroundColors: const [], // Using Unified Background
      fallbackIcon: Icons.volume_up_rounded,
    );
  }
}
