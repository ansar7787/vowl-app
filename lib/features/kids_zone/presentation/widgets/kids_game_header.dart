import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart'
    as import_dialogs;

class KidsGameHeader extends StatelessWidget {
  final String title;
  final int level;
  final Color primaryColor;
  final KidsState state;
  final VoidCallback? onInfoTap;

  const KidsGameHeader({
    super.key,
    required this.title,
    required this.level,
    required this.primaryColor,
    required this.state,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    int currentIndex = 0;
    int totalQuests = 1;
    int lives = 3;

    if (state is KidsLoaded) {
      final s = state as KidsLoaded;
      int correctlyAnswered =
          s.currentIndex - (s.quests.length - s.originalTotalQuests);
      currentIndex = correctlyAnswered.clamp(0, s.originalTotalQuests);
      totalQuests = s.originalTotalQuests;
      lives = s.livesRemaining;
    } else if (state is KidsGameOver) {
      final s = state as KidsGameOver;
      int correctlyAnswered =
          s.currentIndex - (s.quests.length - s.originalTotalQuests);
      currentIndex = correctlyAnswered.clamp(0, s.originalTotalQuests);
      totalQuests = s.originalTotalQuests;
      lives = 0;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back Button
          ScaleButton(
            onTap: () => context.pop(),
            child: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 3.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Icon(
                Icons.close_rounded,
                color: Colors.grey.shade400,
                size: 20.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // Progress Bar
          Expanded(child: _buildChunkyProgressBar(currentIndex, totalQuests)),

          SizedBox(width: 12.w),

          // Hint Button
          _buildHintButton(context),

          SizedBox(width: 8.w),

          // Lives
          _buildLives(lives),
        ],
      ),
    );
  }

  Widget _buildChunkyProgressBar(int index, int total) {
    final progress = (total > 0 ? (index / total) : 0.0).clamp(0.0, 1.0);
    return Container(
      height: 24.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey.shade300, width: 3.w),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade300, offset: Offset(0, 4.h)),
        ],
      ),
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth > 0
                  ? constraints.maxWidth
                  : 0.0;
              final targetWidth = availableWidth * progress;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                width: targetWidth > 0 ? targetWidth : 0.0,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(18.r),
                ),
              );
            },
          ),
          // Glare effect for 3D chunkiness
          Container(
            height: 8.h,
            margin: EdgeInsets.only(top: 2.h, left: 6.w, right: 6.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLives(int lives) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.redAccent.withValues(alpha: 0.3),
          width: 3.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withValues(alpha: 0.2),
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: Icon(
              index < lives
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: index < lives ? Colors.redAccent : Colors.grey.shade300,
              size: 20.sp,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHintButton(BuildContext context) {
    if (state is! KidsLoaded) return const SizedBox.shrink();
    final s = state as KidsLoaded;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final hints = authState.user?.hintCount ?? 0;
        final isUsed = s.hintUsed;

        return ScaleButton(
          onTap: () {
            if (isUsed) return;
            if (hints > 0) {
              context.read<KidsBloc>().add(const UseKidsHint());
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
              color: isUsed ? Colors.grey.shade300 : Colors.amber.shade400,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isUsed ? Colors.grey.shade400 : Colors.amber.shade600,
                width: 3.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: isUsed ? Colors.grey.shade400 : Colors.amber.shade600,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lightbulb_rounded,
                  color: isUsed ? Colors.grey.shade400 : Colors.white,
                  size: 18.sp,
                ),
                SizedBox(width: 4.w),
                Text(
                  hints.toString(),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: isUsed ? Colors.grey.shade400 : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


