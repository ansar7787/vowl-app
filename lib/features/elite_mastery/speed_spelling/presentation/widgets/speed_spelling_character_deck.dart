import 'package:vowl/core/theme/app_colors.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Interactive wrap deck of character letter tiles for spelling construction.
class SpeedSpellingCharacterDeck extends StatelessWidget {
  /// Letter characters available in the deck.
  final List<String> shuffledChars;

  /// Whether dark theme is enabled.
  final bool isDark;

  /// Callback executed when a character tile is tapped.
  final void Function(String char, int index) onCharTap;

  /// Creates a [SpeedSpellingCharacterDeck].
  const SpeedSpellingCharacterDeck({
    super.key,
    required this.shuffledChars,
    required this.isDark,
    required this.onCharTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
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
                  fallback: 'Letter tile, already used',
                ),
          excludeSemantics: true,
          child: ScaleButton(
            key: Key('speed_spelling_tile_$index'),
            scaleDown: 0.9,
            debounceDuration: const Duration(milliseconds: 50),
            onTap: char == "" ? null : () => onCharTap(char, index),
            child:
                Container(
                      width: math.max(50.r, 48.0),
                      height: math.max(50.r, 48.0),
                      decoration: BoxDecoration(
                        color: char == ""
                            ? (isDark
                                  ? Colors.white.withValues(alpha: 0.03)
                                  : AppColors.slate100.withValues(alpha: 0.6))
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.white),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: char == ""
                              ? (isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : AppColors.slate200)
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : AppColors.slate200),
                          width: 1.2,
                        ),
                        boxShadow: char == ""
                            ? []
                            : [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.25)
                                      : Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Center(
                        child: Text(
                          char,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.slate800,
                          ),
                        ),
                      ),
                    )
                    .animate(target: char == "" ? 1 : 0)
                    .scaleXY(
                      begin: 1.0,
                      end: 0.85,
                      duration: 200.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fade(begin: 1.0, end: 0.35, duration: 200.ms),
          ),
        );
      }),
    );
  }
}
