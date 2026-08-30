import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';

class AntonymGradientScale extends StatefulWidget {
  final List<String> gradientScale;
  final Color primaryColor;

  const AntonymGradientScale({
    super.key,
    required this.gradientScale,
    required this.primaryColor,
  });

  @override
  State<AntonymGradientScale> createState() => _AntonymGradientScaleState();
}

class _AntonymGradientScaleState extends State<AntonymGradientScale> {
  late final ValueNotifier<double> _sliderNotifier;

  @override
  void initState() {
    super.initState();
    _sliderNotifier = ValueNotifier((widget.gradientScale.length - 1) / 2.0); // start in the middle
  }

  @override
  void dispose() {
    _sliderNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03);
    final textColor = isDark ? Colors.white : Colors.black87;
    
    final maxSteps = widget.gradientScale.length - 1;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 32.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: widget.primaryColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.linear_scale_rounded, color: widget.primaryColor, size: 18.r),
              SizedBox(width: 6.w),
              AutoSizeText(
                'INTENSITY SCALE',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  color: widget.primaryColor,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          ValueListenableBuilder<double>(
            valueListenable: _sliderNotifier,
            builder: (context, sliderValue, _) {
              final currentIndex = sliderValue.round().clamp(0, maxSteps);
              final currentWord = widget.gradientScale[currentIndex];
              
              return Column(
                children: [
                  // Current Word Display
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 20.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.primaryColor.withValues(alpha: 0.15),
                          widget.primaryColor.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: widget.primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: AutoSizeText(
                      currentWord.toUpperCase(),
                      maxLines: 1,
                      minFontSize: 12,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ).animate(key: ValueKey(currentWord)).scale(duration: 200.ms, curve: Curves.easeOutBack),
                  
                  SizedBox(height: 12.h),
                  
                  // Slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: widget.primaryColor,
                      inactiveTrackColor: widget.primaryColor.withValues(alpha: 0.2),
                      thumbColor: widget.primaryColor,
                      overlayColor: widget.primaryColor.withValues(alpha: 0.2),
                      trackHeight: 6.h,
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.r),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 20.r),
                      activeTickMarkColor: Colors.transparent,
                      inactiveTickMarkColor: Colors.transparent,
                    ),
                    child: Slider(
                      value: sliderValue,
                      min: 0,
                      max: maxSteps.toDouble(),
                      divisions: maxSteps > 0 ? maxSteps : 1,
                      onChanged: (value) {
                        _sliderNotifier.value = value;
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Labels (Start & End)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AutoSizeText(
                  widget.gradientScale.first.toUpperCase(),
                  maxLines: 1,
                  minFontSize: 8,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    color: widget.primaryColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Expanded(
                child: AutoSizeText(
                  widget.gradientScale.last.toUpperCase(),
                  maxLines: 1,
                  minFontSize: 8,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    color: widget.primaryColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
  }
}
