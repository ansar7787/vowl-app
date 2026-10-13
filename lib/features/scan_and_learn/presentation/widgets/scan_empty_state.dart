import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/theme/app_colors.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color4f46e5 = Color(0xFF4F46E5);
  static const Color color818cf8 = Color(0xFF818CF8);
}

class ScanEmptyState extends StatelessWidget {
  final Future<void> Function(ImageSource) onPickImage;

  const ScanEmptyState({super.key, required this.onPickImage});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final primaryIndigo = AppColors.indigo500;

    // Viewfinder laser scanning line
    Widget laserLine = Center(
      child: Container(
        height: 2.h,
        width: 190.w,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryIndigo.withValues(alpha: 0.0),
              primaryIndigo,
              Colors.white,
              primaryIndigo,
              primaryIndigo.withValues(alpha: 0.0),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryIndigo.withValues(alpha: 0.8),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );

    if (!reduceMotion) {
      laserLine = RepaintBoundary(
        child: laserLine
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .slideY(begin: -0.38, end: 0.38, duration: 2.2.seconds, curve: Curves.easeInOut),
      );
    }

    Widget cameraBtn = _buildGlassAction(
      context,
      icon: LucideIcons.camera,
      label: context.tr('common.camera', fallback: 'Camera'),
      subtitle: context.tr('translation.scan_live', fallback: 'Scan live text'),
      onTap: () => onPickImage(ImageSource.camera),
      isDark: isDark,
      isPrimary: true,
    );
    if (!reduceMotion) {
      cameraBtn = cameraBtn.animate(delay: 200.ms).fadeIn().slideY(begin: 0.15);
    }

    Widget galleryBtn = _buildGlassAction(
      context,
      icon: LucideIcons.image,
      label: context.tr('common.gallery', fallback: 'Gallery'),
      subtitle: context.tr(
        'translation.pick_saved',
        fallback: 'Pick photo',
      ),
      onTap: () => onPickImage(ImageSource.gallery),
      isDark: isDark,
      isPrimary: false,
    );
    if (!reduceMotion) {
      galleryBtn = galleryBtn.animate(delay: 300.ms).fadeIn().slideY(begin: 0.15);
    }

    Widget content = SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // High-Tech Document Scanner Viewfinder HUD
          ExcludeSemantics(
            child: Container(
              height: 190.h,
              width: 220.w,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.45)
                    : Colors.white.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: primaryIndigo.withValues(alpha: 0.25),
                  width: 1.w,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // Top-Left Corner Bracket
                  Positioned(
                    top: 10.h,
                    left: 10.w,
                    child: _buildCornerBracket(primaryIndigo, top: true, left: true),
                  ),
                  // Top-Right Corner Bracket
                  Positioned(
                    top: 10.h,
                    right: 10.w,
                    child: _buildCornerBracket(primaryIndigo, top: true, left: false),
                  ),
                  // Bottom-Left Corner Bracket
                  Positioned(
                    bottom: 10.h,
                    left: 10.w,
                    child: _buildCornerBracket(primaryIndigo, top: false, left: true),
                  ),
                  // Bottom-Right Corner Bracket
                  Positioned(
                    bottom: 10.h,
                    right: 10.w,
                    child: _buildCornerBracket(primaryIndigo, top: false, left: false),
                  ),

                  // Center Document & OCR Scanner Icon
                  Center(
                    child: Container(
                      height: 70.r,
                      width: 70.r,
                      decoration: BoxDecoration(
                        color: primaryIndigo.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryIndigo.withValues(alpha: 0.25),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.document_scanner_rounded,
                        size: 36.r,
                        color: isDark ? _LocalPalette.color818cf8 : primaryIndigo,
                      ),
                    ),
                  ),

                  // Scanning Laser
                  Positioned.fill(child: laserLine),
                ],
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // Technical Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: primaryIndigo.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(100.r),
              border: Border.all(
                color: primaryIndigo.withValues(alpha: 0.35),
                width: 1.w,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.fileText, size: 12.r, color: primaryIndigo),
                SizedBox(width: 6.w),
                Text(
                  context
                      .tr('translation.system_standby', fallback: 'SIGN & TEXT READER')
                      .toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? _LocalPalette.color818cf8 : primaryIndigo,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),

          Text(
            context.tr(
              'translation.scan_learn_title',
              fallback: 'Scan & Learn',
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 26.sp,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 8.h),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              context.tr(
                'translation.scan_learn_desc',
                fallback:
                    'Scan real-world signs, restaurant menus, packaging, or books to read, pronounce, and translate written English.',
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

          // Real-World Use Case Pills (Distinct from Photo Vocab)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _buildContextPill(isDark, '🪧 Street Signs'),
              _buildContextPill(isDark, '📜 Menus & Bills'),
              _buildContextPill(isDark, '📖 Books & Labels'),
            ],
          ),
          SizedBox(height: 28.h),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: cameraBtn),
              SizedBox(width: 16.w),
              Expanded(child: galleryBtn),
            ],
          ),
        ],
      ),
    );

    if (!reduceMotion) {
      content = content.animate().fadeIn(duration: 600.ms);
    }

    return content;
  }

  Widget _buildCornerBracket(Color color, {required bool top, required bool left}) {
    return Container(
      width: 22.w,
      height: 22.w,
      decoration: BoxDecoration(
        border: Border(
          top: top ? BorderSide(color: color, width: 3.w) : BorderSide.none,
          bottom: !top ? BorderSide(color: color, width: 3.w) : BorderSide.none,
          left: left ? BorderSide(color: color, width: 3.w) : BorderSide.none,
          right: !left ? BorderSide(color: color, width: 3.w) : BorderSide.none,
        ),
      ),
    );
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
    required bool isPrimary,
  }) {
    final primaryIndigo = AppColors.indigo500;

    return Semantics(
      label: label,
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
                    primaryIndigo.withValues(alpha: isPrimary ? 0.22 : 0.1),
                    _LocalPalette.color4f46e5.withValues(alpha: isPrimary ? 0.1 : 0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: primaryIndigo.withValues(alpha: isPrimary ? 0.45 : 0.25),
                  width: 1.5.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryIndigo.withValues(alpha: isPrimary ? 0.15 : 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: primaryIndigo, size: 30.r),
                  SizedBox(height: 10.h),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : Colors.black45,
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
