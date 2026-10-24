import 'dart:async';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

/// Back-facing flashcard view revealing the target word, definition, TTS audio, and example sentences.
class FlashcardSwipeBack extends StatefulWidget {
  /// The active vocabulary quest item.
  final VocabularyQuest quest;

  /// Theme accent color for cards, buttons, and glow shadows.
  final Color color;

  /// Whether dark theme is enabled.
  final bool isDark;

  /// Card layout width constraint.
  final double width;

  /// Card layout height constraint.
  final double height;

  /// Whether a temporary hint peek is actively illuminating the definition.
  final bool isHintActive;

  /// Creates a [FlashcardSwipeBack] widget.
  const FlashcardSwipeBack({
    super.key,
    required this.quest,
    required this.color,
    required this.isDark,
    required this.width,
    required this.height,
    required this.isHintActive,
  });

  @override
  State<FlashcardSwipeBack> createState() => _FlashcardSwipeBackState();
}

class _FlashcardSwipeBackState extends State<FlashcardSwipeBack> {
  late final ScrollController _scrollController;
  final TtsService _ttsService = di.sl<TtsService>();
  final HapticService _hapticService = di.sl<HapticService>();
  Timer? _ttsTimer;

  bool _hasHitTop = true;
  bool _hasHitBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    if (widget.quest.word != null && widget.quest.word!.isNotEmpty) {
      _ttsTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) _ttsService.speak(widget.quest.word!);
      });
    }
  }

  @override
  void dispose() {
    _ttsTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Word: ${widget.quest.word ?? ""}. Definition: ${widget.quest.definition ?? ""}. '
          '${widget.quest.explanation != null ? "Explanation: ${widget.quest.explanation}. " : ""}'
          '${widget.quest.example != null ? "Example: ${widget.quest.example}" : ""}',
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.slate900 : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: widget.isDark
                ? Colors.white10
                : widget.color.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.2),
              blurRadius: 30,
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
              final compact = widget.height < 280 || widget.width < 280;
              final dividerInset = (widget.width * 0.12).clamp(16.0, 40.0);

              final maxWordFontSize = compact ? 22.sp : 26.sp;
              final iconSize = compact ? 22.r : 26.r;

              return Stack(
                children: [
                  if (widget.quest.topicEmoji != null &&
                      widget.quest.topicEmoji!.isNotEmpty)
                    Positioned(
                      right: -30.w,
                      bottom: -30.h,
                      child: Opacity(
                        opacity: widget.isDark ? 0.06 : 0.08,
                        child: Text(
                          widget.quest.topicEmoji!,
                          style: TextStyle(fontSize: 180.sp),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: RawScrollbar(
                      controller: _scrollController,
                      thumbColor: widget.color.withValues(alpha: 0.35),
                      radius: Radius.circular(8.r),
                      thickness: 3.w,
                      crossAxisMargin: 2.w,
                      mainAxisMargin: 8.h,
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
                          } else if (notification is ScrollUpdateNotification) {
                            if (!notification.metrics.outOfRange &&
                                !notification.metrics.atEdge) {
                              _hasHitTop = false;
                              _hasHitBottom = false;
                            }
                          }
                          return false;
                        },
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 14.h,
                              ),
                              sliver: SliverFillRemaining(
                                hasScrollBody: false,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        widget.quest.word?.toUpperCase() ?? '',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: maxWordFontSize,
                                          color: widget.isDark
                                              ? Colors.white
                                              : AppColors.slate900,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 6.h),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: widget.color.withValues(
                                          alpha: 0.1,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        onPressed: () {
                                          if (widget.quest.word != null) {
                                            _ttsService.speak(
                                              widget.quest.word!,
                                            );
                                          }
                                        },
                                        icon: Icon(
                                          Icons.volume_up_rounded,
                                          color: widget.color,
                                          size: iconSize,
                                        ),
                                        padding: EdgeInsets.all(8.r),
                                        constraints: const BoxConstraints(),
                                        splashRadius: 24.r,
                                      ),
                                    ),
                                    SizedBox(height: compact ? 10.h : 14.h),
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
                                        'Definition',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 11.sp,
                                          color: widget.color,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: compact ? 6.h : 8.h),
                                    Text(
                                      widget.quest.definition ?? '',
                                      textAlign: TextAlign.center,
                                      softWrap: true,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: compact ? 15.sp : 17.sp,
                                        color: widget.isHintActive
                                            ? widget.color
                                            : (widget.isDark
                                                  ? Colors.white
                                                  : AppColors.slate900),
                                        height: 1.45,
                                        fontWeight: widget.isHintActive
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        shadows: widget.isHintActive
                                            ? [
                                                Shadow(
                                                  color: widget.color
                                                      .withValues(alpha: 0.4),
                                                  blurRadius: 8,
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ),
                                    if (widget.quest.explanation != null &&
                                        widget
                                            .quest
                                            .explanation!
                                            .isNotEmpty) ...[
                                      SizedBox(height: compact ? 10.h : 14.h),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 14.w,
                                          vertical: 10.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: widget.color.withValues(
                                            alpha: 0.05,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14.r,
                                          ),
                                          border: Border.all(
                                            color: widget.color.withValues(
                                              alpha: 0.15,
                                            ),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons
                                                      .lightbulb_outline_rounded,
                                                  color: widget.color,
                                                  size: 15.r,
                                                ),
                                                SizedBox(width: 6.w),
                                                Text(
                                                  'Note',
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 11.sp,
                                                    color: widget.color,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 6.h),
                                            Text(
                                              widget.quest.explanation!,
                                              textAlign: TextAlign.center,
                                              softWrap: true,
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: compact
                                                    ? 13.sp
                                                    : 14.sp,
                                                color: widget.isDark
                                                    ? AppColors.slate200
                                                    : AppColors.slate800,
                                                height: 1.45,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (widget.quest.example != null &&
                                        widget.quest.example!.isNotEmpty) ...[
                                      SizedBox(height: compact ? 10.h : 14.h),
                                      Divider(
                                        color: widget.color.withValues(
                                          alpha: 0.1,
                                        ),
                                        thickness: 1,
                                        indent: dividerInset,
                                        endIndent: dividerInset,
                                      ),
                                      SizedBox(height: compact ? 8.h : 12.h),
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
                                          'Example',
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 11.sp,
                                            color: widget.color,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        widget.quest.example!,
                                        textAlign: TextAlign.center,
                                        softWrap: true,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: compact ? 13.sp : 14.sp,
                                          color: widget.isDark
                                              ? AppColors.slate200
                                              : AppColors.slate700,
                                          height: 1.45,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      if (widget.quest.usageExample != null &&
                                          widget
                                              .quest
                                              .usageExample!
                                              .isNotEmpty) ...[
                                        SizedBox(height: compact ? 6.h : 8.h),
                                        Text(
                                          widget.quest.usageExample!,
                                          textAlign: TextAlign.center,
                                          softWrap: true,
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: compact ? 12.sp : 13.sp,
                                            color: widget.isDark
                                                ? AppColors.slate400
                                                : AppColors.slate600,
                                            fontStyle: FontStyle.italic,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ],
                                    SizedBox(height: 8.h),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
