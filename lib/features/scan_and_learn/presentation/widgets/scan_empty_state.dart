import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

class ScanEmptyState extends StatelessWidget {
  final Future<void> Function(ImageSource) onPickImage;

  const ScanEmptyState({
    super.key,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white : const Color(0xFF6366F1);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Laser Scanner
          SizedBox(
            height: 180.r,
            width: 140.r,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Viewfinder Corners
                _buildViewfinderCorner(Alignment.topLeft, iconColor),
                _buildViewfinderCorner(Alignment.topRight, iconColor),
                _buildViewfinderCorner(Alignment.bottomLeft, iconColor),
                _buildViewfinderCorner(Alignment.bottomRight, iconColor),

                // Center Icon
                Icon(Icons.description_outlined, size: 80.r, color: iconColor.withValues(alpha: 0.2)),

                // Moving Laser Line
                Positioned(
                  top: 0,
                  left: 20.w,
                  right: 20.w,
                  child: Container(
                    height: 2.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF6366F1), blurRadius: 10, spreadRadius: 2),
                      ],
                    ),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true)).moveY(begin: 10.h, end: 170.h, duration: 1.5.seconds, curve: Curves.easeInOut),
                ),
              ],
            ),
          ),
          SizedBox(height: 32.h),
          Text(
            context.tr('translation.scan_learn_title', fallback: 'Scan & Learn'),
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
              'Capture a photo of text, signs, or menus to instantly translate them to your language.',
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

  Widget _buildViewfinderCorner(Alignment alignment, Color color) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 32.r,
        height: 32.r,
        decoration: BoxDecoration(
          border: Border(
            top: (alignment == Alignment.topLeft || alignment == Alignment.topRight) ? BorderSide(color: color, width: 4) : BorderSide.none,
            bottom: (alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight) ? BorderSide(color: color, width: 4) : BorderSide.none,
            left: (alignment == Alignment.topLeft || alignment == Alignment.bottomLeft) ? BorderSide(color: color, width: 4) : BorderSide.none,
            right: (alignment == Alignment.topRight || alignment == Alignment.bottomRight) ? BorderSide(color: color, width: 4) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: alignment == Alignment.topLeft ? Radius.circular(8.r) : Radius.zero,
            topRight: alignment == Alignment.topRight ? Radius.circular(8.r) : Radius.zero,
            bottomLeft: alignment == Alignment.bottomLeft ? Radius.circular(8.r) : Radius.zero,
            bottomRight: alignment == Alignment.bottomRight ? Radius.circular(8.r) : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassAction(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap, required bool isDark}) {
    return ScaleButton(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r), // Sharper structural corners
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 5)),
              ],
            ),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 36.r),
                SizedBox(height: 12.h),
                Text(
                  label, 
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 16.sp, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
