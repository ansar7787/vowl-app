import 'dart:math';
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

/// Mechanic 2: Type Duel 📝
/// Shows definition → player types the exact word from memory.
/// Autocomplete disabled, case-insensitive, shows real-time rival char count.
class ArenaTypeDuelMechanic extends StatefulWidget {
  final ArenaChallenge challenge;
  final ArenaDuelState state;
  final bool isDark;
  final bool isMidnight;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<String> onSubmitWord;

  const ArenaTypeDuelMechanic({
    super.key,
    required this.challenge,
    required this.state,
    required this.isDark,
    required this.isMidnight,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTextChanged,
    required this.onSubmitWord,
  });

  @override
  State<ArenaTypeDuelMechanic> createState() => _ArenaTypeDuelMechanicState();
}

class _ArenaTypeDuelMechanicState extends State<ArenaTypeDuelMechanic> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant ArenaTypeDuelMechanic oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.challenge.id != widget.challenge.id) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (widget.state.isAnswered) return;
    final typed = _controller.text.trim();
    if (typed.isEmpty) return;

    final normalized = typed.toLowerCase();
    final matchesTarget =
        normalized == widget.challenge.correctAnswer.trim().toLowerCase() ||
        (widget.challenge.acceptedSpellings ?? []).any(
          (s) => s.trim().toLowerCase() == normalized,
        );

    if (matchesTarget) {
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
    widget.onSubmitWord(typed);
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isMidnight
        ? AppColors.midnightSurface
        : (widget.isDark ? AppColors.slate800 : Colors.white);
    final isAnswered = widget.state.isAnswered;
    final isCorrect = widget.state.isCorrect == true;
    final targetLen = max(
      1,
      widget.challenge.letterCount ?? widget.challenge.correctAnswer.length,
    );
    final rivalTyped = (widget.state.rivalCharactersTyped ?? 0).clamp(
      0,
      targetLen,
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Definition Card
          Container(
            padding: EdgeInsets.all(AppSpacing.card),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.emerald500.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'TYPE THE EXACT WORD',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.5.sp,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w800,
                          color: widget.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emerald500.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        '$targetLen LETTERS',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.emerald500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Text(
                  widget.challenge.prompt,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.38,
                    color: widget.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // Live Rival Typing Progress Meter
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: widget.isDark ? AppColors.slate900 : AppColors.slate50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: widget.borderColor),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.keyboard,
                  size: 14.sp,
                  color: AppColors.amber500,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Rival typing:',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: widget.textSecondary,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Row(
                    children: List.generate(targetLen, (i) {
                      final filled = i < rivalTyped;
                      return Expanded(
                        child: Container(
                          height: 6.h,
                          margin: EdgeInsets.symmetric(horizontal: 1.5.w),
                          decoration: BoxDecoration(
                            color: filled
                                ? AppColors.amber500
                                : (widget.isDark
                                      ? AppColors.slate700
                                      : AppColors.slate200),
                            borderRadius: BorderRadius.circular(3.r),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '$rivalTyped/$targetLen',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.amber500,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 14.h),

          // Answer TextField (autocorrect & suggestions disabled for pure recall)
          TextField(
            controller: _controller,
            enabled: !isAnswered,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            textInputAction: TextInputAction.send,
            onChanged: (val) {
              setState(() {});
              widget.onTextChanged(val);
            },
            onSubmitted: (_) => _handleSubmit(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: widget.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Type the word here...',
              hintStyle: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: widget.textSecondary.withValues(alpha: 0.6),
              ),
              filled: true,
              fillColor: cardBg,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(color: widget.borderColor, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(
                  color: AppColors.indigo500.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: const BorderSide(
                  color: AppColors.indigo500,
                  width: 2.0,
                ),
              ),
            ),
          ),

          SizedBox(height: 14.h),

          if (!isAnswered)
            ScaleButton(
              onTap: _controller.text.trim().isEmpty ? null : _handleSubmit,
              child: Container(
                height: 48.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: _controller.text.trim().isEmpty
                      ? null
                      : const LinearGradient(
                          colors: [AppColors.indigo500, AppColors.indigo600],
                        ),
                  color: _controller.text.trim().isEmpty
                      ? (widget.isDark
                            ? AppColors.slate800
                            : AppColors.slate200)
                      : null,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.send,
                      size: 16.sp,
                      color: _controller.text.trim().isEmpty
                          ? widget.textSecondary
                          : Colors.white,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Submit Word',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: _controller.text.trim().isEmpty
                            ? widget.textSecondary
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (isAnswered)
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
                        ? 'Exact match! ${widget.challenge.correctAnswer}'
                        : 'Correct answer: ${widget.challenge.correctAnswer}',
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
      ),
    );
  }
}
