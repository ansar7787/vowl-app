import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      label: 'Hint: ${widget.quest.hint ?? widget.quest.instruction}. Tap to reveal word.',
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: widget.isDark ? Colors.white10 : widget.color.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 25,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compactHeight = constraints.maxHeight < 260;
              final compactWidth = constraints.maxWidth < 290;

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
                        style: TextStyle(fontSize: compactHeight ? 44.sp : 58.sp),
                      ),
                    ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                    SizedBox(height: compactHeight ? 16.h : 24.h),
                    Flexible(
                      flex: 6,
                      child: Center(
                        child: RawScrollbar(
                          controller: _scrollController,
                          thumbColor: widget.color.withValues(alpha: 0.4),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          crossAxisMargin: -16.w, // Push scrollbar to the very edge of the card
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            child: Text(
                          widget.quest.hint ?? widget.quest.instruction,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: compactWidth ? 18.sp : 22.sp, // Standardized
                            fontWeight: FontWeight.w600, // Reduced from w700
                            color: widget.isDark ? Colors.white : Colors.black87,
                            height: 1.4, // Increased line height for readability
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
