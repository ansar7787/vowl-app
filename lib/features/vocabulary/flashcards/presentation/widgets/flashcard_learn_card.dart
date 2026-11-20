import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive 3D flippable card for the Flashcard Learn Phase.
class FlashcardLearnCard extends StatelessWidget {
  final PhasedQuest quest;
  final bool isFlipped;
  final bool isDark;
  final VoidCallback onFlip;
  final VoidCallback onSpeak;

  const FlashcardLearnCard({
    super.key,
    required this.quest,
    required this.isFlipped,
    required this.isDark,
    required this.onFlip,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('flashcard_learn_card'),
      behavior: HitTestBehavior.opaque,
      onTap: onFlip,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: isFlipped ? 1 : 0),
        duration: 400.ms,
        curve: Curves.easeInOutCubic,
        builder: (context, val, child) {
          final isBack = val > 0.5;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(val * pi),
            alignment: Alignment.center,
            child: isBack
                ? Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _buildBackFace(context),
                  )
                : _buildFrontFace(context),
          );
        },
      ),
    );
  }

  Widget _buildFrontFace(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate900 : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark ? AppColors.slate800 : AppColors.slate200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigo500.withValues(alpha: 0.12),
            blurRadius: 18.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  quest.word ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.slate900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              ScaleButton(
                onTap: onSpeak,
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: AppColors.indigo500,
                    size: 24.r,
                  ),
                ),
              ),
            ],
          ),
          if (quest.pronunciation != null &&
              quest.pronunciation!.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.indigo500.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                quest.pronunciation!,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  color: AppColors.indigo400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          SizedBox(height: 18.h),
          Divider(
            color: isDark ? AppColors.slate800 : AppColors.slate100,
            thickness: 1.2,
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 16.r,
                color: AppColors.indigo500,
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  'Tap card to reveal definition & usage',
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    color: isDark ? AppColors.slate400 : AppColors.slate500,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackFace(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate900 : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.indigo500, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigo500.withValues(alpha: 0.16),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.indigo500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'DEFINITION',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.indigo500,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const Spacer(),
              ScaleButton(
                onTap: onSpeak,
                child: Icon(
                  Icons.volume_up_rounded,
                  color: AppColors.indigo500,
                  size: 22.r,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            quest.definition ?? 'No definition provided',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              color: isDark ? Colors.white : AppColors.slate900,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          if (quest.example != null && quest.example!.isNotEmpty) ...[
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.slate800.withValues(alpha: 0.6)
                    : AppColors.slate50,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isDark ? AppColors.slate700 : AppColors.slate200,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '"${quest.example!}"',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppColors.slate300 : AppColors.slate700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 12.h),
          Center(
            child: Text(
              'Tap to flip back',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                color: AppColors.indigo400,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
