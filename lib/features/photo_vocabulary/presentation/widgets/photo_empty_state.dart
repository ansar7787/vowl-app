import 'package:vowl/core/theme/app_colors.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color0d9488 = Color(0xFF0D9488);
  static const Color color2dd4bf = Color(0xFF2DD4BF);
}

/// Placeholder view displayed before a photo has been selected or captured for classification.
class PhotoEmptyState extends StatelessWidget {
  final Future<void> Function(ImageSource) onPickImage;

  const PhotoEmptyState({super.key, required this.onPickImage});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget sweepLine = Center(
      child: Container(
        width: 2.w,
        height: 160.r,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF14B8A6).withValues(alpha: 0.0),
              const Color(0xFF14B8A6).withValues(alpha: 0.8),
              const Color(0xFF14B8A6).withValues(alpha: 0.0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );

    if (!reduceMotion) {
      sweepLine = RepaintBoundary(
        child: sweepLine
            .animate(onPlay: (c) => c.repeat())
            .rotate(duration: 4.seconds),
      );
    }

    final radarSweep = Positioned.fill(child: sweepLine);

    Widget cameraBtn = _buildGlassAction(
      context,
      icon: LucideIcons.camera,
      label: context.tr('common.camera', fallback: 'Camera'),
      subtitle: context.tr(
        'vocabulary.take_photo',
        fallback: 'Take live photo',
      ),
      onTap: () => onPickImage(ImageSource.camera),
      isDark: isDark,
    );
    if (!reduceMotion) {
      cameraBtn = cameraBtn.animate(delay: 200.ms).fadeIn().slideY(begin: 0.2);
    }

    Widget galleryBtn = _buildGlassAction(
      context,
      icon: LucideIcons.image,
      label: context.tr('common.gallery', fallback: 'Gallery'),
      subtitle: context.tr(
        'vocabulary.pick_saved',
        fallback: 'Pick saved photo',
      ),
      onTap: () => onPickImage(ImageSource.gallery),
      isDark: isDark,
    );
    if (!reduceMotion) {
      galleryBtn = galleryBtn
          .animate(delay: 300.ms)
          .fadeIn()
          .slideY(begin: 0.2);
    }

    Widget content = SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Standby AI Core Radar
            ExcludeSemantics(
              child: Container(
                height: 180.r,
                width: 180.r,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.teal500.withValues(alpha: 0.2),
                    width: 1.w,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Pulsing ring
                    Container(
                      height: 125.r,
                      width: 125.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF14B8A6).withValues(alpha: 0.4),
                          width: 1.5.w,
                        ),
                      ),
                    ),
                    // Glowing Core
                    Container(
                      height: 72.r,
                      width: 72.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.teal500.withValues(alpha: 0.15),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal500.withValues(alpha: 0.3),
                            blurRadius: 25,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 34.r,
                        color: AppColors.teal500,
                      ),
                    ),
                    // Radar sweep line inside Stack
                    radarSweep,
                  ],
                ),
              ),
            ),
            SizedBox(height: 24.h),
            // Exploration Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.teal500.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(100.r),
                border: Border.all(
                  color: AppColors.teal500.withValues(alpha: 0.35),
                  width: 1.w,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.sparkles, size: 12.r, color: AppColors.teal500),
                  SizedBox(width: 6.w),
                  Text(
                    context
                        .tr('vocabulary.explore_objects', fallback: 'EXPLORE OBJECTS')
                        .toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? _LocalPalette.color2dd4bf : AppColors.teal500,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              context.tr(
                'vocabulary.photo_vocab_title',
                fallback: 'Photo Vocabulary',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 24.sp,
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                context.tr(
                  'vocabulary.photo_vocab_desc',
                  fallback:
                      'Take a photo of everyday objects around you to learn their names, pronunciations, and meanings.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.35,
                ),
              ),
            ),
            SizedBox(height: 18.h),
            // Scenario Pills
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _buildContextPill(isDark, 'Home & Furniture'),
                _buildContextPill(isDark, 'Kitchen & Food'),
                _buildContextPill(isDark, 'School & Toys'),
              ],
            ),
            SizedBox(height: 28.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: cameraBtn),
                SizedBox(width: 14.w),
                Expanded(child: galleryBtn),
              ],
            ),
          ],
        ),
      ),
    );

    if (!reduceMotion) {
      content = content.animate().fadeIn(duration: 600.ms);
    }

    return content;
  }

  Widget _buildContextPill(bool isDark, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.w,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11.5.sp,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildGlassAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Semantics(
      label: '$label: $subtitle',
      button: true,
      child: ScaleButton(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.teal500.withValues(alpha: 0.2),
                    _LocalPalette.color0d9488.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: AppColors.teal500.withValues(alpha: 0.4),
                  width: 1.5.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal500.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: AppColors.teal500, size: 30.r),
                  SizedBox(height: 10.h),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
