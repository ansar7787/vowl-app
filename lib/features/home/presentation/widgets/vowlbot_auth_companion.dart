import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/utils/vowl_assets.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Interactive mascot companion for auth screens.
///
/// ### Design philosophy
/// - The mascot reacts to which field is focused with a contextual speech bubble.
/// - When the keyboard opens, the mascot shrinks and the speech bubble
///   repositions to stay visible without clipping.
/// - Text in the speech bubble NEVER uses ellipsis — it uses [FittedBox]
///   with [BoxFit.scaleDown] to guarantee 100% visibility.
///
/// ### Architecture
/// - Uses [ListenableBuilder] on focus nodes — zero setState.
/// - [SpeechBubblePainter] properly repaints when theme colors change.
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
    this.size = 60,
    this.isSignup = false,
    this.isForgotPassword = false,
  });

  @override
  State<VowlBotAuthCompanion> createState() => _VowlBotAuthCompanionState();
}

class _VowlBotAuthCompanionState extends State<VowlBotAuthCompanion> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(const AssetImage(VowlAssets.vowlbotHappy), context);
      precacheImage(const AssetImage(VowlAssets.vowlbotThinking), context);
      precacheImage(const AssetImage(VowlAssets.vowlbotWorried), context);
    });
  }

  String _getGreeting(BuildContext context) {
    // 1. Password (Universal)
    if (widget.passwordFocus?.hasFocus ?? false) {
      return context.tr(
        'auth_companion.password_focus',
        fallback: "I'm not looking!",
      );
    }

    // 2. Email (Contextual)
    if (widget.emailFocus?.hasFocus ?? false) {
      if (widget.isSignup) {
        return context.tr(
          'auth_companion.email_focus_signup',
          fallback: 'Your best email',
        );
      }
      if (widget.isForgotPassword) {
        return context.tr(
          'auth_companion.email_focus_forgot',
          fallback: 'Where should we send it?',
        );
      }
      return context.tr(
        'auth_companion.email_focus_signin',
        fallback: 'Welcome back!',
      );
    }

    // 3. Name (Signup only)
    if (widget.nameFocus?.hasFocus ?? false) {
      return widget.nameValue.isEmpty
          ? context.tr(
              'auth_companion.name_focus_empty',
              fallback: "What's your name?",
            )
          : context.tr(
              'auth_companion.name_focus_filled',
              fallback: 'Great name!',
            );
    }

    // Default (No Focus) - Mascot acts as the page subtitle
    if (widget.isSignup) {
      return context.tr(
        'auth_companion.default_signup',
        fallback: 'Begin your learning adventure.',
      );
    }
    if (widget.isForgotPassword) {
      return context.tr(
        'auth_companion.default_forgot',
        fallback: "Let's get you back on track.",
      );
    }
    return context.tr(
      'auth_companion.default_login',
      fallback: 'Ready to continue your journey?',
    );
  }

  @override
  Widget build(BuildContext context) {
    final listenables = [
      if (widget.nameFocus != null) widget.nameFocus!,
      if (widget.emailFocus != null) widget.emailFocus!,
      if (widget.passwordFocus != null) widget.passwordFocus!,
    ];

    return listenables.isEmpty
        ? _buildContent(context)
        : ListenableBuilder(
            listenable: Listenable.merge(listenables),
            builder: (context, _) => _buildContent(context),
          );
  }

  Widget _buildContent(BuildContext context) {
    String currentAsset = VowlAssets.vowlbotHappy;
    if (widget.passwordFocus?.hasFocus ?? false) {
      currentAsset = VowlAssets.vowlbotWorried;
    } else if (widget.emailFocus?.hasFocus ?? false) {
      currentAsset = VowlAssets.vowlbotThinking;
    } else if (widget.nameFocus?.hasFocus ?? false) {
      currentAsset = VowlAssets.vowlbotHappy;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Adaptive Colors based on Theme
    final bubbleColor = isDark
        ? Colors.black.withValues(alpha: 0.75)
        : Colors.white.withValues(alpha: 0.85);
    final textColor = isDark ? Colors.white : Colors.black87;
    final borderColor = const Color(
      0xFF6366F1,
    ); // Primary Indigo for neon-glass effect
    final greeting = _getGreeting(context);

    // BUG FIX: Use .r for symmetric scaling to prevent squashing on
    // non-standard aspect ratios (tablets, foldables, landscape).
    return SizedBox(
      height: widget.size.r,
      width: widget.size.r,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. The Mascot
          Semantics(
            label: context.tr(
              'auth_companion.mascot_label',
              fallback: 'Vowl companion',
            ),
            image: true,
            child: Image.asset(currentAsset, height: widget.size.r),
          ),

          // 2. Adaptive Speech Bubble — perfectly centered above the mascot
          //    to maintain Diamond Standard vertical symmetry and focus.
          Positioned(
            bottom: widget.size.r * 0.9,
            child:
                CustomPaint(
                      painter: SpeechBubblePainter(
                        color: bubbleColor,
                        borderColor: borderColor,
                      ),
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: 60.w,
                          maxWidth: 160.w,
                        ),
                        padding: EdgeInsets.fromLTRB(16.w, 8, 16.w, 18),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            greeting,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: textColor,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ),
                    )
                    .animate(key: ValueKey(greeting))
                    .fade(duration: 300.ms)
                    .scale(
                      begin: const Offset(0.4, 0.4),
                      curve: Curves.elasticOut,
                      duration: 1000.ms,
                      alignment: Alignment.bottomCenter,
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
          .withValues(alpha: 0.6) // Premium translucent border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final fullPath = Path();
    final bubbleHeight = size.height - 10; // Sleek 10px tail

    // Safety clamp: ensure radius is never larger than half the shortest side
    // to prevent the bezier path from inverting/crossing itself on tiny screens.
    final r = 12.0.clamp(0.0, bubbleHeight / 2);

    // Start at Top-Left, just after the corner radius
    fullPath.moveTo(r, 0);

    // Top Edge
    fullPath.lineTo(size.width - r, 0);

    // Top-Right Corner
    fullPath.quadraticBezierTo(size.width, 0, size.width, r);

    // Right Edge
    fullPath.lineTo(size.width, bubbleHeight - r);

    // Bottom-Right Corner
    fullPath.quadraticBezierTo(
      size.width,
      bubbleHeight,
      size.width - r,
      bubbleHeight,
    );

    // Bottom Edge (Right of tail)
    fullPath.lineTo(size.width / 2 + 12, bubbleHeight);

    // The "Liquid Tail" - mathematically continuous bezier curves (Swoop Down)
    fullPath.cubicTo(
      size.width / 2 + 6,
      bubbleHeight, // Control 1
      size.width / 2 + 2,
      bubbleHeight + 10, // Control 2
      size.width / 2,
      bubbleHeight + 10, // Tail tip (Dead center, 10px down)
    );

    // The "Liquid Tail" - mathematically continuous bezier curves (Swoop Up)
    fullPath.cubicTo(
      size.width / 2 - 2,
      bubbleHeight + 10, // Control 1
      size.width / 2 - 6,
      bubbleHeight, // Control 2
      size.width / 2 - 12,
      bubbleHeight, // Melt point (Left of tail)
    );

    // Bottom Edge (Left of tail)
    fullPath.lineTo(r, bubbleHeight);

    // Bottom-Left Corner
    fullPath.quadraticBezierTo(0, bubbleHeight, 0, bubbleHeight - r);

    // Left Edge
    fullPath.lineTo(0, r);

    // Top-Left Corner
    fullPath.quadraticBezierTo(0, 0, r, 0);

    fullPath.close();

    // 4. Draw Premium Drop Shadows (3D depth)
    // Ambient colored glow
    canvas.save();
    canvas.translate(0, 8);
    canvas.drawPath(
      fullPath,
      Paint()
        ..color = borderColor.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0),
    );
    canvas.restore();

    // Direct soft contact shadow
    canvas.save();
    canvas.translate(0, 3);
    canvas.drawPath(
      fullPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
    );
    canvas.restore();

    // 5. Draw the actual bubble and border
    canvas.drawPath(fullPath, paint);
    canvas.drawPath(fullPath, borderPaint);
  }

  // FIX: Properly repaint when theme colors change (e.g., dark↔light switch
  // while the bubble is visible).
  @override
  bool shouldRepaint(covariant SpeechBubblePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.borderColor != borderColor;
}
