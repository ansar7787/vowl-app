import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class ConnectedSpeechSpectralSlider extends StatefulWidget {
  final List<String> options;
  final int correctIndex;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final int? selectedIndex;
  final double initialSliderValue;
  final Function(int, int) onSubmitChoice;
  final Function(double, int) onSliderUpdate;
  final bool isCompact;

  const ConnectedSpeechSpectralSlider({
    super.key,
    required this.options,
    required this.correctIndex,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.selectedIndex,
    required this.initialSliderValue,
    required this.onSubmitChoice,
    required this.onSliderUpdate,
    this.isCompact = false,
  });

  @override
  State<ConnectedSpeechSpectralSlider> createState() => _ConnectedSpeechSpectralSliderState();
}

class _ConnectedSpeechSpectralSliderState extends State<ConnectedSpeechSpectralSlider> {
  late double _localSliderValue;

  @override
  void initState() {
    super.initState();
    _localSliderValue = widget.initialSliderValue;
  }

  @override
  void didUpdateWidget(covariant ConnectedSpeechSpectralSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSliderValue != oldWidget.initialSliderValue ||
        widget.selectedIndex != oldWidget.selectedIndex ||
        widget.isAnswered != oldWidget.isAnswered) {
      _localSliderValue = widget.selectedIndex == null
          ? widget.initialSliderValue
          : (widget.selectedIndex == 0 ? 0.0 : 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildConnectedSpeechOrb(
                widget.options[0],
                0,
                widget.correctIndex,
                widget.color,
                widget.isDark,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _buildConnectedSpeechOrb(
                widget.options[1],
                1,
                widget.correctIndex,
                widget.color,
                widget.isDark,
              ),
            ),
          ],
        ),
        SizedBox(height: widget.isCompact ? 16.h : 32.h),
        _buildSliderBar(widget.correctIndex, widget.color),
      ],
    );
  }

  Widget _buildConnectedSpeechOrb(
    String text,
    int index,
    int correctIndex,
    Color color,
    bool isDark,
  ) {
    final bool isSelected = widget.selectedIndex == index;
    final bool correct = index == correctIndex;

    Color orbColor = color.withValues(alpha: 0.1);
    Color textColor = color;
    if (widget.isAnswered && isSelected) {
      orbColor = correct
          ? Colors.greenAccent.withValues(alpha: 0.2)
          : Colors.redAccent.withValues(alpha: 0.2);
      textColor = correct ? Colors.greenAccent : Colors.redAccent;
    } else if (isSelected) {
      orbColor = color;
      textColor = Colors.white;
    }

    return ScaleButton(
      onTap: widget.isAnswered
          ? null
          : () => widget.onSubmitChoice(index, correctIndex),
      child: Container(
        height: widget.isCompact ? 70.h : 100.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: widget.isCompact ? 4.h : 8.h),
        decoration: BoxDecoration(
          color: orbColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: widget.isAnswered && isSelected
                ? textColor
                : color.withValues(alpha: isSelected ? 1.0 : 0.3),
            width: widget.isCompact ? 2 : 3,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? (correct
                      ? Colors.greenAccent.withValues(alpha: 0.3)
                      : color.withValues(alpha: 0.3))
                  : Colors.transparent,
              blurRadius: widget.isCompact ? 10 : 15,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: widget.isCompact ? 10.sp : 12.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.2,
            ),
          ),
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
            begin: const Offset(1, 1),
            end: const Offset(1.05, 1.05),
            duration: (2 + index).seconds,
          ),
    );
  }

  Widget _buildSliderBar(int correct, Color color) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: color,
        inactiveTrackColor: color.withValues(alpha: 0.1),
        thumbColor: color,
        overlayColor: color.withValues(alpha: 0.2),
        trackHeight: 10.h,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 16.r),
      ),
      child: IgnorePointer(
        ignoring: widget.isAnswered,
        child: Slider(
          value: _localSliderValue,
          onChanged: (v) {
            if (widget.isAnswered) return;
            setState(() {
              _localSliderValue = v;
            });
            widget.onSliderUpdate(v, correct);
          },
        ),
      ),
    );
  }
}
