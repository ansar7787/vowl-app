import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/arena/domain/entities/arena_challenge.dart';
import 'package:vowl/features/arena/presentation/bloc/arena_duel_state.dart';

/// Mechanic 1: Word Snap ⚡
/// Independent implementation: scrambled letters → tap in order to spell word.
/// Supports tap-placed-tile-to-undo, Clear All button, and auto-submit.
class ArenaWordSnapMechanic extends StatefulWidget {
  final ArenaChallenge challenge;
  final ArenaDuelState state;
  final bool isDark;
  final bool isMidnight;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final ValueChanged<String> onSubmitWord;

  const ArenaWordSnapMechanic({
    super.key,
    required this.challenge,
    required this.state,
    required this.isDark,
    required this.isMidnight,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onSubmitWord,
  });

  @override
  State<ArenaWordSnapMechanic> createState() => _ArenaWordSnapMechanicState();
}

class _ArenaWordSnapMechanicState extends State<ArenaWordSnapMechanic> {
  late List<String> _poolLetters;
  final List<int> _placedIndices = [];

  @override
  void initState() {
    super.initState();
    _initPool();
  }

  @override
  void didUpdateWidget(covariant ArenaWordSnapMechanic oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.challenge.id != widget.challenge.id) {
      _placedIndices.clear();
      _initPool();
    }
  }

  void _initPool() {
    final source =
        (widget.challenge.scrambledLetters ?? widget.challenge.correctAnswer)
            .toUpperCase();
    _poolLetters = source.split('');
  }

  void _onPoolTileTap(int poolIndex) {
    if (widget.state.isAnswered) return;
    if (_placedIndices.contains(poolIndex)) return;
    if (_placedIndices.length >= _poolLetters.length) return;

    if (di.sl.isRegistered<HapticService>()) {
      di.sl<HapticService>().light();
    }

    setState(() {
      _placedIndices.add(poolIndex);
    });

    if (_placedIndices.length == _poolLetters.length) {
      final spelled = _placedIndices.map((i) => _poolLetters[i]).join('');
      final isCorrect =
          spelled.toLowerCase() ==
          widget.challenge.correctAnswer.trim().toLowerCase();
      if (isCorrect) {
        if (di.sl.isRegistered<HapticService>()) {
          di.sl<HapticService>().success();
        }
        if (di.sl.isRegistered<SoundService>()) {
          di.sl<SoundService>().playCorrect(
            comboStep: widget.state.currentQuestionIndex + 1,
          );
        }
      } else {
        if (di.sl.isRegistered<HapticService>()) {
          di.sl<HapticService>().error();
        }
        if (di.sl.isRegistered<SoundService>()) {
          di.sl<SoundService>().playWrong();
        }
      }
      widget.onSubmitWord(spelled);
    }
  }

  void _onPlacedTileTap(int slotPos) {
    if (widget.state.isAnswered) return;
    if (slotPos < 0 || slotPos >= _placedIndices.length) return;
    if (di.sl.isRegistered<HapticService>()) {
      di.sl<HapticService>().selection();
    }
    setState(() {
      _placedIndices.removeAt(slotPos);
    });
  }

  void _clearAll() {
    if (widget.state.isAnswered || _placedIndices.isEmpty) return;
    if (di.sl.isRegistered<HapticService>()) {
      di.sl<HapticService>().selection();
    }
    setState(() {
      _placedIndices.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isMidnight
        ? AppColors.midnightSurface
        : (widget.isDark ? AppColors.slate800 : Colors.white);
    final isAnswered = widget.state.isAnswered;
    final isCorrect = widget.state.isCorrect == true;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Prompt Card + Hint
          Container(
            padding: EdgeInsets.all(AppSpacing.card),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.indigo500.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'UNSCRAMBLE THE WORD',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.5.sp,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w800,
                    color: widget.textSecondary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  widget.challenge.prompt,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.5.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                    color: widget.textPrimary,
                  ),
                ),
                if (widget.challenge.hint != null &&
                    widget.challenge.hint!.isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.indigo500.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      widget.challenge.hint!,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: widget.isDark
                            ? AppColors.indigo400
                            : AppColors.indigo600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // Placed Letters Tray (Tap placed tile to undo)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: widget.isDark ? AppColors.slate900 : AppColors.slate50,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isAnswered
                    ? (isCorrect ? AppColors.emerald500 : AppColors.rose500)
                    : widget.borderColor,
                width: isAnswered ? 1.8 : 1.2,
              ),
            ),
            child: Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6.w,
                  runSpacing: 8.h,
                  children: List.generate(_poolLetters.length, (slotIdx) {
                    final hasTile = slotIdx < _placedIndices.length;
                    final letter = hasTile
                        ? _poolLetters[_placedIndices[slotIdx]]
                        : '';
                    final Color tileBg;
                    final Color tileBorder;
                    if (isAnswered && hasTile) {
                      tileBg = isCorrect
                          ? AppColors.emerald500.withValues(alpha: 0.2)
                          : AppColors.rose500.withValues(alpha: 0.2);
                      tileBorder = isCorrect
                          ? AppColors.emerald500
                          : AppColors.rose500;
                    } else if (hasTile) {
                      tileBg = AppColors.indigo500;
                      tileBorder = AppColors.indigo600;
                    } else {
                      tileBg = widget.isDark
                          ? AppColors.slate800
                          : Colors.white;
                      tileBorder = widget.borderColor;
                    }

                    return GestureDetector(
                      onTap: hasTile && !isAnswered
                          ? () => _onPlacedTileTap(slotIdx)
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        width: 34.w,
                        height: 40.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: tileBg,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: tileBorder, width: 1.5),
                        ),
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w900,
                            color: hasTile
                                ? (isAnswered
                                      ? widget.textPrimary
                                      : Colors.white)
                                : widget.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                if (_placedIndices.isNotEmpty && !isAnswered) ...[
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Tap a placed letter to undo',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: widget.textSecondary,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      TextButton.icon(
                        onPressed: _clearAll,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(
                          LucideIcons.rotateCcw,
                          size: 12.sp,
                          color: AppColors.rose500,
                        ),
                        label: Text(
                          'Clear All',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.rose500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // Available Scrambled Letter Tiles
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8.w,
            runSpacing: 8.h,
            children: List.generate(_poolLetters.length, (poolIdx) {
              final isUsed = _placedIndices.contains(poolIdx);
              return ScaleButton(
                debounceDuration: Duration.zero,
                onTap: (isUsed || isAnswered)
                    ? null
                    : () => _onPoolTileTap(poolIdx),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 140),
                  opacity: isUsed ? 0.25 : 1.0,
                  child: Container(
                    width: 44.w,
                    height: 48.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.indigo500.withValues(alpha: 0.45),
                        width: 1.5,
                      ),
                      boxShadow: isUsed
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.indigo500.withValues(
                                  alpha: 0.12,
                                ),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Text(
                      _poolLetters[poolIdx],
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: widget.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          if (isAnswered) ...[
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: isCorrect
                    ? AppColors.emerald500.withValues(alpha: 0.1)
                    : AppColors.rose500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isCorrect ? AppColors.emerald500 : AppColors.rose500,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCorrect
                        ? 'Correct! ${widget.challenge.correctAnswer.toUpperCase()}'
                        : 'Answer: ${widget.challenge.correctAnswer.toUpperCase()}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w900,
                      color: isCorrect
                          ? AppColors.emerald500
                          : AppColors.rose500,
                    ),
                  ),
                  if (widget.challenge.explanation.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      widget.challenge.explanation,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: widget.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
