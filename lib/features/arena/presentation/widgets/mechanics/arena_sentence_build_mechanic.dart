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

/// Mechanic 4: Sentence Build 🧩
/// Independent implementation: shuffled word tiles → tap in order.
/// Supports tap-placed-tile-to-undo and Clear All button.
class ArenaSentenceBuildMechanic extends StatefulWidget {
  final ArenaChallenge challenge;
  final ArenaDuelState state;
  final bool isDark;
  final bool isMidnight;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final ValueChanged<List<String>> onSubmitSentence;

  const ArenaSentenceBuildMechanic({
    super.key,
    required this.challenge,
    required this.state,
    required this.isDark,
    required this.isMidnight,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onSubmitSentence,
  });

  @override
  State<ArenaSentenceBuildMechanic> createState() =>
      _ArenaSentenceBuildMechanicState();
}

class _ArenaSentenceBuildMechanicState
    extends State<ArenaSentenceBuildMechanic> {
  late List<String> _wordPool;
  final List<int> _placedIndices = [];

  @override
  void initState() {
    super.initState();
    _initPool();
  }

  @override
  void didUpdateWidget(covariant ArenaSentenceBuildMechanic oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.challenge.id != widget.challenge.id) {
      _placedIndices.clear();
      _initPool();
    }
  }

  void _initPool() {
    _wordPool =
        widget.challenge.shuffledWords ??
        widget.challenge.correctAnswer.split(' ');
  }

  void _onPoolTap(int poolIndex) {
    if (widget.state.isAnswered) return;
    if (_placedIndices.contains(poolIndex)) return;

    if (di.sl.isRegistered<HapticService>()) {
      di.sl<HapticService>().light();
    }

    setState(() {
      _placedIndices.add(poolIndex);
    });

    if (_placedIndices.length == _wordPool.length) {
      final words = _placedIndices.map((i) => _wordPool[i]).toList();
      final built = words.join(' ').trim().toLowerCase();
      final target = widget.challenge.correctAnswer.trim().toLowerCase();
      final isCorrect = built == target;

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
      widget.onSubmitSentence(words);
    }
  }

  void _onPlacedTap(int slotPos) {
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
          // Header Card
          Container(
            padding: EdgeInsets.all(AppSpacing.compact),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: AppColors.violet500.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  widget.challenge.prompt.isNotEmpty
                      ? widget.challenge.prompt
                      : 'Arrange the words into the correct sentence',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w800,
                    color: widget.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${_placedIndices.length} / ${_wordPool.length} words placed',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.violet500,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // Answer Sentence Tray
          Container(
            constraints: BoxConstraints(minHeight: 86.h),
            padding: EdgeInsets.all(12.r),
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_placedIndices.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: Text(
                      'Tap words below in order...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.5.sp,
                        color: widget.textSecondary,
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 8.h,
                    children: List.generate(_placedIndices.length, (slotPos) {
                      final word = _wordPool[_placedIndices[slotPos]];
                      return GestureDetector(
                        onTap: isAnswered ? null : () => _onPlacedTap(slotPos),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 7.h,
                          ),
                          decoration: BoxDecoration(
                            color: isAnswered
                                ? (isCorrect
                                      ? AppColors.emerald500
                                      : AppColors.rose500)
                                : AppColors.violet500,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            word,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
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
                          'Tap any placed word to undo',
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

          // Shuffled Word Tiles Pool
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8.w,
            runSpacing: 10.h,
            children: List.generate(_wordPool.length, (poolIdx) {
              final isUsed = _placedIndices.contains(poolIdx);
              return ScaleButton(
                debounceDuration: Duration.zero,
                onTap: (isUsed || isAnswered)
                    ? null
                    : () => _onPoolTap(poolIdx),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 140),
                  opacity: isUsed ? 0.25 : 1.0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 9.h,
                    ),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.violet500.withValues(alpha: 0.4),
                        width: 1.4,
                      ),
                    ),
                    child: Text(
                      _wordPool[poolIdx],
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
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
                        ? 'Perfect sentence order!'
                        : 'Correct: ${widget.challenge.correctAnswer}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.5.sp,
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
