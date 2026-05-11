import 'package:flutter/material.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_picker_template.dart';

class TimeGameScreen extends StatelessWidget {
  final int level;
  const TimeGameScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return KidsPickerTemplate(
      title: "Tell the Time",
      gameType: "time",
      level: level,
      primaryColor: const Color(0xFF333333), // Dark Gray
      backgroundColors: const [], // Using Unified Background
      fallbackIcon: Icons.access_time_filled_rounded,
    );
  }
}
