import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/story_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Glassmorphic story-beat dialog presenting narrative moments before levels.
///
/// Uses [context.select] (not [context.read]) so the mascot and level data
/// stays in sync if auth state changes while the dialog is visible.
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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child:
              ClipRRect(
                    borderRadius: BorderRadius.circular(32.r),
                    child: BackdropFilter(
                      // PERF: reduced from sigma 15 → 8. Sigma 15 is
                      // expensive during the entry scale/fade animation
                      // (GPU must re-blur every frame). 8 provides the
                      // same glassmorphic effect at lower cost.
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
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
                            _buildFooter(context),
                          ],
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .scale(duration: 400.ms, curve: Curves.easeOutBack)
                  .fadeIn(duration: 300.ms),
        ),
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
            Flexible(
              child: Text(
                beat.title,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w900,
                  color: beat.themeColor,
                  letterSpacing: 3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    // HIGH FIX: Use context.select instead of context.read in build().
    // context.read misses updates; context.select rebuilds only when the
    // selected values change.
    final mascotId = context.select<AuthBloc, String>(
      (b) => isKidsMode
          ? (b.state.user?.kidsMascot ?? 'owly')
          : (b.state.user?.vowlMascot ?? 'vowl_prime'),
    );
    final level = context.select<AuthBloc, int>(
      (b) => b.state.user?.level ?? 1,
    );

    return Padding(
      padding: EdgeInsets.all(32.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VowlMascot(
            state: VowlMascotState.happy,
            size: 96.r,
            useFloatingAnimation: true,
            level: level,
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
              .fadeIn(delay: 150.ms)
              .slideY(begin: 0.1, duration: 300.ms),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(32.w, 0, 32.w, 32.h),
      child: Semantics(
        button: true,
        label: context.tr('story.start_journey', fallback: 'Start Journey'),
        child: ScaleButton(
          onTap: onDismiss,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 20.h),
            constraints: BoxConstraints(minHeight: 48.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  beat.themeColor,
                  beat.themeColor.withValues(alpha: 0.8),
                ],
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
                context
                    .tr('story.start_journey', fallback: 'Start Journey')
                    .toUpperCase(),
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
      ),
    ).animate().fadeIn(delay: 250.ms).moveY(begin: 20, end: 0);
  }
}
