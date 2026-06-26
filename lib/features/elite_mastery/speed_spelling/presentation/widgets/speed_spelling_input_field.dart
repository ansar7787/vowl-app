import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

class SpeedSpellingInputField extends StatelessWidget {
  final String currentInput;
  final bool isAnswered;
  final bool? isCorrect;
  final int attempts;
  final bool isDark;
  final Color primaryColor;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  const SpeedSpellingInputField({
    super.key,
    required this.currentInput,
    required this.isAnswered,
    this.isCorrect,
    required this.attempts,
    required this.isDark,
    required this.primaryColor,
    required this.onBackspace,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final showCorrectGlow = isCorrect == true;

    return Container(
      height: 100.h,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: showCorrectGlow
            ? LinearGradient(
                colors: [
                  Colors.greenAccent.withValues(alpha: 0.2),
                  Colors.greenAccent.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.black.withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: (isAnswered || (isCorrect == false && attempts > 0))
              ? (isCorrect == true
                    ? Colors.greenAccent.withValues(alpha: 0.6)
                    : Colors.redAccent.withValues(alpha: 0.6))
              : (isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.1)),
          width: 2.5,
        ),
        boxShadow: showCorrectGlow
            ? [
                BoxShadow(
                  color: Colors.greenAccent.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: -5,
                ),
              ]
            : [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 90.w, // Safe space for Backspace + Clear buttons
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                // FIX: nothing here previously told a screen-reader user
                // what they'd spelled so far — the only feedback was visual.
                // `liveRegion: true` announces the running input every time
                // it changes, which matters more for this game than most:
                // there's no other way to know what's been typed without
                // sight, since the deck shows letters, not the built word.
                child: Semantics(
                  liveRegion: true,
                  label: currentInput.isEmpty
                      ? context.tr('games.semantic_spelling_empty')
                      : context.tr(
                          'games.semantic_current_spelling',
                          args: [currentInput],
                        ),
                  excludeSemantics: true,
                  child: Text(
                    currentInput,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 36.sp,
                      fontWeight: FontWeight.w900,
                      color: showCorrectGlow
                          ? Colors.greenAccent
                          : (isDark ? primaryColor : const Color(0xFF0F172A)),
                      letterSpacing: 6,
                      shadows: showCorrectGlow
                          ? [
                              Shadow(
                                color: Colors.greenAccent.withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 20,
                              ),
                            ]
                          : [],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (currentInput.isNotEmpty && !isAnswered)
            Positioned(
              right: 12.w,
              top: 0,
              bottom: 0,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      button: true,
                      label: context.tr('games.semantic_backspace'),
                      excludeSemantics: true,
                      child: ScaleButton(
                        onTap: onBackspace,
                        child: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.backspace_rounded,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            size: 18.r,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Semantics(
                      button: true,
                      label: context.tr('games.semantic_clear_input'),
                      excludeSemantics: true,
                      child: ScaleButton(
                        onTap: onClear,
                        child: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.refresh_rounded,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            size: 18.r,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
