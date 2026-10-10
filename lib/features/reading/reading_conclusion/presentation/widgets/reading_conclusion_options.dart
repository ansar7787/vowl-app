import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class ReadingConclusionOptions extends StatelessWidget {
  final List<String> options;
  final String correct;
  final Color primaryColor;
  final bool isDark;
  final int? selectedIndex;
  final bool isAnswered;
  final Function(int, String) onOptionTap;

  const ReadingConclusionOptions({
    super.key,
    required this.options,
    required this.correct,
    required this.primaryColor,
    required this.isDark,
    required this.selectedIndex,
    required this.isAnswered,
    required this.onOptionTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;

    return Column(
      children: List.generate(options.length, (index) {
        final optionText = options[index];
        final isSelected = selectedIndex == index;
        final isCorrect =
            isAnswered &&
            optionText.trim().toLowerCase() == correct.trim().toLowerCase();
        final isWrong = isAnswered && isSelected && !isCorrect;

        return _OptionCard(
          key: ValueKey(
            optionText,
          ), // ensure unique state reset per option text
          optionText: optionText,
          isSelected: isSelected,
          isCorrect: isCorrect,
          isWrong: isWrong,
          primaryColor: primaryColor,
          isDark: isDark,
          isAnswered: isAnswered,
          tokens: tokens,
          onTap: () {
            if (!isAnswered) {
              di.sl<HapticService>().selection();
              onOptionTap(index, optionText);
            }
          },
        );
      }),
    );
  }
}

class _OptionCard extends StatefulWidget {
  final String optionText;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final Color primaryColor;
  final bool isDark;
  final bool isAnswered;
  final AppColorTokens tokens;
  final VoidCallback onTap;

  const _OptionCard({
    super.key,
    required this.optionText,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.primaryColor,
    required this.isDark,
    required this.isAnswered,
    required this.tokens,
    required this.onTap,
  });

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;

    if (widget.isCorrect) {
      bgColor = widget.tokens.gameCorrect.withValues(alpha: 0.15);
      borderColor = widget.tokens.gameCorrect;
    } else if (widget.isWrong) {
      bgColor = widget.tokens.gameIncorrect.withValues(alpha: 0.15);
      borderColor = widget.tokens.gameIncorrect;
    } else if (widget.isSelected) {
      bgColor = widget.primaryColor.withValues(alpha: 0.15);
      borderColor = widget.primaryColor;
    } else {
      bgColor = widget.isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03);
      borderColor = widget.isDark
          ? Colors.white.withValues(alpha: 0.15)
          : Colors.black.withValues(alpha: 0.1);
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          if (!widget.isAnswered) {
            setState(() => _isPressed = true);
          }
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
        },
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutQuad,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                if (widget.isCorrect || widget.isWrong || widget.isSelected)
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Text(
              widget.optionText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
