import 'package:flutter/material.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_picker_template.dart';

class TransportGameScreen extends StatelessWidget {
  final int level;
  const TransportGameScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return KidsPickerTemplate(
      title: "Vroom Vroom!",
      gameType: "transport",
      level: level,
      primaryColor: const Color(0xFF3B82F6), // Blue 500
      backgroundColors: const [], // Using Unified Background
      fallbackIcon: Icons.directions_car_rounded,
    );
  }
}
