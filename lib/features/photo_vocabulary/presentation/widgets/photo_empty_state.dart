import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

class PhotoEmptyState extends StatelessWidget {
  final Future<void> Function(ImageSource) onPickImage;

  const PhotoEmptyState({super.key, required this.onPickImage});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white : const Color(0xFF14B8A6);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Radar/Sonar
          SizedBox(
            height: 200.r,
            width: 200.r,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Expanding Ripple 1
                Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .scaleXY(begin: 0.5, end: 1.5, duration: 2.5.seconds)
                    .fade(begin: 0.8, end: 0.0),

                // Expanding Ripple 2
                Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF14B8A6).withValues(alpha: 0.5),
                          width: 3,
                        ),
                      ),
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .scaleXY(
                      begin: 0.5,
                      end: 1.5,
                      duration: 2.5.seconds,
                      delay: 1.2.seconds,
                    )
                    .fade(begin: 0.8, end: 0.0),

                // Solid Center Circle
                Container(
                  height: 100.r,
                  width: 100.r,
                  decoration: BoxDecoration(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                ),

                // Center Icon
                Icon(LucideIcons.camera, size: 48.r, color: iconColor)
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .scaleXY(begin: 0.9, end: 1.1, duration: 1.5.seconds),
              ],
            ),
          ),
          SizedBox(height: 32.h),
          Text(
            context.tr(
              'vocabulary.photo_prompt',
              fallback: 'Discover words around you!',
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 26.sp,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              'Snap a photo and let our AI engine instantly identify objects in your environment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: 48.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGlassAction(
                context,
                icon: LucideIcons.camera,
                label: context.tr('common.camera', fallback: 'Camera'),
                onTap: () => onPickImage(ImageSource.camera),
                isDark: isDark,
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
              SizedBox(width: 24.w),
              _buildGlassAction(
                context,
                icon: LucideIcons.image,
                label: context.tr('common.gallery', fallback: 'Gallery'),
                onTap: () => onPickImage(ImageSource.gallery),
                isDark: isDark,
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms);
  }

  Widget _buildGlassAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ScaleButton(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          40.r,
        ), // Pill shape for organic feel
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: const Color(0xFF14B8A6),
              borderRadius: BorderRadius.circular(40.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              // Row layout for pill shape
              children: [
                Icon(icon, color: Colors.white, size: 24.r),
                SizedBox(width: 8.w),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
