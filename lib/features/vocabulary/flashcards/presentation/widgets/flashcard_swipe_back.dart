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

  double _getOptimalFontSize(
    String text,
    double availableWidth,
    double maxFontSize,
    double minFontSize,
  ) {
    if (text.isEmpty) return maxFontSize;
    double fontSize = maxFontSize;
    while (fontSize > minFontSize) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: double.infinity);

      final width = textPainter.width;
      textPainter.dispose(); // Prevent native memory leaks

      if (width <= availableWidth) {
        break;
      }
      fontSize -= 1;
    }
    return fontSize;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Word: ${widget.quest.word ?? ""}. Definition: ${widget.quest.definition ?? ""}. '
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
              final availableWordWidth = widget.width - 48.w;

              final optimalWordSize = _getOptimalFontSize(
                widget.quest.word?.toUpperCase() ?? '',
                availableWordWidth,
                maxWordFontSize,
                14.sp,
              );

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
                                horizontal: 24.w,
                                vertical: 24.h,
                              ),
                              sliver: SliverFillRemaining(
                                hasScrollBody: false,
                                child: Stack(
                                  children: [
                                    Align(
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(height: 16.h),
                                          Text(
                                            widget.quest.word?.toUpperCase() ??
                                                '',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: optimalWordSize,
                                              color: widget.isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 2,
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
                                    if (widget.quest.example != null &&
                                        widget.quest.example!.isNotEmpty) ...[
                                      SizedBox(height: compact ? 18.h : 28.h),
                                      Divider(
                                        color: widget.color.withValues(
                                          alpha: 0.1,
                                        ),
                                        thickness: 1,
                                        indent: dividerInset,
                                        endIndent: dividerInset,
                                      ),
                                      SizedBox(height: compact ? 16.h : 24.h),
                                    ],
                                    if (widget.quest.example != null &&
                                        widget.quest.example!.isNotEmpty) ...[
                                      Text(
                                        'EXAMPLE',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 10.sp,
                                          color: Colors.amber.shade700,
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
                                    Positioned(
                                      top: 0,
                                      right: 0,
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
                                          color: widget.color.withValues(alpha: 0.8),
                                          size: iconSize,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        splashRadius: 24.r,
                                      ),
                                    ),
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
