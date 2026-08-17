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

  const ScanEmptyState({super.key, required this.onPickImage});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Standby AI Core Radar
          Container(
            height: 200.r,
            width: 200.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                width: 1.w,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing rings
                Container(
                      height: 140.r,
                      width: 140.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                          width: 1.5.w,
                        ),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 0.9, end: 1.1, duration: 2.seconds),
                // Glowing Core
                Container(
                  height: 80.r,
                  width: 80.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child:
                      Icon(
                            Icons.document_scanner_rounded,
                            size: 40.r,
                            color: const Color(0xFF6366F1),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .fade(begin: 0.5, end: 1.0, duration: 1.seconds),
                ),
                // Radar sweep line
                Positioned.fill(
                      child: Center(
                        child: Container(
                          width: 2.w,
                          height: 180.r,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6366F1).withValues(alpha: 0.0),
                                const Color(0xFF6366F1).withValues(alpha: 0.8),
                                const Color(0xFF6366F1).withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .rotate(duration: 4.seconds),
              ],
            ),
          ),
          SizedBox(height: 32.h),
          Text(
                "SYSTEM STANDBY",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF6366F1),
                  letterSpacing: 4.0,
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(duration: 800.ms),
          SizedBox(height: 8.h),
          Text(
            context.tr(
              'translation.scan_learn_title',
              fallback: 'Scan & Learn',
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 32.sp,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              context.tr(
                'translation.scan_learn_desc',
                fallback:
                    'Capture a photo of text, signs, or menus to instantly translate them to your language.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
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
        borderRadius: BorderRadius.circular(24.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.15),
                  const Color(0xFF4F46E5).withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                width: 1.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(icon, color: const Color(0xFF6366F1), size: 36.r),
                SizedBox(height: 12.h),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
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
