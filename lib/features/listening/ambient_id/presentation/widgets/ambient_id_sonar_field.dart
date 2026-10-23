import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Radar sonar circular field displaying ambient sound location options.
///
/// Sweeps an animated radar beam around concentric rings and positions
/// selectable location hubs radially for the user to choose the ambient source.
class AmbientIdSonarField extends StatelessWidget {
  /// Available location option labels.
  final List<String> options;

  /// Index of the correct location option.
  final int correctAnswerIndex;

  /// Theme accent color.
  final Color color;

  /// Animation controller driving the 360-degree radar sweep.
  final AnimationController radarController;

  /// Whether the user has submitted an answer for this question.
  final bool isAnswered;

  /// Whether the submitted answer was correct (`null` if pending evaluation).
  final bool? isCorrectState;

  /// Currently selected option index, if any.
  final int? selectedIndex;

  /// Callback invoked when an option hub is tapped.
  final Function(int) onSubmitAnswer;

  /// Optional background image URL.
  final String? imageUrl;

  /// Creates an [AmbientIdSonarField] instance.
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
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 380.h,
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 380.r,
          height: 380.r,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Image Background (if any)
              if (imageUrl != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  width: 320.r,
                  height: 320.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(imageUrl!),
                      fit: BoxFit.cover,
                      colorFilter: isCorrectState == true
                          ? null
                          : ColorFilter.mode(
                              Colors.black.withValues(alpha: 0.6),
                              BlendMode.darken,
                            ),
                    ),
                  ),
                  child: isCorrectState == true
                      ? const SizedBox()
                      : ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 25.0,
                              sigmaY: 25.0,
                            ),
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                ),

              // Radar Sweep Animation
              AnimatedBuilder(
                animation: radarController,
                builder: (context, child) {
                  if (VowlMotion.shouldReduceMotion(context)) {
                    return child!;
                  }
                  return Transform.rotate(
                    angle: radarController.value * 6.28,
                    child: child,
                  );
                },
                child: Container(
                  width: 380.r,
                  height: 380.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        color.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.1, 0.25],
                    ),
                  ),
                ),
              ),

              // Spatial Rings
              ...List.generate(
                3,
                (i) => Container(
                  width: (i + 1) * 120.r,
                  height: (i + 1) * 120.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.12),
                      width: 1.2,
                    ),
                  ),
                ),
              ),

              // Subtle center blip
              Container(
                width: 14.r,
                height: 14.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.3),
                  border: Border.all(
                    color: color.withValues(alpha: 0.7),
                    width: 2,
                  ),
                ),
              ),

              // Location Hubs
              ...List.generate(options.length, (index) {
                double angle = (index * 6.28 / options.length) - 1.57;
                double dist = 126.r;
                return Transform.translate(
                  offset: Offset(dist * cos(angle), dist * sin(angle)),
                  child: _buildLocationHub(context, index, options[index]),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationHub(BuildContext context, int index, String text) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final Color modernCorrect = tokens?.gameCorrect ?? AppColors.gameCorrect;
    final Color modernIncorrect = tokens?.gameIncorrect ?? AppColors.gameIncorrect;

    bool isSelected = selectedIndex == index;
    bool isChoiceCorrect =
        isAnswered && index == correctAnswerIndex && isCorrectState == true;
    bool isChoiceWrong = isAnswered && isSelected && isCorrectState == false;

    Color cardBgColor;
    Color borderColor;
    Color textColor;

    if (isChoiceCorrect) {
      cardBgColor = modernCorrect;
      borderColor = Colors.white.withValues(alpha: 0.85);
      textColor = Colors.white;
    } else if (isChoiceWrong) {
      cardBgColor = modernIncorrect;
      borderColor = Colors.white.withValues(alpha: 0.85);
      textColor = Colors.white;
    } else if (isSelected) {
      cardBgColor = color;
      borderColor = Colors.white.withValues(alpha: 0.85);
      textColor = Colors.white;
    } else {
      cardBgColor = isDark
          ? const Color(0xFF1E1E24)
          : Colors.white;
      borderColor = color.withValues(alpha: isDark ? 0.35 : 0.22);
      textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    }

    Widget hub = Container(
      constraints: BoxConstraints(
        minWidth: 96.r,
        maxWidth: 116.r,
        minHeight: 58.r,
        maxHeight: 70.r,
      ),
      padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 6.r),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: borderColor,
          width: isSelected || isChoiceCorrect || isChoiceWrong ? 2.0 : 1.5,
        ),
        boxShadow: [
          if (isSelected || isChoiceCorrect || isChoiceWrong)
            BoxShadow(
              color: cardBgColor.withValues(alpha: 0.35),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            offset: const Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getLocationIcon(text),
              color: textColor,
              size: 19.r,
            ),
            SizedBox(height: 3.h),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 96.r),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: textColor,
                    height: 1.2,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!reduceMotion) {
      hub = hub
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.03, 1.03),
            duration: 1600.ms,
            delay: (index * 250).ms,
          );
    }

    return ScaleButton(
      key: ValueKey('ambient_hub_$index'),
      onTap: isAnswered ? null : () => onSubmitAnswer(index),
      child: hub,
    );
  }

  IconData _getLocationIcon(String loc) {
    final l = loc.toLowerCase();
    if (l.contains('forest') || l.contains('wood') || l.contains('jungle')) {
      return Icons.forest_rounded;
    }
    if (l.contains('cyber') || l.contains('city') || l.contains('downtown') || l.contains('street')) {
      return Icons.location_city_rounded;
    }
    if (l.contains('station')) {
      return Icons.settings_input_antenna_rounded;
    }
    if (l.contains('space') || l.contains('orbit') || l.contains('galaxy')) {
      return Icons.rocket_launch_rounded;
    }
    if (l.contains('airport') || l.contains('flight') || l.contains('terminal') || l.contains('plane')) {
      return Icons.local_airport_rounded;
    }
    if (l.contains('train') || l.contains('subway') || l.contains('metro') || l.contains('platform') || l.contains('rail')) {
      return Icons.train_rounded;
    }
    if (l.contains('library') || l.contains('book') || l.contains('study')) {
      return Icons.local_library_rounded;
    }
    if (l.contains('school') || l.contains('classroom') || l.contains('college') || l.contains('university')) {
      return Icons.school_rounded;
    }
    if (l.contains('mall') || l.contains('shop') || l.contains('store') || l.contains('supermarket') || l.contains('market') || l.contains('checkout') || l.contains('retail')) {
      return Icons.local_mall_rounded;
    }
    if (l.contains('restaurant') || l.contains('cafe') || l.contains('bakery') || l.contains('kitchen') || l.contains('diner') || l.contains('coffee')) {
      return Icons.restaurant_rounded;
    }
    if (l.contains('park') || l.contains('garden') || l.contains('trail')) {
      return Icons.park_rounded;
    }
    if (l.contains('hospital') || l.contains('clinic') || l.contains('doctor') || l.contains('pharmacy')) {
      return Icons.local_hospital_rounded;
    }
    if (l.contains('gym') || l.contains('workout') || l.contains('fitness') || l.contains('sport')) {
      return Icons.fitness_center_rounded;
    }
    if (l.contains('ocean') || l.contains('sea') || l.contains('deep') || l.contains('water') || l.contains('dock') || l.contains('ferry')) {
      return Icons.waves_rounded;
    }
    if (l.contains('beach') || l.contains('coast') || l.contains('island')) {
      return Icons.beach_access_rounded;
    }
    if (l.contains('base') || l.contains('military')) {
      return Icons.security_rounded;
    }
    if (l.contains('lab') || l.contains('science') || l.contains('research')) {
      return Icons.science_rounded;
    }
    if (l.contains('temple') || l.contains('church') || l.contains('shrine') || l.contains('mosque')) {
      return Icons.temple_hindu_rounded;
    }
    if (l.contains('vault') || l.contains('safe')) {
      return Icons.lock_rounded;
    }
    if (l.contains('arcade') || l.contains('game') || l.contains('cinema') || l.contains('theater')) {
      return Icons.sports_esports_rounded;
    }
    if (l.contains('home') || l.contains('house') || l.contains('room') || l.contains('living')) {
      return Icons.home_rounded;
    }
    return Icons.place_rounded;
  }
}
