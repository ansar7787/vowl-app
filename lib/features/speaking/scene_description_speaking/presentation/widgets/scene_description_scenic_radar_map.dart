import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/speaking/scene_description_speaking/presentation/widgets/radar_beacon_painter.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color131326 = Color(0xFF131326);
}

/// Interactive scenic radar canvas presenting hotspot beacons that users tap to describe.
class SceneDescriptionScenicRadarMap extends StatelessWidget {
  /// Environmental title of the active scene.
  final String sceneTitle;

  /// Set of hotspot indices already successfully described.
  final Set<int> inspectedHotspots;

  /// Index of the actively selected hotspot.
  final int activeHotspot;

  /// Descriptive labels attached to each hotspot node.
  final List<String> hotspotLabels;

  /// Animation controller driving the rotating radar sweep.
  final AnimationController radarController;

  /// Primary theme accent color.
  final Color primaryColor;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Callback triggered when a hotspot beacon is tapped.
  final Function(int) onHotspotTap;

  /// Creates a [SceneDescriptionScenicRadarMap].
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
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations == true ||
        VowlMotion.lowAnimationModeOverride.value;

    return Container(
      key: const Key('scene_description_scenic_radar_map'),
      width: 1.sw,
      height: 240.h,
      decoration: BoxDecoration(
        color: isDark ? _LocalPalette.color131326 : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black38
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 16.r,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background atmospheric visualizer waves
          if (!disableAnimations)
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

          // Central Scene Title & Progress
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 44.w),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_size_select_large_rounded,
                      color: primaryColor,
                      size: 34.r,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      sceneTitle,
                      key: const Key('scene_description_title_text'),
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: 0.5,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      "${inspectedHotspots.length} of ${hotspotLabels.length} items described",
                      key: const Key('scene_description_progress_text'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        color: inspectedHotspots.length == hotspotLabels.length
                            ? tokens.gameCorrect
                            : (isDark ? Colors.white60 : Colors.black54),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3 Dynamic Beacons in top-left, top-right, bottom-center
          _buildPulsingBeacon(0, Alignment.topLeft, disableAnimations),
          _buildPulsingBeacon(1, Alignment.topRight, disableAnimations),
          _buildPulsingBeacon(2, Alignment.bottomCenter, disableAnimations),
        ],
      ),
    );
  }

  Widget _buildPulsingBeacon(
    int index,
    Alignment alignment,
    bool disableAnimations,
  ) {
    if (hotspotLabels.length <= index) return const SizedBox();

    final isInspected = inspectedHotspots.contains(index);
    final isActive = activeHotspot == index;
    final label = hotspotLabels[index];

    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Semantics(
          button: true,
          label: 'Beacon ${index + 1}: $label',
          selected: isActive,
          checked: isInspected,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                key: Key('scene_description_beacon_$index'),
                onTap: () => onHotspotTap(index),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!disableAnimations)
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
                      width: 36.r,
                      height: 36.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isInspected
                            ? AppColors.gameCorrect
                            : (isActive ? primaryColor : Colors.black26),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Icon(
                        isInspected
                            ? Icons.check_rounded
                            : (isActive
                                  ? Icons.spatial_tracking_rounded
                                  : Icons.radar_rounded),
                        color: Colors.white,
                        size: 16.r,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 6.h),
              Container(
                constraints: BoxConstraints(maxWidth: 96.w),
                child: Text(
                  label,
                  key: Key('scene_description_beacon_label_$index'),
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    color: isInspected
                        ? AppColors.gameCorrect
                        : (isActive
                              ? primaryColor
                              : (isDark ? Colors.white70 : AppColors.slate700)),
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
