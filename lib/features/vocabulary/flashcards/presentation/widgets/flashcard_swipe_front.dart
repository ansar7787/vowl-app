import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

class FlashcardSwipeFront extends StatefulWidget {
  final VocabularyQuest quest;
  final Color color;
  final bool isDark;
  final double width;
  final double height;

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
    return Semantics(
      label:
          '${context.tr('hint')}: ${widget.quest.hint ?? widget.quest.instruction}. ${context.tr('instructions.flashcards.tap_to_reveal')}',
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
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

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    Container(
                      padding: EdgeInsets.all(compactHeight ? 16.r : 20.r),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        widget.quest.topicEmoji ?? '🏷️',
                        style: TextStyle(
                          fontSize: compactHeight ? 44.sp : 58.sp,
                        ),
                      ),
                    ).animate().scale(
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ),
                    SizedBox(height: compactHeight ? 16.h : 24.h),
                    Flexible(
                      flex: 6,
                      child: Center(
                        child: AutoSizeText(
                          widget.quest.hint ?? widget.quest.instruction,
                          textAlign: TextAlign.center,
                          minFontSize: 14,
                          wrapWords: false,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: compactWidth ? 18.sp : 22.sp,
                            fontWeight: FontWeight.w600,
                            color: widget.isDark
                                ? Colors.white
                                : Colors.black87,
                            height: 1.4,
                          ),
                          overflowReplacement: RawScrollbar(
                            controller: _scrollController,
                            thumbColor: widget.color.withValues(alpha: 0.4),
                            radius: Radius.circular(8.r),
                            thickness: 4.w,
                            crossAxisMargin: -16.w,
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
                                  if (!notification.metrics.outOfRange && !notification.metrics.atEdge) {
                                    _hasHitTop = false;
                                    _hasHitBottom = false;
                                  }
                                }
                                return false;
                              },
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                physics: const BouncingScrollPhysics(),
                              child: Text(
                                widget.quest.hint ?? widget.quest.instruction,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: widget.isDark
                                      ? Colors.white
                                      : Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
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
