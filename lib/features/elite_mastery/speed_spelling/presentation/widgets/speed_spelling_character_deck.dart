import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

class SpeedSpellingCharacterDeck extends StatelessWidget {
  final List<String> shuffledChars;
  final bool isDark;
  final Function(String char, int index) onCharTap;

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

        // FIX: each tile previously had no Semantics at all. A sighted
        // player can see which tiles are dimmed (already used) versus
        // solid (available); a screen-reader user got nothing — not even
        // confirmation that this was a letter tile rather than decoration.
        return Semantics(
          button: isAvailable,
          enabled: isAvailable,
          label: isAvailable
              ? context.tr('games.semantic_letter_tile', args: [char])
              : context.tr('games.semantic_letter_tile_used'),
          excludeSemantics: true,
          child: ScaleButton(
            onTap: char == "" ? null : () => onCharTap(char, index),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: char == "" ? 0.3 : 1.0,
              child: Container(
                width: 54.r,
                height: 54.r,
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
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
