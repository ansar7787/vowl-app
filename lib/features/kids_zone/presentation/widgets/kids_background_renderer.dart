import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';

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
        const Color(0xFF00B4DB),
        const Color(0xFF0083B0),
        const Color(0xFF00B4DB),
      ];
    } else if (painterName == 'StarryNight') {
      gradientColors = isDark
          ? [
              const Color(0xFF1E1B4B),
              const Color(0xFF0F172A),
              const Color(0xFF1E1B4B),
            ]
          : [
              const Color(0xFF1A237E),
              const Color(0xFF3949AB),
              const Color(0xFF1A237E),
            ];
    } else if (painterName == 'CandyCloud') {
      gradientColors = isDark
          ? [
              const Color(0xFF831843),
              const Color(0xFF500724),
              const Color(0xFF831843),
            ]
          : [
              const Color(0xFFFFC0CB),
              const Color(0xFFF8BBD0),
              const Color(0xFFFFC0CB),
            ];
    } else if (painterName == 'ForestFriend') {
      gradientColors = isDark
          ? [
              const Color(0xFF064E3B),
              const Color(0xFF022C22),
              const Color(0xFF064E3B),
            ]
          : [
              const Color(0xFF388E3C),
              const Color(0xFFC8E6C9),
              const Color(0xFF388E3C),
            ];
    } else {
      // Default: The Kids Level Map "Mesh Gradient" aesthetic based on primaryColor
      gradientColors = isDark
          ? [
              primaryColor.withAlpha(100),
              const Color(0xFF0F172A),
              primaryColor.withAlpha(80),
            ]
          : [
              primaryColor.withAlpha(60),
              const Color(0xFFF8FAFC),
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
