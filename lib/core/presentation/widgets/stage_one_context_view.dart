import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

/// A standardized "Stage 1" context view that displays pedagogical JSON fields.
/// When the user taps the "Continue" button, they proceed to Stage 2 (Game Mechanism).
class StageOneContextView extends StatelessWidget {
  /// The main context/passage (e.g. context sentence, example, or reading passage).
  final String mainContext;

  /// Optional: specific pedagogical highlights (e.g. academic field, collocations).
  final Widget? pedagogicalContent;

  /// The theme color of the current level/game.
  final Color primaryColor;

  /// Called when the user taps to proceed to Stage 2.
  final VoidCallback onProceedToStage2;

  const StageOneContextView({
    super.key,
    required this.mainContext,
    this.pedagogicalContent,
    required this.primaryColor,
    required this.onProceedToStage2,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon header
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: primaryColor,
                      size: 32.r,
                    ),
                  ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                  SizedBox(height: 24.h),

                  // Main Context Label
                  Text(
                    'CONTEXT',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                      letterSpacing: 1.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                  SizedBox(height: 12.h),

                  // Main Context Text
                  Container(
                    padding: EdgeInsets.all(24.r),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      mainContext,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                  SizedBox(height: 24.h),

                  // Optional Pedagogical Fields
                  if (pedagogicalContent != null)
                    pedagogicalContent!.animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                ],
              ),
            ),
          ),
          
          // Proceed Button
          SizedBox(height: 16.h),
          ScaleButton(
            onTap: onProceedToStage2,
            child: Container(
              width: double.infinity,
              height: 64.h,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'START CHALLENGE',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ).animate().scale(delay: 600.ms, curve: Curves.easeOutBack),
        ],
      ),
    );
  }
}
