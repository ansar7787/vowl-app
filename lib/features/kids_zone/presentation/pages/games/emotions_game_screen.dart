import 'package:flutter/material.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_picker_template.dart';

class EmotionsGameScreen extends StatelessWidget {
  final int level;
  const EmotionsGameScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return KidsPickerTemplate(
      title: "How I Feel",
      gameType: "emotions",
      level: level,
      primaryColor: const Color(0xFFFACC15), // Yellow 400
      backgroundColors: const [], // Using Unified Background
      fallbackIcon: Icons.face_rounded,
    );
  }
}
