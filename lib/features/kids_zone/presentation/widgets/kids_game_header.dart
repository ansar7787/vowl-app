import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/utils/mascot_message_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart' as import_dialogs;

class KidsGameHeader extends StatelessWidget {
  final String title;
  final int level;
  final Color primaryColor;
  final String? hintText;
  final KidsState state;
  final VoidCallback? onInfoTap;

  const KidsGameHeader({
    super.key,
    required this.title,
    required this.level,
    required this.primaryColor,
    required this.state,
    this.hintText,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int currentIndex = 0;
    int totalQuests = 1;

    if (state is KidsLoaded) {
      final s = state as KidsLoaded;
      int correctlyAnswered = s.currentIndex - (s.quests.length - s.originalTotalQuests);
      currentIndex = correctlyAnswered.clamp(0, s.originalTotalQuests);
      totalQuests = s.originalTotalQuests;
    } else if (state is KidsGameOver) {
      final s = state as KidsGameOver;
      int correctlyAnswered = s.currentIndex - (s.quests.length - s.originalTotalQuests);
      currentIndex = correctlyAnswered.clamp(0, s.originalTotalQuests);
      totalQuests = s.originalTotalQuests;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        children: [
          _buildFloatingIsland(context, isDark),
          SizedBox(height: 12.h),
          _buildModernProgressTracker(context, isDark, currentIndex, totalQuests),
        ],
      ),
    );
  }

  Widget _buildFloatingIsland(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30.r),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF1E293B) : Colors.white)
                  .withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                ScaleButton(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16.sp),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        "QUEST $level",
                        style: TextStyle(fontFamily: 'Outfit', 
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        title.toUpperCase(),
                        style: TextStyle(fontFamily: 'Outfit', 
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildLives(),
                if (onInfoTap != null) ...[
                  SizedBox(width: 8.w),
                  ScaleButton(
                    onTap: onInfoTap!,
                    child: Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 16.r,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
                SizedBox(width: 8.w),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLives() {
    int lives = 3;
    if (state is KidsLoaded) lives = (state as KidsLoaded).livesRemaining;
    return Row(
      children: List.generate(3, (index) {
        return Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Icon(
            index < lives ? Icons.favorite : Icons.favorite_border,
            color: Colors.redAccent,
            size: 18.sp,
          ),
        );
      }),
    );
  }

  Widget _buildModernProgressTracker(BuildContext context, bool isDark, int index, int total) {
    final progress = (total > 0 ? (index / total) : 0.0).clamp(0.0, 1.0);
    return Row(
      children: [
        _buildHintButton(context),
        SizedBox(width: 12.w),
        Expanded(
          child: Container(
            height: 20.h,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 10.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedContainer(
                      duration: 800.ms,
                      curve: Curves.easeOutCubic,
                      width: constraints.maxWidth * progress,
                      height: 10.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withValues(alpha: 0.5)],
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12.w),
        _buildBuddyMascot(context, isDark),
      ],
    );
  }

  Widget _buildHintButton(BuildContext context) {
    if (state is! KidsLoaded) return const SizedBox.shrink();
    final s = state as KidsLoaded;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final hints = authState.user?.hintCount ?? 0;
        return ScaleButton(
          onTap: () {
            if (s.hintUsed) return;
            if (hints > 0) {
              context.read<KidsBloc>().add(UseKidsHint());
            } else {
              import_dialogs.GameDialogHelper.showHintAdDialog(
                context, 
                persistToAccount: false,
                onHintEarned: () {
                  context.read<KidsBloc>().add(const UseKidsHint(isFree: true));
                },
              );
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: s.hintUsed ? Colors.grey[300] : Colors.amber[100],
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(color: s.hintUsed ? Colors.grey : Colors.amber[600]!, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lightbulb_rounded, color: s.hintUsed ? Colors.grey : Colors.amber[800], size: 14.sp),
                SizedBox(width: 4.w),
                Text(hints.toString(), style: TextStyle(fontFamily: 'Outfit', fontSize: 12.sp, fontWeight: FontWeight.w900, color: s.hintUsed ? Colors.grey : Colors.amber[900])),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBuddyMascot(BuildContext context, bool isDark) {
    bool isComplete = state is KidsGameComplete;
    bool isGameOver = state is KidsGameOver;
    bool isAnswered = false;
    bool? isCorrect;
    int lives = 3;

    if (state is KidsLoaded) {
      final s = state as KidsLoaded;
      isAnswered = s.lastAnswerCorrect != null;
      isCorrect = s.lastAnswerCorrect;
      lives = s.livesRemaining;
    }

    final mascotState = MascotMessageHelper.getMascotState(
      isComplete: isComplete,
      isGameOver: isGameOver,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final mascotId = authState.user?.kidsMascot ?? 'owly';
        final displayMessage = hintText ?? MascotMessageHelper.getMessage(
          context,
          category: 'kids',
          mascotId: mascotId,
          isComplete: isComplete,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          lives: lives,
        );

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (displayMessage.isNotEmpty)
              Positioned(
                right: 50.w,
                top: -15.h,
                child: _buildSpeechBubble(context, displayMessage, isDark),
              ),
            VowlMascot(
              isKidsMode: true,
              size: 50.r,
              state: mascotState,
              useFloatingAnimation: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpeechBubble(BuildContext context, String text, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15.r),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          constraints: BoxConstraints(maxWidth: 140.w),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Text(text, style: TextStyle(fontFamily: 'Outfit', fontSize: 12.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
        ),
      ),
    ).animate().scale(begin: Offset.zero, duration: 400.ms, curve: Curves.easeOutBack);
  }
}
