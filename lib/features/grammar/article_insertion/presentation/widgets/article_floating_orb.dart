import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class ArticleFloatingOrb extends StatefulWidget {
  final String article;
  final int index;
  final VoidCallback onTap;
  final Color primaryColor;
  final bool isDark;
  final bool isAnswered;
  final bool isSelected;
  final bool isCorrectAnswer;

  final bool isCompact;

  const ArticleFloatingOrb({
    super.key,
    required this.article,
    required this.index,
    required this.onTap,
    required this.primaryColor,
    required this.isDark,
    required this.isAnswered,
    required this.isSelected,
    required this.isCorrectAnswer,
    this.isCompact = false,
  });

  @override
  State<ArticleFloatingOrb> createState() => _ArticleFloatingOrbState();
}

class _ArticleFloatingOrbState extends State<ArticleFloatingOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _driftController;
  late double _top;
  late double _left;

  @override
  void initState() {
    super.initState();
    _top = widget.index * (widget.isCompact ? 40.h : 70.h) + (widget.isCompact ? 5.h : 20.h);
    _left = (widget.index % 2 == 0) ? (widget.isCompact ? 55.w : 45.w) : (widget.isCompact ? 220.w : 210.w);
    _driftController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 4 + widget.index),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _driftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color borderColor;
    List<Color> gradientColors;
    double opacity = 1.0;
    List<BoxShadow> shadows = [];

    if (!widget.isAnswered) {
      textColor = widget.isDark ? Colors.white : Colors.black87;
      borderColor = widget.isDark ? Colors.white30 : Colors.black26;
      gradientColors = [
        widget.primaryColor.withValues(alpha: 0.25),
        widget.primaryColor.withValues(alpha: 0.1),
        Colors.white.withValues(alpha: 0.05),
      ];
      shadows = [
        BoxShadow(
          color: widget.primaryColor.withValues(alpha: 0.08),
          blurRadius: 15,
          spreadRadius: 2,
        ),
      ];
    } else {
      if (widget.isSelected) {
        if (widget.isCorrectAnswer) {
          textColor = Colors.greenAccent;
          borderColor = Colors.greenAccent;
          gradientColors = [
            Colors.greenAccent.withValues(alpha: 0.3),
            Colors.greenAccent.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ];
          shadows = [
            BoxShadow(
              color: Colors.greenAccent.withValues(alpha: 0.3),
              blurRadius: 25,
              spreadRadius: 4,
            ),
          ];
        } else {
          textColor = Colors.redAccent;
          borderColor = Colors.redAccent;
          gradientColors = [
            Colors.redAccent.withValues(alpha: 0.3),
            Colors.redAccent.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ];
          shadows = [
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.3),
              blurRadius: 25,
              spreadRadius: 4,
            ),
          ];
        }
      } else if (widget.isCorrectAnswer) {
        textColor = Colors.greenAccent;
        borderColor = Colors.greenAccent.withValues(alpha: 0.6);
        gradientColors = [
          Colors.greenAccent.withValues(alpha: 0.15),
          Colors.greenAccent.withValues(alpha: 0.05),
          Colors.transparent,
        ];
        shadows = [
          BoxShadow(
            color: Colors.greenAccent.withValues(alpha: 0.15),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ];
      } else {
        opacity = 0.25;
        textColor = widget.isDark ? Colors.white30 : Colors.black38;
        borderColor = Colors.transparent;
        gradientColors = [
          widget.primaryColor.withValues(alpha: 0.05),
          Colors.transparent,
        ];
      }
    }

    return AnimatedBuilder(
      animation: _driftController,
      builder: (context, child) {
        return Positioned(
          top: _top + (15.h * _driftController.value),
          left: _left + (12.w * (1 - _driftController.value)),
          child: Opacity(
            opacity: opacity,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: widget.isCompact ? 65.r : 90.r,
                height: widget.isCompact ? 65.r : 90.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.3),
                    colors: gradientColors,
                  ),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: shadows,
                ),
                child: Center(
                  child: Text(
                    widget.article.toUpperCase(),
                    style: TextStyle(fontFamily: 'Outfit', 
                      fontSize: widget.isCompact ? 14.sp : 18.sp,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.08, 1.08),
                duration: 2500.ms,
                curve: Curves.easeInOutSine,
              ),
            ),
          ),
        );
      },
    );
  }
}
