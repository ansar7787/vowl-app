import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color07070f = Color(0xFF07070F);
}

class EmergencyHubTerminalInput extends StatelessWidget {
  final TextEditingController controller;
  final String correctAnswer;
  final bool isDark;
  final VoidCallback onChanged;

  const EmergencyHubTerminalInput({
    super.key,
    required this.controller,
    required this.correctAnswer,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final bool isCodeValid =
        controller.text.trim().replaceAll(' ', '').toLowerCase() ==
        correctAnswer.trim().replaceAll(' ', '').toLowerCase();

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: isDark
            ? _LocalPalette.color07070f
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "DECRYPTION KEYBOARD SLATE",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  color: isCodeValid ? tokens.gameCorrect : Colors.amberAccent,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                isCodeValid ? Icons.vpn_key_rounded : Icons.keyboard_rounded,
                color: isCodeValid ? tokens.gameCorrect : Colors.amberAccent,
                size: 16.r,
              ),
            ],
          ),
          SizedBox(height: 12.h),

          TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18.sp,
              color: isCodeValid ? tokens.gameCorrect : tokens.gameIncorrect,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              hintText: "ENTER CODE (e.g. CODE RED 99)",
              hintStyle: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                color: isDark ? Colors.white24 : Colors.black26,
                letterSpacing: 1.5,
              ),
              filled: true,
              fillColor: isDark ? AppColors.deepDark : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: isCodeValid
                      ? tokens.gameCorrect.withValues(alpha: 0.4)
                      : tokens.gameIncorrect.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: isCodeValid
                      ? tokens.gameCorrect
                      : tokens.gameIncorrect,
                  width: 2,
                ),
              ),
              prefixIcon: Icon(
                Icons.terminal_rounded,
                color: isCodeValid ? tokens.gameCorrect : tokens.gameIncorrect,
                size: 20.r,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
