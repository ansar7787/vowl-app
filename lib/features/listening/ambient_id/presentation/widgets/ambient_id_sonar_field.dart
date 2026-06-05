import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class AmbientIdSonarField extends StatelessWidget {
  final List<String> options;
  final int correctAnswerIndex;
  final Color color;
  final AnimationController radarController;
  final bool isAnswered;
  final bool? isCorrectState;
  final int? selectedIndex;
  final Function(int) onSubmitAnswer;

  const AmbientIdSonarField({
    super.key,
    required this.options,
    required this.correctAnswerIndex,
    required this.color,
    required this.radarController,
    required this.isAnswered,
    required this.isCorrectState,
    required this.selectedIndex,
    required this.onSubmitAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 380.h,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radar Sweep Animation
          AnimatedBuilder(
            animation: radarController,
            builder: (context, child) {
              return Transform.rotate(
                angle: radarController.value * 6.28,
                child: Container(
                  width: 380.r,
                  height: 380.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [color.withValues(alpha: 0.2), Colors.transparent],
                      stops: const [0.1, 0.25],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Spatial Rings
          ...List.generate(3, (i) => Container(
            width: (i + 1) * 120.r,
            height: (i + 1) * 120.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.1)),
            ),
          )),
          
          // Location Hubs
          ...List.generate(options.length, (index) {
            double angle = (index * 6.28 / options.length) - 1.57;
            double dist = 135.r;
            return Transform.translate(
              offset: Offset(dist * cos(angle), dist * sin(angle)),
              child: _buildLocationHub(index, options[index]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLocationHub(int index, String text) {
    bool isSelected = selectedIndex == index;
    bool isChoiceCorrect = isAnswered && index == correctAnswerIndex && isCorrectState == true;
    bool isChoiceWrong = isAnswered && isSelected && isCorrectState == false;

    return ScaleButton(
      onTap: () => onSubmitAnswer(index),
      child: Container(
        width: 90.r,
        height: 90.r,
        decoration: BoxDecoration(
          color: isChoiceCorrect 
              ? Colors.greenAccent 
              : (isChoiceWrong ? Colors.redAccent : (isSelected ? color : const Color(0xFF1E1E24))),
          shape: BoxShape.circle,
          border: Border.all(
            color: isChoiceCorrect || isChoiceWrong || isSelected 
                ? Colors.white.withValues(alpha: 0.5) 
                : color.withValues(alpha: 0.3), 
            width: 2,
          ),
          boxShadow: [
            if (isSelected || isChoiceCorrect || isChoiceWrong) 
              BoxShadow(
                color: (isChoiceCorrect ? Colors.greenAccent : (isChoiceWrong ? Colors.redAccent : color)).withValues(alpha: 0.4), 
                blurRadius: 15, 
                spreadRadius: 2,
              ),
            // Permanent subtle base shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_getLocationIcon(text), color: Colors.white, size: 22.r),
              SizedBox(height: 4.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: FittedBox(
                  child: Text(
                    text.toUpperCase(), 
                    textAlign: TextAlign.center, 
                    style: TextStyle(fontFamily: 'RobotoMono', fontSize: 8.sp, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getLocationIcon(String loc) {
    final l = loc.toLowerCase();
    if (l.contains('forest')) return Icons.forest_rounded;
    if (l.contains('cyber') || l.contains('city')) return Icons.location_city_rounded;
    if (l.contains('space')) return Icons.rocket_launch_rounded;
    if (l.contains('ocean') || l.contains('deep')) return Icons.waves_rounded;
    if (l.contains('base') || l.contains('military')) return Icons.security_rounded;
    if (l.contains('lab')) return Icons.science_rounded;
    if (l.contains('temple')) return Icons.temple_hindu_rounded;
    if (l.contains('vault')) return Icons.lock_rounded;
    if (l.contains('station')) return Icons.settings_input_antenna_rounded;
    if (l.contains('airport')) return Icons.local_airport_rounded;
    if (l.contains('train')) return Icons.train_rounded;
    if (l.contains('library')) return Icons.local_library_rounded;
    if (l.contains('mall')) return Icons.local_mall_rounded;
    if (l.contains('restaurant')) return Icons.restaurant_rounded;
    if (l.contains('park')) return Icons.park_rounded;
    return Icons.place_rounded;
  }
}
