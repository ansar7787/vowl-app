import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/features/speaking/scene_description_speaking/presentation/widgets/radar_beacon_painter.dart';

class SceneDescriptionScenicRadarMap extends StatelessWidget {
  final String sceneTitle;
  final Set<int> inspectedHotspots;
  final int activeHotspot;
  final List<String> hotspotLabels;
  final AnimationController radarController;
  final Color primaryColor;
  final bool isDark;
  final Function(int) onHotspotTap;

  const SceneDescriptionScenicRadarMap({
    super.key,
    required this.sceneTitle,
    required this.inspectedHotspots,
    required this.activeHotspot,
    required this.hotspotLabels,
    required this.radarController,
    required this.primaryColor,
    required this.isDark,
    required this.onHotspotTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw,
      height: 230.h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131326) : Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15.r,
          )
        ],
      ),
      child: Stack(
        children: [
          // Background atmospheric visualizer waves
          Positioned.fill(
            child: AnimatedBuilder(
              animation: radarController,
              builder: (context, child) {
                return CustomPaint(
                  painter: RadarBeaconPainter(
                    progress: radarController.value,
                    isActive: false,
                    isCompleted: false,
                    primaryColor: primaryColor,
                  ),
                );
              },
            ),
          ),

          // Central Scene Title
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_size_select_large_rounded, color: primaryColor, size: 36.r),
                  SizedBox(height: 8.h),
                  Text(
                    sceneTitle.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    "${inspectedHotspots.length} OF 3 FEATURES STABILIZED",
                    style: GoogleFonts.shareTechMono(
                      fontSize: 10.sp,
                      color: inspectedHotspots.length == 3 ? Colors.greenAccent : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3 Dynamic Sonar Hotspots in top-left, top-right, bottom-center
          _buildPulsingBeacon(0, Alignment.topLeft),
          _buildPulsingBeacon(1, Alignment.topRight),
          _buildPulsingBeacon(2, Alignment.bottomCenter),
        ],
      ),
    );
  }

  Widget _buildPulsingBeacon(int index, Alignment alignment) {
    if (hotspotLabels.length <= index) return const SizedBox();
    
    final isInspected = inspectedHotspots.contains(index);
    final isActive = activeHotspot == index;

    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.all(22.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => onHotspotTap(index),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: radarController,
                    builder: (context, child) {
                      return SizedBox(
                        width: 52.r,
                        height: 52.r,
                        child: CustomPaint(
                          painter: RadarBeaconPainter(
                            progress: radarController.value,
                            isActive: isActive,
                            isCompleted: isInspected,
                            primaryColor: primaryColor,
                          ),
                        ),
                      );
                    },
                  ),
                  // Icon indicator
                  Container(
                    width: 32.r,
                    height: 32.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isInspected
                          ? Colors.greenAccent
                          : (isActive ? primaryColor : Colors.black26),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Icon(
                      isInspected
                          ? Icons.check_rounded
                          : (isActive ? Icons.spatial_tracking_rounded : Icons.radar_rounded),
                      color: Colors.white,
                      size: 14.r,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              hotspotLabels[index].toUpperCase(),
              style: GoogleFonts.shareTechMono(
                fontSize: 8.sp,
                color: isInspected
                    ? Colors.greenAccent
                    : (isActive ? primaryColor : Colors.grey),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
