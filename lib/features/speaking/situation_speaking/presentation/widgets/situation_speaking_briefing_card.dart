import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class SituationSpeakingBriefingCard extends StatefulWidget {
  final SpeakingQuest quest;
  final Color primaryColor;
  final bool isDark;
  final bool isAnswered;
  final bool hintUsed;
  final VoidCallback onBriefingComplete;
  final VoidCallback onPlayTts;

  const SituationSpeakingBriefingCard({
    super.key,
    required this.quest,
    required this.primaryColor,
    required this.isDark,
    required this.isAnswered,
    required this.hintUsed,
    required this.onBriefingComplete,
    required this.onPlayTts,
  });

  @override
  State<SituationSpeakingBriefingCard> createState() =>
      _SituationSpeakingBriefingCardState();
}

class _SituationSpeakingBriefingCardState
    extends State<SituationSpeakingBriefingCard> {
  bool _isFinishedTyping = false;
  final _hapticService = di.sl<HapticService>();

  @override
  void didUpdateWidget(covariant SituationSpeakingBriefingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quest.id != widget.quest.id) {
      setState(() {
        _isFinishedTyping = false;
      });
    } else if (oldWidget.isAnswered && !widget.isAnswered) {
      if (_isFinishedTyping) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onBriefingComplete();
        });
      }
    }
  }

  void _finishTyping() {
    if (_isFinishedTyping) return;
    _hapticService.success();
    setState(() {
      _isFinishedTyping = true;
    });
    widget.onBriefingComplete();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28.r),
      child: GestureDetector(
        onTap: () {
          if (!_isFinishedTyping) {
            _finishTyping();
          }
        },
        child: Container(
          width: 1.sw,
          constraints: BoxConstraints(minHeight: 200.h),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF131326) : Colors.white,
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(
              color: _isFinishedTyping || widget.isAnswered
                  ? widget.primaryColor.withValues(alpha: 0.5)
                  : Colors.white10,
              width: _isFinishedTyping || widget.isAnswered ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isFinishedTyping || widget.isAnswered
                    ? widget.primaryColor.withValues(alpha: 0.2)
                    : Colors.black26,
                blurRadius: 15.r,
                spreadRadius: _isFinishedTyping || widget.isAnswered ? 2.r : 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background Pattern/Gradient
              Container(
                constraints: BoxConstraints(minHeight: 200.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isDark
                        ? [const Color(0xFF1B1B33), const Color(0xFF0F0F1D)]
                        : [
                            widget.primaryColor.withValues(alpha: 0.05),
                            Colors.white,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28.r),
                ),
                padding: EdgeInsets.all(22.r),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(top: 2.h),
                                child:
                                    Icon(
                                          Icons.assignment_late_rounded,
                                          color: widget.primaryColor,
                                          size: 16.r,
                                        )
                                        .animate(onPlay: (c) => c.repeat())
                                        .shake(hz: 2, curve: Curves.easeInOut)
                                        .then(delay: 2.seconds),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  "SCENARIO BRIEFING",
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: widget.primaryColor,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isFinishedTyping || widget.isAnswered)
                          ScaleButton(
                            onTap: widget.onPlayTts,
                            child: Padding(
                              padding: EdgeInsets.all(8.r),
                              child: Icon(
                                Icons.volume_up_rounded,
                                color: widget.primaryColor,
                                size: 24.r,
                              ),
                            ),
                          ).animate().scale(
                            duration: 300.ms,
                            curve: Curves.easeOutBack,
                          ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Body Text
                    SizedBox(
                      width: double.infinity,
                      child: _isFinishedTyping || widget.isAnswered
                          ? Text(
                              widget.quest.situationText ??
                                  "Situation description.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: widget.isDark
                                    ? Colors.white
                                    : Colors.black87,
                                height: 1.35,
                              ),
                            )
                          : _TypewriterText(
                              text:
                                  widget.quest.situationText ??
                                  "Situation description.",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: widget.isDark
                                    ? Colors.white
                                    : Colors.black87,
                                height: 1.35,
                              ),
                              speed: const Duration(milliseconds: 35),
                              onFinished: _finishTyping,
                            ),
                    ),

                    // Grammar Guide / Hint (Fades in when Hint is purchased and typing finishes)
                    if (widget.quest.hint != null &&
                        widget.quest.hint!.isNotEmpty &&
                        widget.hintUsed)
                      AnimatedSize(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        child: (_isFinishedTyping || widget.isAnswered)
                            ? Padding(
                                padding: EdgeInsets.only(top: 24.h),
                                child:
                                    Container(
                                          padding: EdgeInsets.all(16.r),
                                          decoration: BoxDecoration(
                                            color: widget.primaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                            border: Border.all(
                                              color: widget.primaryColor
                                                  .withValues(alpha: 0.2),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                      top: 1.h,
                                                    ),
                                                    child: Icon(
                                                      Icons
                                                          .lightbulb_outline_rounded,
                                                      color:
                                                          widget.primaryColor,
                                                      size: 16.r,
                                                    ),
                                                  ),
                                                  SizedBox(width: 6.w),
                                                  Expanded(
                                                    child: Text(
                                                      "SPEAKING GUIDE",
                                                      style: TextStyle(
                                                        fontFamily: 'Outfit',
                                                        fontSize: 10.sp,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            widget.primaryColor,
                                                        letterSpacing: 1.2,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 8.h),
                                              Text(
                                                widget.quest.hint!,
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w500,
                                                  color: widget.isDark
                                                      ? Colors.white70
                                                      : Colors.black87,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                        .animate()
                                        .fade(
                                          duration: 400.ms,
                                          curve: Curves.easeOut,
                                        )
                                        .slideY(
                                          begin: 0.2,
                                          end: 0,
                                          duration: 400.ms,
                                          curve: Curves.easeOut,
                                        ),
                              )
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration speed;
  final VoidCallback onFinished;

  const _TypewriterText({
    required this.text,
    required this.style,
    required this.speed,
    required this.onFinished,
  });

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _characterCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.speed * widget.text.length,
    );
    _characterCount =
        StepTween(begin: 0, end: widget.text.length).animate(_controller)
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              widget.onFinished();
            }
          });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String visibleText = widget.text.substring(0, _characterCount.value);
    return Text(visibleText, style: widget.style, textAlign: TextAlign.center);
  }
}
