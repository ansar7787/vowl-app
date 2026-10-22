import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class _LocalPalette {
  _LocalPalette._();
  static const Color color131326 = Color(0xFF131326);
  static const Color color1b1b33 = Color(0xFF1B1B33);
  static const Color color0f0f1d = Color(0xFF0F0F1D);
}

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
      borderRadius: BorderRadius.circular(24.r),
      child: GestureDetector(
        key: const Key('situation_speaking_briefing_card_gesture'),
        onTap: () {
          if (!_isFinishedTyping) {
            _finishTyping();
          }
        },
        child: Container(
          width: 1.sw,
          constraints: BoxConstraints(minHeight: 180.h),
          decoration: BoxDecoration(
            color: widget.isDark ? _LocalPalette.color131326 : Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: _isFinishedTyping || widget.isAnswered
                  ? widget.primaryColor.withValues(alpha: 0.35)
                  : widget.isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : widget.primaryColor.withValues(alpha: 0.06),
                blurRadius: 16.r,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background Pattern/Gradient
              Container(
                constraints: BoxConstraints(minHeight: 180.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isDark
                        ? [_LocalPalette.color1b1b33, _LocalPalette.color0f0f1d]
                        : [
                            widget.primaryColor.withValues(alpha: 0.04),
                            Colors.white,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24.r),
                ),
                padding: EdgeInsets.all(20.r),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.forum_rounded,
                                color: widget.primaryColor,
                                size: 16.r,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  "THE SITUATION",
                                  key: const Key(
                                    'situation_speaking_briefing_title',
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    color: widget.primaryColor,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isFinishedTyping || widget.isAnswered)
                          Semantics(
                            button: true,
                            label: 'Listen to situation audio',
                            child: ScaleButton(
                              key: const Key('situation_speaking_tts_button'),
                              onTap: widget.onPlayTts,
                              child: Padding(
                                padding: EdgeInsets.all(6.r),
                                child: Icon(
                                  Icons.volume_up_rounded,
                                  color: widget.primaryColor,
                                  size: 22.r,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 20.h),

                    // Body Text
                    SizedBox(
                      width: double.infinity,
                      child: _isFinishedTyping || widget.isAnswered
                          ? Text(
                              widget.quest.situationText ??
                                  "Situation description.",
                              key: const Key('situation_speaking_body_text'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: widget.isDark
                                    ? Colors.white.withValues(alpha: 0.95)
                                    : const Color(0xFF1E293B),
                                height: 1.48,
                              ),
                            )
                          : _TypewriterText(
                              key: const Key(
                                'situation_speaking_typewriter_text',
                              ),
                              text:
                                  widget.quest.situationText ??
                                  "Situation description.",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: widget.isDark
                                    ? Colors.white.withValues(alpha: 0.95)
                                    : const Color(0xFF1E293B),
                                height: 1.48,
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
                                padding: EdgeInsets.only(top: 20.h),
                                child: Semantics(
                                  container: true,
                                  label:
                                      'Speaking guide hint: ${widget.quest.hint}',
                                  child: Container(
                                    key: const Key(
                                      'situation_speaking_hint_container',
                                    ),
                                    padding: EdgeInsets.all(14.r),
                                    decoration: BoxDecoration(
                                      color: widget.primaryColor
                                          .withValues(alpha: 0.08),
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
                                              CrossAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.lightbulb_outline_rounded,
                                              color: widget.primaryColor,
                                              size: 16.r,
                                            ),
                                            SizedBox(width: 6.w),
                                            Expanded(
                                              child: Text(
                                                "SPEAKING TIP",
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 11.5.sp,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  color:
                                                      widget.primaryColor,
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8.h),
                                        Text(
                                          widget.quest.hint!,
                                          key: const Key(
                                            'situation_speaking_hint_text',
                                          ),
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 13.5.sp,
                                            fontWeight: FontWeight.w400,
                                            color: widget.isDark
                                                ? Colors.white70
                                                : const Color(0xFF475569),
                                            height: 1.45,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
    super.key,
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
    final bool reduceMotion = VowlMotion.lowAnimationModeOverride.value;
    if (reduceMotion || widget.text.isEmpty) {
      _controller = AnimationController(
        vsync: this,
        duration: Duration.zero,
      );
      _characterCount =
          StepTween(begin: widget.text.length, end: widget.text.length)
              .animate(_controller);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onFinished();
      });
      return;
    }
    _controller = AnimationController(
      vsync: this,
      duration: widget.speed * widget.text.length,
    );
    _characterCount =
        StepTween(begin: 0, end: widget.text.length).animate(_controller)
          ..addListener(() {
            if (mounted) setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              widget.onFinished();
            }
          });
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        VowlMotion.lowAnimationModeOverride.value) {
      if (_controller.isAnimating) {
        _controller.stop();
        _controller.value = 1.0;
        widget.onFinished();
      }
    }
  }

  @override
  void didUpdateWidget(covariant _TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.stop();
      if (VowlMotion.lowAnimationModeOverride.value || widget.text.isEmpty) {
        _characterCount =
            StepTween(begin: widget.text.length, end: widget.text.length)
                .animate(_controller);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onFinished();
        });
      } else {
        _controller.duration = widget.speed * widget.text.length;
        _characterCount =
            StepTween(begin: 0, end: widget.text.length).animate(_controller);
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = _characterCount.value.clamp(0, widget.text.length);
    final visibleText = widget.text.substring(0, count);
    return Text(
      visibleText,
      key: const Key('situation_speaking_body_text'),
      style: widget.style,
      textAlign: TextAlign.center,
    );
  }
}
