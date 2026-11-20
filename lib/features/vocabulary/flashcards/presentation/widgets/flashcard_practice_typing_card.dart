import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shakeable_wrapper.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_practice_rune_slots.dart';

/// Cyber-Cloze Shard Assembly widget for the Flashcard Practice Phase.
///
/// Replaces standard text boxes with tactile, glowing rune letter slots,
/// interactive letter shards that snap on tap, and instant haptic confirmation.
class FlashcardPracticeTypingCard extends StatefulWidget {
  final PracticeExercise exercise;
  final TextEditingController textController;
  final bool hasChecked;
  final bool isAnswerCorrect;
  final int shakeCount;
  final bool isDark;
  final VoidCallback onCheck;

  const FlashcardPracticeTypingCard({
    super.key,
    required this.exercise,
    required this.textController,
    required this.hasChecked,
    required this.isAnswerCorrect,
    required this.shakeCount,
    required this.isDark,
    required this.onCheck,
  });

  @override
  State<FlashcardPracticeTypingCard> createState() =>
      _FlashcardPracticeTypingCardState();
}

class _FlashcardPracticeTypingCardState
    extends State<FlashcardPracticeTypingCard> {
  late final List<String> _shards;

  @override
  void initState() {
    super.initState();
    _shards = _generateLetterShards();
    widget.textController.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant FlashcardPracticeTypingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.correctAnswer != widget.exercise.correctAnswer) {
      _shards = _generateLetterShards();
    }
  }

  @override
  void dispose() {
    widget.textController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  List<String> _generateLetterShards() {
    final target = (widget.exercise.correctAnswer ?? '').toUpperCase().trim();
    final letters = <String>[];
    for (final char in target.runes) {
      final s = String.fromCharCode(char);
      if (s != ' ') letters.add(s);
    }

    // Add 3 deterministic distractor letters based on answer length & hash
    const distractors = ['E', 'A', 'R', 'T', 'S', 'O', 'N', 'I', 'L'];
    int seed = target.hashCode.abs();
    for (int i = 0; i < 3; i++) {
      final d = distractors[(seed + i * 3) % distractors.length];
      letters.add(d);
    }

    // Deterministic shuffle with seed
    final random = Random(seed);
    letters.shuffle(random);
    return letters;
  }

  void _onShardTap(String letter) {
    if (widget.hasChecked) return;
    final current = widget.textController.text;
    final targetLen = (widget.exercise.correctAnswer ?? '')
        .replaceAll(' ', '')
        .length;
    if (current.replaceAll(' ', '').length >= targetLen) return;

    if (di.sl.isRegistered<HapticService>()) {
      di.sl<HapticService>().selection();
    }
    widget.textController.text = current + letter;
  }

  void _onBackspace() {
    if (widget.hasChecked) return;
    final current = widget.textController.text;
    if (current.isNotEmpty) {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().light();
      }
      widget.textController.text = current.substring(0, current.length - 1);
    }
  }

  void _onClearAll() {
    if (widget.hasChecked) return;
    if (widget.textController.text.isNotEmpty) {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().light();
      }
      widget.textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetWord = (widget.exercise.correctAnswer ?? '')
        .toUpperCase()
        .trim();
    final currentText = widget.textController.text.toUpperCase();

    // Calculate shard usage counts
    final usedCounts = <String, int>{};
    for (final c in currentText.split('')) {
      usedCounts[c] = (usedCounts[c] ?? 0) + 1;
    }

    final poolCounts = <String, int>{};
    final shardAvailable = <bool>[];
    for (final s in _shards) {
      poolCounts[s] = (poolCounts[s] ?? 0) + 1;
      final used = usedCounts[s] ?? 0;
      shardAvailable.add(used < poolCounts[s]!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sentence prompt with illuminated gap
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.slate900 : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: widget.isDark
                  ? AppColors.indigo500.withValues(alpha: 0.3)
                  : AppColors.indigo500.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.indigo500.withValues(alpha: 0.08),
                blurRadius: 16.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Text(
            widget.exercise.sentence ?? widget.exercise.question ?? '',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: widget.isDark ? Colors.white : AppColors.slate900,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 20.h),

        // Glowing Rune Slots for the assembled word
        ShakeableWrapper(
          shakeCount: widget.shakeCount,
          child: FlashcardPracticeRuneSlots(
            targetWord: targetWord,
            currentText: currentText,
            hasChecked: widget.hasChecked,
            isAnswerCorrect: widget.isAnswerCorrect,
            isDark: widget.isDark,
          ),
        ),
        SizedBox(height: 18.h),

        // Shard Pool Controls (Clear & Backspace)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ScaleButton(
              onTap: widget.hasChecked ? null : _onClearAll,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? AppColors.slate800
                      : AppColors.slate100,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 14.r,
                      color: widget.isDark
                          ? AppColors.slate400
                          : AppColors.slate600,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Clear',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: widget.isDark
                            ? AppColors.slate400
                            : AppColors.slate600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Text(
                  'TAP SHARDS TO ASSEMBLE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: widget.isDark
                        ? AppColors.slate500
                        : AppColors.slate400,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            ScaleButton(
              onTap: widget.hasChecked ? null : _onBackspace,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? AppColors.slate800
                      : AppColors.slate100,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.backspace_rounded,
                      size: 14.r,
                      color: widget.isDark
                          ? AppColors.slate400
                          : AppColors.slate600,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Undo',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: widget.isDark
                            ? AppColors.slate400
                            : AppColors.slate600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // Floating Letter Shard Pool
        Wrap(
          spacing: 8.w,
          runSpacing: 10.h,
          alignment: WrapAlignment.center,
          children: List.generate(_shards.length, (idx) {
            final letter = _shards[idx];
            final available = shardAvailable[idx];

            return ScaleButton(
              onTap: (!available || widget.hasChecked)
                  ? null
                  : () => _onShardTap(letter),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: available ? 1.0 : 0.25,
                child: Container(
                  width: 44.r,
                  height: 48.r,
                  decoration: BoxDecoration(
                    color: widget.isDark ? AppColors.slate800 : Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: available
                          ? AppColors.indigo500.withValues(alpha: 0.5)
                          : (widget.isDark
                                ? AppColors.slate700
                                : AppColors.slate300),
                      width: 1.8,
                    ),
                    boxShadow: available
                        ? [
                            BoxShadow(
                              color: AppColors.indigo500.withValues(
                                alpha: 0.15,
                              ),
                              blurRadius: 8.r,
                              offset: Offset(0, 3.h),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: available
                            ? (widget.isDark
                                  ? Colors.white
                                  : AppColors.slate900)
                            : (widget.isDark
                                  ? AppColors.slate600
                                  : AppColors.slate400),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
