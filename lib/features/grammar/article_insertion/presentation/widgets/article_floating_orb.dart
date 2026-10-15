import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class ArticleFloatingOrb extends StatefulWidget {
  final String article;
  final int index;
  final VoidCallback onTap;
  final Color primaryColor;
  final bool isDark;
  final bool isAnswered;
  final bool isSelected;
  final bool isCorrectAnswer;
  final bool isFinalFailure;
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
    this.isFinalFailure = false,
    this.isCompact = false,
  });

  @override
  State<ArticleFloatingOrb> createState() => _ArticleFloatingOrbState();
}

class _ArticleFloatingOrbState extends State<ArticleFloatingOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _driftController;

  @override
  void initState() {
    super.initState();
    _driftController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 4 + widget.index),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDrift();
  }

  @override
  void didUpdateWidget(covariant ArticleFloatingOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnswered != oldWidget.isAnswered) {
      _updateDrift();
    }
  }

  void _updateDrift() {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    if (reduceMotion || widget.isAnswered) {
      if (_driftController.isAnimating) {
        _driftController.stop();
      }
    } else if (!_driftController.isAnimating) {
      _driftController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _driftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    Color textColor;
    Color borderColor;
    List<Color> gradientColors;
    double opacity = 1.0;
    List<BoxShadow> shadows = [];

    if (!widget.isAnswered) {
      textColor = Theme.of(context).colorScheme.onSurface;
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
          textColor = tokens.gameCorrect;
          borderColor = tokens.gameCorrect;
          gradientColors = [
            tokens.gameCorrect.withValues(alpha: 0.3),
            tokens.gameCorrect.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ];
          shadows = [
            BoxShadow(
              color: tokens.gameCorrect.withValues(alpha: 0.3),
              blurRadius: 25,
              spreadRadius: 4,
            ),
          ];
        } else {
          textColor = tokens.gameIncorrect;
          borderColor = tokens.gameIncorrect;
          gradientColors = [
            tokens.gameIncorrect.withValues(alpha: 0.3),
            tokens.gameIncorrect.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ];
          shadows = [
            BoxShadow(
              color: tokens.gameIncorrect.withValues(alpha: 0.3),
              blurRadius: 25,
              spreadRadius: 4,
            ),
          ];
        }
      } else if (widget.isCorrectAnswer && widget.isFinalFailure) {
        textColor = tokens.gameCorrect;
        borderColor = tokens.gameCorrect.withValues(alpha: 0.6);
        gradientColors = [
          tokens.gameCorrect.withValues(alpha: 0.15),
          tokens.gameCorrect.withValues(alpha: 0.05),
          Colors.transparent,
        ];
        shadows = [
          BoxShadow(
            color: tokens.gameCorrect.withValues(alpha: 0.15),
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

    Widget orbContent = Container(
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
          widget.article.toLowerCase() == "(no article)"
              ? "Ø"
              : widget.article.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: widget.isCompact ? 14.sp : 18.sp,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
      ),
    );

    if (!reduceMotion && !widget.isAnswered) {
      orbContent = orbContent
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.08, 1.08),
            duration: 2500.ms,
            curve: Curves.easeInOutSine,
          );
    }

    return AnimatedBuilder(
      animation: _driftController,
      builder: (context, child) {
        return Transform.translate(
          offset: (reduceMotion || widget.isAnswered)
              ? Offset.zero
              : Offset(
                  12.w * (1 - _driftController.value),
                  15.h * _driftController.value,
                ),
          child: Opacity(
            opacity: opacity,
            child: ScaleButton(
              key: ValueKey('article_orb_${widget.index}'),
              onTap: widget.isAnswered ? null : widget.onTap,
              child: orbContent,
            ),
          ),
        );
      },
    );
  }
}
