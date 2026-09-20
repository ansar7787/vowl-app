import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color00b4db = Color(0xFF00B4DB);
  static const Color color0083b0 = Color(0xFF0083B0);
  static const Color color1e1b4b = Color(0xFF1E1B4B);
  static const Color color1a237e = Color(0xFF1A237E);
  static const Color color3949ab = Color(0xFF3949AB);
  static const Color color831843 = Color(0xFF831843);
  static const Color color500724 = Color(0xFF500724);
  static const Color colorffc0cb = Color(0xFFFFC0CB);
  static const Color colorf8bbd0 = Color(0xFFF8BBD0);
  static const Color color064e3b = Color(0xFF064E3B);
  static const Color color022c22 = Color(0xFF022C22);
  static const Color color388e3c = Color(0xFF388E3C);
  static const Color colorc8e6c9 = Color(0xFFC8E6C9);
}

class KidsBackgroundRenderer extends StatelessWidget {
  final String painterName;
  final String shaderName;
  final Color primaryColor;
  final String gameType;

  const KidsBackgroundRenderer({
    super.key,
    required this.painterName,
    required this.shaderName,
    required this.primaryColor,
    required this.gameType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Use specific colors for special themes, otherwise use the primaryColor mesh from the Level Map
    List<Color> gradientColors;

    if (painterName == 'OceanWave') {
      gradientColors = [
        _LocalPalette.color00b4db,
        _LocalPalette.color0083b0,
        _LocalPalette.color00b4db,
      ];
    } else if (painterName == 'StarryNight') {
      gradientColors = isDark
          ? [
              _LocalPalette.color1e1b4b,
              AppColors.slate900,
              _LocalPalette.color1e1b4b,
            ]
          : [
              _LocalPalette.color1a237e,
              _LocalPalette.color3949ab,
              _LocalPalette.color1a237e,
            ];
    } else if (painterName == 'CandyCloud') {
      gradientColors = isDark
          ? [
              _LocalPalette.color831843,
              _LocalPalette.color500724,
              _LocalPalette.color831843,
            ]
          : [
              _LocalPalette.colorffc0cb,
              _LocalPalette.colorf8bbd0,
              _LocalPalette.colorffc0cb,
            ];
    } else if (painterName == 'ForestFriend') {
      gradientColors = isDark
          ? [
              _LocalPalette.color064e3b,
              _LocalPalette.color022c22,
              _LocalPalette.color064e3b,
            ]
          : [
              _LocalPalette.color388e3c,
              _LocalPalette.colorc8e6c9,
              _LocalPalette.color388e3c,
            ];
    } else {
      // Default: The Kids Level Map "Mesh Gradient" aesthetic based on primaryColor
      gradientColors = isDark
          ? [
              primaryColor.withAlpha(100),
              AppColors.slate900,
              primaryColor.withAlpha(80),
            ]
          : [
              primaryColor.withAlpha(60),
              AppColors.slate50,
              primaryColor.withAlpha(40),
            ];
    }

    return Stack(
      children: [
        Positioned.fill(
          child: MeshGradientBackground(
            colors: gradientColors,
          ).animate().fadeIn(duration: 400.ms),
        ),

        // Top Cloud - Moving left to right
        Positioned(
              top: 100.h,
              left: -150.w, // Start fully off-screen left
              child: _buildCloud(context, 180.w),
            )
            .animate(
              onPlay: (controller) => controller.repeat(),
            ) // No reverse, infinite loop
            .moveX(
              begin: 0,
              end: screenWidth + 300.w, // Move fully off-screen right
              duration: 25.seconds,
              curve: Curves.linear,
            ),

        // Bottom Cloud - Moving right to left
        Positioned(
              bottom: 250.h,
              right: -150.w, // Start fully off-screen right
              child: _buildCloud(context, 160.w),
            )
            .animate(onPlay: (controller) => controller.repeat())
            .moveX(
              begin: 0,
              end: -(screenWidth + 300.w), // Move fully off-screen left
              duration: 35.seconds,
              curve: Curves.linear,
            ),

        // Extra middle cloud for depth
        Positioned(
              top: 300.h,
              left: -100.w,
              child: _buildCloud(context, 100.w, opacity: 0.5),
            )
            .animate(onPlay: (controller) => controller.repeat())
            .moveX(
              begin: 0,
              end: screenWidth + 200.w,
              duration: 45.seconds,
              curve: Curves.linear,
            ),
      ],
    );
  }

  Widget _buildCloud(
    BuildContext context,
    double width, {
    double opacity = 1.0,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Icon(
      Icons.cloud_rounded,
      color: (isDark ? Colors.white.withAlpha(15) : Colors.white).withAlpha(
        (180 * opacity).round(),
      ),
      size: width,
    );
  }
}
