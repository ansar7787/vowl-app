import 'package:flutter/material.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_picker_template.dart';

class FoodGameScreen extends StatelessWidget {
  final int level;
  const FoodGameScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return KidsPickerTemplate(
      title: "Yummy Food",
      gameType: "food_kids",
      level: level,
      primaryColor: const Color(0xFFFB923C), // Orange 400
      backgroundColors: const [], // Using Unified Background
      fallbackIcon: Icons.restaurant_rounded,
    );
  }
}
