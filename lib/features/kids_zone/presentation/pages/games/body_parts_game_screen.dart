import 'package:flutter/material.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_picker_template.dart';

class BodyPartsGameScreen extends StatelessWidget {
  final int level;
  const BodyPartsGameScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return KidsPickerTemplate(
      title: "My Body",
      gameType: "body_parts",
      level: level,
      primaryColor: const Color(0xFFF43F5E),
      backgroundColors: const [], // Using Unified Background
      fallbackIcon: Icons.accessibility_new_rounded,
      centerTextOverride: null,
    );
  }
}
