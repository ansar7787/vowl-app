import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_audio_visualizer.dart';

/// Interactive 3D flippable card for the Flashcard Learn Phase.
///
/// Features holographic glass aesthetics, integrated audio resonance visualizer,
/// pronunciation power orbs, and spring-physics 3D flipping.
class FlashcardLearnCard extends StatefulWidget {
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
  State<FlashcardLearnCard> createState() => _FlashcardLearnCardState();
}

class _FlashcardLearnCardState extends State<FlashcardLearnCard> {
  bool _isSpeaking = false;

  void _handleSpeak() {
    setState(() => _isSpeaking = true);
    widget.onSpeak();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('flashcard_learn_card'),
      behavior: HitTestBehavior.opaque,
      onTap: widget.onFlip,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: widget.isFlipped ? 1 : 0),
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
    final bgColor = widget.isDark ? AppColors.slate900 : Colors.white;
    final borderColor = widget.isDark
        ? AppColors.indigo500.withValues(alpha: 0.35)
        : AppColors.indigo500.withValues(alpha: 0.25);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 22.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: borderColor, width: 2),
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
        children: [
          // Word & Audio Resonance Equalizer Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.quest.word ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w900,
                      color: widget.isDark ? Colors.white : AppColors.slate900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              FlashcardAudioVisualizer(
                isPlaying: _isSpeaking,
                color: AppColors.indigo500,
                height: 22.h,
              ),
              SizedBox(width: 8.w),
              ScaleButton(
                onTap: _handleSpeak,
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(alpha: 0.14),
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

          // Pronunciation Pill
          if (widget.quest.pronunciation != null &&
              widget.quest.pronunciation!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.indigo500.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.20),
                ),
              ),
              child: Text(
                widget.quest.pronunciation!,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  color: AppColors.indigo400,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],

          // Quick Word Power Orbs (first 2 family words preview if present)
          if (widget.quest.familyWords.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Wrap(
              spacing: 6.w,
              alignment: WrapAlignment.center,
              children: widget.quest.familyWords.take(3).map((w) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? AppColors.slate800
                        : AppColors.slate100,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    w,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      color: widget.isDark
                          ? AppColors.slate400
                          : AppColors.slate600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          SizedBox(height: 18.h),
          Divider(
            color: widget.isDark ? AppColors.slate800 : AppColors.slate100,
            thickness: 1.2,
          ),
          SizedBox(height: 10.h),

          // Interactive Flip Cue
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
                    color: widget.isDark
                        ? AppColors.slate400
                        : AppColors.slate500,
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 22.h),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.slate900 : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.indigo500, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigo500.withValues(alpha: 0.20),
            blurRadius: 22.r,
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
                onTap: _handleSpeak,
                child: Icon(
                  Icons.volume_up_rounded,
                  color: AppColors.indigo500,
                  size: 22.r,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            widget.quest.definition ?? 'No definition provided',
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              color: widget.isDark ? Colors.white : AppColors.slate900,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          if (widget.quest.example != null &&
              widget.quest.example!.isNotEmpty) ...[
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? AppColors.slate800.withValues(alpha: 0.6)
                    : AppColors.slate50,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: widget.isDark
                      ? AppColors.slate700
                      : AppColors.slate200,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '"${widget.quest.example!}"',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontStyle: FontStyle.italic,
                        color: widget.isDark
                            ? AppColors.slate300
                            : AppColors.slate700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 14.h),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.flip_to_back_rounded,
                  size: 14.r,
                  color: AppColors.indigo400,
                ),
                SizedBox(width: 6.w),
                Text(
                  'Tap to flip back',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    color: AppColors.indigo400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
