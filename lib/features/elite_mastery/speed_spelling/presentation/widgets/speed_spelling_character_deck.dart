import 'package:vowl/core/theme/app_colors.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

class SpeedSpellingCharacterDeck extends StatelessWidget {
  final List<String> shuffledChars;
  final bool isDark;
  final void Function(String char, int index) onCharTap;

  const SpeedSpellingCharacterDeck({
    super.key,
    required this.shuffledChars,
    required this.isDark,
    required this.onCharTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      alignment: WrapAlignment.center,
      children: List.generate(shuffledChars.length, (index) {
        final char = shuffledChars[index];
        final isAvailable = char != "";

        return Semantics(
          button: isAvailable,
          enabled: isAvailable,
          label: isAvailable
              ? context.tr(
                  'games.semantic_letter_tile',
                  fallback: 'Letter Tile',
                  args: [char],
                )
              : context.tr(
                  'games.semantic_letter_tile_used',
                  fallback: 'Used Letter Tile',
                ),
          excludeSemantics: true,
          child: ScaleButton(
            scaleDown: 0.9,
            debounceDuration: const Duration(milliseconds: 50),
            onTap: char == "" ? null : () => onCharTap(char, index),
            child:
                Container(
                      width: math.max(54.r, 48.0),
                      height: math.max(54.r, 48.0),
                      decoration: BoxDecoration(
                        color: char == ""
                            ? (isDark
                                  ? Colors.white.withValues(alpha: 0.02)
                                  : Colors.black.withValues(alpha: 0.02))
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.white),
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(
                          color: char == ""
                              ? (isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.05))
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : Colors.black.withValues(alpha: 0.08)),
                          width: 1.5,
                        ),
                        boxShadow: char == ""
                            ? []
                            : [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.3)
                                      : Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                      ),
                      child: Center(
                        child: Text(
                          char,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.slate800,
                          ),
                        ),
                      ),
                    )
                    .animate(target: char == "" ? 1 : 0)
                    .scaleXY(
                      begin: 1.0,
                      end: 0.8,
                      duration: 250.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fade(begin: 1.0, end: 0.3, duration: 200.ms),
          ),
        );
      }),
    );
  }
}
