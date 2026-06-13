import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/story_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';

/// A premium, glassmorphic dialog box presenting story beats and mission briefings,
/// optimized to protect expensive BackdropFilter blur operations from redundant animation redraws.
class StoryDialogueBox extends StatelessWidget {
  final StoryBeat beat;
  final VoidCallback onDismiss;
  final bool isKidsMode;

  const StoryDialogueBox({
    super.key,
    required this.beat,
    required this.onDismiss,
    this.isKidsMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Center(
        child:
            Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32.r),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(32.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: beat.themeColor.withValues(alpha: 0.2),
                              blurRadius: 40,
                              spreadRadius: -10,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeader(),
                            _buildBody(context, isDark),
                            _buildFooter(),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .animate()
                .scale(duration: 600.ms, curve: Curves.easeOutBack)
                .fadeIn(duration: 400.ms),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            beat.themeColor.withValues(alpha: 0.2),
            beat.themeColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: beat.themeColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Isolate high-frequency pulsing indicator dot inside a RepaintBoundary
            RepaintBoundary(
              child:
                  Container(
                        width: 8.r,
                        height: 8.r,
                        decoration: BoxDecoration(
                          color: beat.themeColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: beat.themeColor.withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(begin: const Offset(0.8, 0.8), duration: 800.ms),
            ),
            SizedBox(width: 12.w),
            Text(
              beat.title,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                fontWeight: FontWeight.w900,
                color: beat.themeColor,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    final user = context.read<AuthBloc>().state.user;
    final mascotId = isKidsMode 
        ? (user?.kidsMascot ?? 'owly')
        : (user?.vowlMascot ?? 'vowl_prime');

    return Padding(
      padding: EdgeInsets.all(32.r),
      child: Column(
        children: [
          // Dynamic Mascot avatar with full accessory support
          VowlMascot(
            state: VowlMascotState.happy,
            size: 96.r,
            useFloatingAnimation: true,
            level: user?.level ?? 1,
            mascotId: mascotId,
            isKidsMode: isKidsMode,
          ),
          SizedBox(height: 24.h),
          Text(
                beat.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : const Color(0xFF1E293B),
                  height: 1.4,
                ),
              )
              .animate()
              .fadeIn(delay: 300.ms)
              .slideY(begin: 0.1, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: EdgeInsets.fromLTRB(32.w, 0, 32.w, 32.h),
      child: ScaleButton(
        onTap: onDismiss,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 20.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [beat.themeColor, beat.themeColor.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: beat.themeColor.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Text(
              "START JOURNEY",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).moveY(begin: 20, end: 0);
  }
}
