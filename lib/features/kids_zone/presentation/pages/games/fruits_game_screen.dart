import 'package:flutter/material.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_picker_template.dart';

class FruitsGameScreen extends StatelessWidget {
  final int level;
  const FruitsGameScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return KidsPickerTemplate(
      title: "Fruit Fun",
      gameType: "fruits",
      level: level,
      primaryColor: const Color(0xFFEF4444), // Red 500
      backgroundColors: const [], // Using Unified Background
      fallbackIcon: Icons.shopping_basket_rounded,
    );
  }
}
