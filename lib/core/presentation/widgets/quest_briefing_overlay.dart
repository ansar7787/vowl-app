import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class QuestBriefingOverlay extends StatefulWidget {
  final String title;
  final String objective;
  final List<String> rules;
  final String actionText;
  final String tip;
  final IconData icon;
  final Color primaryColor;
  final VoidCallback onStart;

  const QuestBriefingOverlay({
    super.key,
    required this.title,
    required this.objective,
    required this.rules,
    required this.actionText,
    required this.tip,
    required this.icon,
    required this.primaryColor,
    required this.onStart,
  });

  @override
  State<QuestBriefingOverlay> createState() => _QuestBriefingOverlayState();
}

class _QuestBriefingOverlayState extends State<QuestBriefingOverlay> {
  bool _isExiting = false;

  void _handleStart() {
    setState(() => _isExiting = true);
    Future.delayed(const Duration(milliseconds: 500), widget.onStart);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Background Overlay (Optimized: No Blur)
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.85)),
          ).animate(target: _isExiting ? 1 : 0).fadeOut(duration: 400.ms),

          // Content Card
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: 50.h),
              physics: const BouncingScrollPhysics(),
              child: Container(
                width: 0.85.sw,
                padding: EdgeInsets.all(32.r),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(40.r),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: widget.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Hero Icon
                    Container(
                      padding: EdgeInsets.all(24.r),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [widget.primaryColor, widget.primaryColor.withValues(alpha: 0.6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.primaryColor.withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 48.r),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .shimmer(duration: 2.seconds, color: Colors.white30)
                     .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1.seconds),

                    SizedBox(height: 24.h),

                    // Title
                    Text(
                      "MISSION BRIEFING",
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                        color: widget.primaryColor,
                        letterSpacing: 4,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Objective
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      child: Text(
                        widget.objective,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.5,
                        ),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Rules
                    ...widget.rules.map((rule) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: widget.primaryColor, size: 18.r),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              rule,
                              style: GoogleFonts.outfit(
                                fontSize: 14.sp,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),

                    SizedBox(height: 24.h),
                    
                    // Pro Tip Card
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.tips_and_updates_rounded, color: Colors.amber, size: 24.r),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              widget.tip,
                              style: GoogleFonts.outfit(
                                fontSize: 13.sp,
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                    SizedBox(height: 32.h),

                    // Action Button
                    ScaleButton(
                      onTap: _handleStart,
                      child: Container(
                        width: double.infinity,
                        height: 65.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [widget.primaryColor, widget.primaryColor.withValues(alpha: 0.8)],
                          ),
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: widget.primaryColor.withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.actionText.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .shimmer(delay: 2.seconds, duration: 1.seconds, color: Colors.white24),
                  ],
                ),
              ).animate(target: _isExiting ? 1 : 0)
               .slideY(begin: 0, end: -0.2, duration: 400.ms, curve: Curves.easeIn)
               .fadeOut(duration: 300.ms),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
