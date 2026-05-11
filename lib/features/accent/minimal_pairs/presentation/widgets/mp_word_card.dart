import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  MpWordCard — Tap card showing word + IPA with dynamic color states
// ═══════════════════════════════════════════════════════════════════════════

class MpWordCard extends StatelessWidget {
  final String word;
  final int index;
  final String correctWord;
  final int? selectedIndex;
  final List<int> eliminated;
  final bool isDark;
  final ThemeResult theme;
  final bool isMidnight;
  final void Function(int index, String word) onTap;
  final String? ipa;

  const MpWordCard({
    super.key,
    required this.word,
    required this.index,
    required this.correctWord,
    required this.selectedIndex,
    required this.eliminated,
    required this.isDark,
    required this.theme,
    required this.onTap,
    this.ipa,
    this.isMidnight = false,
  });

  static const _green = Color(0xFF10B981);
  static const _red = Color(0xFFF43F5E);

  static final _wordStyle = GoogleFonts.outfit(
    fontWeight: FontWeight.w900,
    letterSpacing: 1.5,
  );
  static final _ipaStyle = GoogleFonts.notoSans(fontWeight: FontWeight.w500);

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;
    final isElim = eliminated.contains(index);
    final isCorrect =
        word.trim().toLowerCase() == correctWord.trim().toLowerCase();
    final showResult = selectedIndex != null;
    final ipaText = ipa ?? '';

    final (Color bg, Color border, Color text) = _resolveColors(
      isElim: isElim,
      showResult: showResult,
      isSelected: isSelected,
      isCorrect: isCorrect,
    );

    return ScaleButton(
          onTap: (selectedIndex == null && !isElim)
              ? () => onTap(index, word)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 12.w),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: border, width: 2),
              boxShadow: [
                if (!isElim)
                  BoxShadow(
                    color: (showResult && isSelected)
                        ? (isCorrect
                              ? _green.withValues(alpha: 0.2)
                              : _red.withValues(alpha: 0.15))
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: Opacity(
              opacity: isElim ? 0.3 : 1.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Result icon
                  if (showResult && isSelected) ...[
                    Icon(
                      isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: isCorrect ? _green : _red,
                      size: 28.r,
                    ).animate().scale(
                      duration: 300.ms,
                      curve: Curves.easeOutBack,
                    ),
                    SizedBox(height: 8.h),
                  ],

                  // Word text
                  Text(
                    word.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: _wordStyle.copyWith(fontSize: 20.sp, color: text),
                  ),

                  // IPA transcription
                  if (ipaText.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(
                      ipaText,
                      style: _ipaStyle.copyWith(
                        fontSize: 14.sp,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        )
        .animate(
          effects: [
            if (showResult && isSelected && !isCorrect)
              ShakeEffect(duration: 500.ms, hz: 4, offset: const Offset(6, 0)),
            if (showResult && isSelected && isCorrect)
              ScaleEffect(
                duration: 300.ms,
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.05, 1.05),
                curve: Curves.easeOutBack,
              ),
          ],
        )
        .animate(onPlay: (c) => c.forward())
        .fadeIn(delay: (index * 150).ms, duration: 400.ms)
        .slideY(begin: 0.15, duration: 400.ms, delay: (index * 150).ms);
  }

  /// Pure function — resolves card colors based on state.
  (Color, Color, Color) _resolveColors({
    required bool isElim,
    required bool showResult,
    required bool isSelected,
    required bool isCorrect,
  }) {
    if (isElim) {
      return (
        isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.03),
        Colors.transparent,
        isDark ? Colors.white24 : Colors.black26,
      );
    }
    if (showResult && isSelected && isCorrect) {
      return (_green.withValues(alpha: 0.15), _green, _green);
    }
    if (showResult && isSelected && !isCorrect) {
      return (_red.withValues(alpha: 0.12), _red, _red);
    }
    return (
      isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
      theme.primaryColor.withValues(alpha: 0.2),
      isDark ? Colors.white : Colors.black87,
    );
  }
}
