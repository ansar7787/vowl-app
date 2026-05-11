import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/utils/vowl_assets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class VowlBotAuthCompanion extends StatefulWidget {
  final FocusNode? nameFocus;
  final String nameValue;
  final FocusNode? emailFocus;
  final FocusNode? passwordFocus;
  final double size;
  final bool isSignup;
  final bool isForgotPassword;

  const VowlBotAuthCompanion({
    super.key,
    this.nameFocus,
    this.nameValue = "",
    this.emailFocus,
    this.passwordFocus,
    this.size = 60, // Default to 60 for better Row fit
    this.isSignup = false,
    this.isForgotPassword = false,
  });

  @override
  State<VowlBotAuthCompanion> createState() => _VowlBotAuthCompanionState();
}

class _VowlBotAuthCompanionState extends State<VowlBotAuthCompanion> {
  String _currentAsset = VowlAssets.vowlbotNeutral;

  @override
  void initState() {
    super.initState();
    widget.nameFocus?.addListener(_onFocusChange);
    widget.emailFocus?.addListener(_onFocusChange);
    widget.passwordFocus?.addListener(_onFocusChange);
    
    // Pre-cache all mascot emotions to prevent flickers on first use
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage(VowlAssets.vowlbotHappy), context);
      precacheImage(const AssetImage(VowlAssets.vowlbotNeutral), context);
      precacheImage(const AssetImage(VowlAssets.vowlbotThinking), context);
      precacheImage(const AssetImage(VowlAssets.vowlbotWorried), context);
    });
  }

  @override
  void dispose() {
    widget.nameFocus?.removeListener(_onFocusChange);
    widget.emailFocus?.removeListener(_onFocusChange);
    widget.passwordFocus?.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  void didUpdateWidget(VowlBotAuthCompanion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nameValue != widget.nameValue) {
      setState(() {});
    }
  }
  void _onFocusChange() {
    setState(() {
      if (widget.passwordFocus?.hasFocus ?? false) {
        _currentAsset = VowlAssets.vowlbotWorried;
      } else if (widget.emailFocus?.hasFocus ?? false) {
        _currentAsset = VowlAssets.vowlbotThinking;
      } else if (widget.nameFocus?.hasFocus ?? false) {
        _currentAsset = VowlAssets.vowlbotHappy;
      } else {
        _currentAsset = VowlAssets.vowlbotNeutral;
      }
    });
  }

  String _getGreeting() {
    // 1. Password (Universal)
    if (widget.passwordFocus?.hasFocus ?? false) return "I'm not looking! 🙈";

    // 2. Email (Contextual)
    if (widget.emailFocus?.hasFocus ?? false) {
      if (widget.isSignup) return "Choose your email! 📧";
      if (widget.isForgotPassword) return "Where to send it? 📧";
      return "Time to sign in! 📧";
    }

    // 3. Name (Signup only)
    if (widget.nameFocus?.hasFocus ?? false) {
      return widget.nameValue.isEmpty
          ? "Hello! What's your name? 👋"
          : "What a great name! ✨";
    }

    return "Ready for an adventure? ✨";
  }

  @override
  Widget build(BuildContext context) {
    final isFocused =
        (widget.nameFocus?.hasFocus ?? false) ||
        (widget.emailFocus?.hasFocus ?? false) ||
        (widget.passwordFocus?.hasFocus ?? false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Adaptive Colors based on Time of Day / Theme
    final bubbleColor = isDark
        ? Colors.black.withValues(alpha: 0.75)
        : Colors.white.withValues(alpha: 0.85);
    final textColor = isDark ? Colors.white : Colors.black87;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.1);

    return SizedBox(
      height: widget.size.h,
      width: widget.size.w,
      child: Stack(
        clipBehavior: Clip.none, // Allow bubble to float outside
        alignment: Alignment.center,
        children: [
          // 1. The Mascot (Static for performance)
          Image.asset(_currentAsset, height: widget.size.h),

          // 2. Adaptive Speech Bubble (Floating & Expanding)
          Positioned(
            top: -35.h, // Float above the mascot
            child: Visibility(
              visible: isFocused,
              child:
                  CustomPaint(
                        painter: SpeechBubblePainter(
                          color: bubbleColor,
                          borderColor: borderColor,
                        ),
                        child: Container(
                          constraints: BoxConstraints(
                            minWidth: 60.w,
                            maxWidth: 180.w,
                          ),
                          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 18.h),
                          child: Text(
                            _getGreeting(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: textColor,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .fade(duration: 300.ms)
                      .scale(
                        begin: const Offset(0.4, 0.4),
                        curve: Curves.elasticOut,
                        duration: 1000.ms,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

class SpeechBubblePainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  SpeechBubblePainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0; // Slightly thicker border

    final path = Path();
    final r = 50.0; // Perfect Pill Curves

    // Draw rounded rectangle (The Bubble)
    path.addRRect(
      RRect.fromLTRBR(0, 0, size.width, size.height - 10, Radius.circular(r)),
    );

    // Draw a "Friendly" rounded tail
    final tailPath = Path();
    tailPath.moveTo(size.width / 2 - 14, size.height - 10);
    tailPath.quadraticBezierTo(
      size.width / 2,
      size.height + 6,
      size.width / 2 + 14,
      size.height - 10,
    );

    final fullPath = Path.combine(PathOperation.union, path, tailPath);

    canvas.drawPath(fullPath, paint);
    canvas.drawPath(fullPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
