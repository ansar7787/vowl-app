import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color c_00B4DB = Color(0xFF00B4DB);
  static const Color c_0083B0 = Color(0xFF0083B0);
  static const Color c_1E1B4B = Color(0xFF1E1B4B);
  static const Color c_1A237E = Color(0xFF1A237E);
  static const Color c_3949AB = Color(0xFF3949AB);
  static const Color c_831843 = Color(0xFF831843);
  static const Color c_500724 = Color(0xFF500724);
  static const Color c_FFC0CB = Color(0xFFFFC0CB);
  static const Color c_F8BBD0 = Color(0xFFF8BBD0);
  static const Color c_064E3B = Color(0xFF064E3B);
  static const Color c_022C22 = Color(0xFF022C22);
  static const Color c_388E3C = Color(0xFF388E3C);
  static const Color c_C8E6C9 = Color(0xFFC8E6C9);
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
        _LocalPalette.c_00B4DB,
        _LocalPalette.c_0083B0,
        _LocalPalette.c_00B4DB,
      ];
    } else if (painterName == 'StarryNight') {
      gradientColors = isDark
          ? [_LocalPalette.c_1E1B4B, AppColors.slate900, _LocalPalette.c_1E1B4B]
          : [
              _LocalPalette.c_1A237E,
              _LocalPalette.c_3949AB,
              _LocalPalette.c_1A237E,
            ];
    } else if (painterName == 'CandyCloud') {
      gradientColors = isDark
          ? [
              _LocalPalette.c_831843,
              _LocalPalette.c_500724,
              _LocalPalette.c_831843,
            ]
          : [
              _LocalPalette.c_FFC0CB,
              _LocalPalette.c_F8BBD0,
              _LocalPalette.c_FFC0CB,
            ];
    } else if (painterName == 'ForestFriend') {
      gradientColors = isDark
          ? [
              _LocalPalette.c_064E3B,
              _LocalPalette.c_022C22,
              _LocalPalette.c_064E3B,
            ]
          : [
              _LocalPalette.c_388E3C,
              _LocalPalette.c_C8E6C9,
              _LocalPalette.c_388E3C,
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
