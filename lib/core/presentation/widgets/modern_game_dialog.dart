import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voxai_quest/core/presentation/widgets/glass_tile.dart';

class ModernGameDialog extends StatelessWidget {
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final VoidCallback? onSecondaryPressed;
  final String? secondaryButtonText;
  final VoidCallback? onAdAction;
  final String? adButtonText;
  final bool isSuccess;
  final bool isRescueLife;

  const ModernGameDialog({
    super.key,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onButtonPressed,
    this.onSecondaryPressed,
    this.secondaryButtonText,
    this.onAdAction,
    this.adButtonText,
    this.isSuccess = true,
    this.isRescueLife = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isSuccess
        ? const Color(0xFF10B981)
        : const Color(0xFFF43F5E);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassTile(
        borderRadius: BorderRadius.circular(28.r),
        padding: EdgeInsets.zero,
        blur: 20,
        glassOpacity: isDark ? 0.1 : 0.6,
        child: Container(
          padding: EdgeInsets.all(28.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess
                      ? Icons.emoji_events_rounded
                      : Icons.heart_broken_rounded,
                  color: primaryColor,
                  size: 48.r,
                ),
              ).animate().scale(
                delay: 200.ms,
                duration: 500.ms,
                curve: Curves.elasticOut,
              ),
              SizedBox(height: 24.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                description,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              SizedBox(height: 32.h),
              if (onAdAction != null) ...[
                SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          gradient: LinearGradient(
                            colors: isRescueLife
                                ? [
                                    const Color(0xFF2563EB),
                                    const Color(0xFF1E3A8A),
                                  ] // Blue for Rescue
                                : [
                                    const Color(0xFFFFD700),
                                    const Color(0xFFFFA500),
                                  ], // Gold for Double Up
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isRescueLife
                                          ? Colors.blue
                                          : const Color(0xFFFFA500))
                                      .withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: isRescueLife
                                ? Colors.white
                                : Colors.black87,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                          onPressed: onAdAction,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isRescueLife
                                      ? Icons.play_circle_fill
                                      : Icons.play_circle_fill_rounded,
                                  size: 20.r,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  adButtonText ?? "DOUBLE REWARDS (2X)",
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .animate(onPlay: (c) => isRescueLife ? c : c.repeat())
                    .shimmer(
                      duration: 2.seconds,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                SizedBox(height: 16.h),
              ],
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRescueLife
                        ? (isDark ? Colors.white12 : Colors.grey[200])
                        : primaryColor,
                    foregroundColor: isRescueLife
                        ? (isDark ? Colors.white54 : Colors.black54)
                        : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  onPressed: onButtonPressed,
                  child: Text(
                    buttonText,
                    style: GoogleFonts.outfit(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (onSecondaryPressed != null) ...[
                SizedBox(height: 12.h),
                TextButton(
                  onPressed: onSecondaryPressed,
                  child: Text(
                    secondaryButtonText ?? "CANCEL",
                    style: GoogleFonts.outfit(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
    );
  }
}
