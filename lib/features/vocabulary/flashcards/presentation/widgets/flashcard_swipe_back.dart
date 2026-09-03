import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

class FlashcardSwipeBack extends StatefulWidget {
  final VocabularyQuest quest;
  final Color color;
  final bool isDark;
  final double width;
  final double height;
  final bool isHintActive;

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

  bool _hasHitTop = true;
  bool _hasHitBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    if (widget.quest.word != null && widget.quest.word!.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _ttsService.speak(widget.quest.word!);
      });
    }
  }

  @override
  void dispose() {
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
          color: widget.isDark ? const Color(0xFF0F172A) : Colors.white,
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

              final maxWordFontSize = compact ? 24.sp : 28.sp;
              final iconSize = compact ? 24.r : 28.r;

              return Stack(
                children: [
                  if (widget.quest.topicEmoji != null &&
                      widget.quest.topicEmoji!.isNotEmpty)
                    Positioned(
                      right: -40.w,
                      bottom: -40.h,
                      child: Opacity(
                        opacity: widget.isDark ? 0.08 : 0.12,
                        child: Text(
                          widget.quest.topicEmoji!,
                          style: TextStyle(fontSize: 220.sp),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: RawScrollbar(
                      controller: _scrollController,
                      thumbColor: widget.color.withValues(alpha: 0.4),
                      radius: Radius.circular(8.r),
                      thickness: 4.w,
                      crossAxisMargin:
                          2.w, // close to edge but padded by ClipRRect
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
                                vertical: 16.h,
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
                                              : Colors.black87,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
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
                                    SizedBox(height: compact ? 12.h : 16.h),
                                    Text(
                                      'DEFINITION',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 10.sp,
                                        color: widget.color,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    SizedBox(height: compact ? 8.h : 12.h),
                                    Text(
                                      widget.quest.definition ?? '',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: compact ? 17.sp : 19.sp,
                                        color: widget.isHintActive
                                            ? widget.color
                                            : (widget.isDark
                                                  ? Colors.white
                                                  : Colors.black87),
                                        height: 1.4,
                                        fontWeight: widget.isHintActive
                                            ? FontWeight.w900
                                            : FontWeight.w500,
                                        shadows: widget.isHintActive
                                            ? [
                                                Shadow(
                                                  color: widget.color
                                                      .withValues(alpha: 0.5),
                                                  blurRadius: 10,
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ),
                                    if (widget.quest.explanation != null &&
                                        widget.quest.explanation!.isNotEmpty) ...[
                                      SizedBox(height: compact ? 12.h : 16.h),
                                      Container(
                                        padding: EdgeInsets.all(12.r),
                                        decoration: BoxDecoration(
                                          color: widget.color.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(12.r),
                                          border: Border.all(color: widget.color.withValues(alpha: 0.2)),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.lightbulb_outline_rounded, color: widget.color, size: 14.r),
                                                SizedBox(width: 6.w),
                                                Text(
                                                  'DID YOU KNOW?',
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 10.sp,
                                                    color: widget.color,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 1.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 8.h),
                                            Text(
                                              widget.quest.explanation!,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: compact ? 13.sp : 14.sp,
                                                color: widget.isDark ? Colors.white70 : Colors.black87,
                                                height: 1.4,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (widget.quest.example != null &&
                                        widget.quest.example!.isNotEmpty) ...[
                                      SizedBox(height: compact ? 12.h : 16.h),
                                      Divider(
                                        color: widget.color.withValues(
                                          alpha: 0.1,
                                        ),
                                        thickness: 1,
                                        indent: dividerInset,
                                        endIndent: dividerInset,
                                      ),
                                      SizedBox(height: compact ? 12.h : 16.h),
                                    ],
                                    if (widget.quest.example != null &&
                                        widget.quest.example!.isNotEmpty) ...[
                                      Text(
                                        'EXAMPLE',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 10.sp,
                                          color: widget.color,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      SizedBox(height: 12.h),
                                      Text(
                                        widget.quest.example!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: compact ? 14.sp : 15.sp,
                                          color: widget.isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                          fontStyle: FontStyle.italic,
                                          height: 1.5,
                                        ),
                                      ),
                                      if (widget.quest.usageExample != null &&
                                          widget
                                              .quest
                                              .usageExample!
                                              .isNotEmpty) ...[
                                        SizedBox(height: compact ? 8.h : 12.h),
                                        Text(
                                          widget.quest.usageExample!,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: compact ? 14.sp : 15.sp,
                                            color: widget.isDark
                                                ? Colors.white70
                                                : Colors.black54,
                                            fontStyle: FontStyle.italic,
                                            height: 1.5,
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
