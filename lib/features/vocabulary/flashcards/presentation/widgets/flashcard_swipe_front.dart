import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

/// Front-facing flashcard view displaying prompt clues, category icons, and flip affordances.
class FlashcardSwipeFront extends StatefulWidget {
  /// The active vocabulary quest item.
  final VocabularyQuest quest;

  /// Theme accent color for cards and glow effects.
  final Color color;

  /// Whether dark theme is enabled.
  final bool isDark;

  /// Card layout width constraint.
  final double width;

  /// Card layout height constraint.
  final double height;

  /// Creates a [FlashcardSwipeFront] widget.
  const FlashcardSwipeFront({
    super.key,
    required this.quest,
    required this.color,
    required this.isDark,
    required this.width,
    required this.height,
  });

  @override
  State<FlashcardSwipeFront> createState() => _FlashcardSwipeFrontState();
}

class _FlashcardSwipeFrontState extends State<FlashcardSwipeFront> {
  late final ScrollController _scrollController;
  final HapticService _hapticService = di.sl<HapticService>();

  bool _hasHitTop = true;
  bool _hasHitBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
        VowlMotion.lowAnimationModeOverride.value;

    return Semantics(
      label:
          '${context.tr('games.hint', fallback: 'Hint')}: ${widget.quest.hint ?? InstructionHelper.getInstruction(widget.quest)}. ${context.tr('instructions.flashcards.tap_to_reveal', fallback: 'Tap card to flip')}',
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.slate800 : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: widget.isDark
                ? Colors.white10
                : widget.color.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, 15),
              spreadRadius: -5,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDark ? 0.4 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: Builder(
            builder: (context) {
              final compactHeight = widget.height < 260;
              final compactWidth = widget.width < 290;

              final emojiBox = Container(
                padding: EdgeInsets.all(compactHeight ? 12.r : 16.r),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  widget.quest.topicEmoji ?? '🏷️',
                  style: TextStyle(
                    fontSize: compactHeight ? 38.sp : 48.sp,
                  ),
                ),
              );

              final rawHint = widget.quest.hint ??
                  InstructionHelper.getInstruction(widget.quest);
              final trimmedHint = rawHint.trim();
              final displayHint = (trimmedHint == trimmedHint.toUpperCase() &&
                      trimmedHint.length > 2)
                  ? trimmedHint[0].toUpperCase() +
                      trimmedHint.substring(1).toLowerCase()
                  : trimmedHint;

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compactWidth ? 16.w : 22.w,
                  vertical: compactHeight ? 14.h : 20.h,
                ),
                child: Column(
                  children: [
                    const Spacer(),
                    reduceMotion
                        ? emojiBox
                        : emojiBox.animate().scale(
                            duration: 500.ms,
                            curve: Curves.elasticOut,
                          ),
                    SizedBox(height: compactHeight ? 10.h : 16.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'Clue',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: widget.color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    SizedBox(height: compactHeight ? 8.h : 12.h),
                    Flexible(
                      flex: 8,
                      child: RawScrollbar(
                        controller: _scrollController,
                        thumbColor: widget.color.withValues(alpha: 0.35),
                        radius: Radius.circular(8.r),
                        thickness: 3.w,
                        crossAxisMargin: -12.w,
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is OverscrollNotification) {
                              if (notification.overscroll < 0) {
                                if (!_hasHitTop) {
                                  _hasHitTop = true;
                                  _hapticService.heavy();
                                }
                              } else if (notification.overscroll > 0) {
                                if (!_hasHitBottom) {
                                  _hasHitBottom = true;
                                  _hapticService.heavy();
                                }
                              }
                            } else if (notification
                                is ScrollUpdateNotification) {
                              if (!notification.metrics.outOfRange &&
                                  !notification.metrics.atEdge) {
                                _hasHitTop = false;
                                _hasHitBottom = false;
                              }
                            }
                            return false;
                          },
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            child: Container(
                              alignment: Alignment.center,
                              constraints: BoxConstraints(
                                minHeight: compactHeight ? 60.h : 90.h,
                              ),
                              child: Text(
                                displayHint,
                                textAlign: TextAlign.center,
                                softWrap: true,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: compactWidth ? 16.sp : 19.sp,
                                  fontWeight: FontWeight.w500,
                                  color: widget.isDark
                                      ? Colors.white
                                      : AppColors.slate900,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
