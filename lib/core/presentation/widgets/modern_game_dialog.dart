import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

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
  final bool isExitConfirmation;

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
    this.isExitConfirmation = false,
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
                child: isSuccess ? _buildVictoryMascot(context) : Icon(
                  Icons.heart_broken_rounded,
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
                ScaleButton(
                  onTap: onAdAction!,
                  child: Container(
                    width: double.infinity,
                    height: 56.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      gradient: LinearGradient(
                        colors: isExitConfirmation
                            ? [
                                const Color(0xFF64748B), // Slate for Quit
                                const Color(0xFF475569),
                              ]
                            : isRescueLife
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
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isExitConfirmation
                                  ? Icons.logout_rounded
                                  : isRescueLife
                                      ? Icons.play_circle_fill
                                      : Icons.play_circle_fill_rounded,
                              color: (isRescueLife || isExitConfirmation) ? Colors.white : Colors.black87,
                              size: 20.r,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              adButtonText ?? "TRIPLE REWARDS (3X)",
                              style: GoogleFonts.outfit(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: (isRescueLife || isExitConfirmation) ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .animate(onPlay: (c) => (isRescueLife || isExitConfirmation) ? c : c.repeat())
                .shimmer(
                  duration: 2.seconds,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                SizedBox(height: 16.h),
              ],
              ScaleButton(
                onTap: onButtonPressed,
                child: Container(
                  width: double.infinity,
                  height: 56.h,
                  decoration: BoxDecoration(
                    color: isRescueLife
                        ? (isDark ? Colors.white12 : Colors.grey[200])
                        : primaryColor,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Center(
                    child: Text(
                      buttonText,
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: isRescueLife
                            ? (isDark ? Colors.white54 : Colors.black54)
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              if (onSecondaryPressed != null) ...[
                SizedBox(height: 12.h),
                TextButton(
                  onPressed: onSecondaryPressed,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  ),
                  child: Text(
                    secondaryButtonText ?? "CANCEL",
                    style: GoogleFonts.outfit(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: isSuccess 
                        ? (isDark ? Colors.white54 : Colors.black54)
                        : const Color(0xFFFFD700), // Gold for rescue!
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

  Widget _buildVictoryMascot(BuildContext context) {
    return VowlMascot(
      size: 80.r,
      state: VowlMascotState.happy,
      useFloatingAnimation: true,
    );
  }
}
