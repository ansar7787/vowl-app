import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/praise_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_coins.dart';

/// Fullscreen modal dialog hosting the 3-question active recall Snap Challenge.
///
/// Strictly conforms to Vowl's 3-question level architecture, ascending pitch
/// ladder earcons (1.00x -> 1.12x -> 1.25x), and 10-coin reward economy.
class SnapQuizDialog extends StatefulWidget {
  final List<GameQuest> quests;
  final String title;

  const SnapQuizDialog({
    super.key,
    required this.quests,
    this.title = 'SNAP CHALLENGE',
  });

  static Future<void> show(
    BuildContext context, {
    required List<GameQuest> quests,
    String title = 'SNAP CHALLENGE',
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SnapQuizDialog(
        quests: quests,
        title: title,
      ),
    );
  }

  @override
  State<SnapQuizDialog> createState() => _SnapQuizDialogState();
}

class _SnapQuizDialogState extends State<SnapQuizDialog> {
  int _currentIndex = 0;
  int _mistakesMade = 0;
  int? _selectedOptionIndex;
  bool _isLocked = false;
  bool _isCompleted = false;

  Timer? _advanceTimer;
  Timer? _tallyTimer;

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _tallyTimer?.cancel();
    super.dispose();
  }

  void _onOptionSelected(int index) async {
    if (_isLocked || _isCompleted) return;

    final quest = widget.quests[_currentIndex];
    final isCorrect = index == quest.correctAnswerIndex;

    setState(() {
      _isLocked = true;
      _selectedOptionIndex = index;
    });

    if (isCorrect) {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().success();
      }
      // Ascending dopamine pitch ladder: Q1=1.00x, Q2=1.12x, Q3=1.25x
      if (di.sl.isRegistered<SoundService>()) {
        await di.sl<SoundService>().playCorrect(comboStep: _currentIndex + 1);
      }
    } else {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().error();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playWrong();
      }
      _mistakesMade++;
    }

    // Auto-advance after brief educational feedback
    _advanceTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;

      if (_currentIndex < widget.quests.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedOptionIndex = null;
          _isLocked = false;
        });
      } else {
        // 3-Question level complete!
        setState(() {
          _isCompleted = true;
        });

        if (di.sl.isRegistered<SoundService>()) {
          di.sl<SoundService>().playLevelComplete();
          _tallyTimer = Timer(const Duration(milliseconds: 350), () {
            if (mounted && di.sl.isRegistered<SoundService>()) {
              di.sl<SoundService>().playCoinTally(count: 10);
            }
          });
        }

        if (di.sl.isRegistered<HapticService>()) {
          di.sl<HapticService>().success();
        }

        if (_mistakesMade == 0 && di.sl.isRegistered<PraiseService>()) {
          Timer(const Duration(milliseconds: 1400), () {
            try {
              di.sl<PraiseService>().givePraise(context: PraiseContext.flawless);
            } catch (_) {}
          });
        }

        // Authoritatively persist 10 coins into user economy
        if (di.sl.isRegistered<UpdateUserCoins>()) {
          di.sl<UpdateUserCoins>().call(
            UpdateUserCoinsParams(
              amountChange: 10,
              title: 'Snap Challenge: ${widget.title}',
              isEarned: true,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A).withValues(alpha: 0.96)
                    : Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(28.r),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: _isCompleted
                  ? _buildCompletionContent(context, isDark)
                  : _buildQuestionContent(context, isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionContent(BuildContext context, bool isDark) {
    final perfect = _mistakesMade == 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Trophy Badge
        Center(
          child: Container(
            width: 72.r,
            height: 72.r,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.amber500, Colors.amber],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.amber500.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              perfect ? LucideIcons.trophy : LucideIcons.award,
              size: 36.r,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 16.h),

        // Header Title
        Text(
          'CHALLENGE MASTERED!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        SizedBox(height: 6.h),

        // Performance Subtitle
        Text(
          perfect
              ? 'Flawless 3/3 Mastery! 🎯'
              : '${3 - _mistakesMade}/3 Questions Correct!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.teal500,
          ),
        ),
        SizedBox(height: 16.h),

        // Coin Reward Pill
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.amber.shade500.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Colors.amber.shade500.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.coins, size: 20.r, color: Colors.amber.shade400),
              SizedBox(width: 8.w),
              Text(
                '+10 COINS ADDED',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.amber.shade300 : AppColors.amber500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),

        // Button 1: Return to scan to inspect more words
        ScaleButton(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.indigo500, AppColors.teal500],
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.indigo500.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.compass, size: 18.r, color: Colors.white),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    'Keep Exploring Scanned Words',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8.h),

        // Button 2: Finish and exit
        ScaleButton(
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Text(
              'Done & Return Home',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionContent(BuildContext context, bool isDark) {
    final quest = widget.quests[_currentIndex];
    final totalQuestions = widget.quests.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header & Progress Bar ───────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(LucideIcons.sparkles, size: 16.r, color: AppColors.teal500),
                SizedBox(width: 8.w),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.teal500,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(LucideIcons.x, size: 20.r),
              color: isDark ? Colors.white54 : Colors.black45,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        SizedBox(height: 8.h),

        // 3-Question Step Progress Indicators
        Row(
          children: List.generate(totalQuestions, (idx) {
            final isPast = idx < _currentIndex;
            final isCurrent = idx == _currentIndex;

            return Expanded(
              child: Container(
                height: 6.h,
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                decoration: BoxDecoration(
                  gradient: isCurrent || isPast
                      ? const LinearGradient(
                          colors: [AppColors.indigo500, AppColors.teal500],
                        )
                      : null,
                  color: isCurrent || isPast
                      ? null
                      : (isDark ? Colors.white12 : Colors.black12),
                  borderRadius: BorderRadius.circular(999.r),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 20.h),

        // ── Question Instruction ────────────────────────────────────────────
        Text(
          quest.instruction,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        SizedBox(height: 8.h),

        // Question Prompt
        Text(
          quest.sentence ?? quest.question ?? 'Select the correct answer:',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 17.sp,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
            height: 1.35,
          ),
        ),
        SizedBox(height: 20.h),

        // ── Options List ────────────────────────────────────────────────────
        if (quest.options != null)
          ...List.generate(quest.options!.length, (index) {
            final option = quest.options![index];
            final isSelected = _selectedOptionIndex == index;
            final isCorrectOption = index == quest.correctAnswerIndex;

            Color borderColor = isDark ? Colors.white12 : Colors.black12;
            Color bgColor = isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03);

            if (_selectedOptionIndex != null) {
              if (isCorrectOption) {
                borderColor = AppColors.teal500;
                bgColor = AppColors.teal500.withValues(alpha: 0.2);
              } else if (isSelected) {
                borderColor = AppColors.rose500;
                bgColor = AppColors.rose500.withValues(alpha: 0.2);
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: ScaleButton(
                onTap: () => _onOptionSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: borderColor,
                      width: isSelected || (_selectedOptionIndex != null && isCorrectOption) ? 2.w : 1.w,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      if (_selectedOptionIndex != null)
                        if (isCorrectOption)
                          Icon(LucideIcons.checkCircle2, color: AppColors.teal500, size: 20.r)
                        else if (isSelected)
                          Icon(LucideIcons.xCircle, color: AppColors.rose500, size: 20.r),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
