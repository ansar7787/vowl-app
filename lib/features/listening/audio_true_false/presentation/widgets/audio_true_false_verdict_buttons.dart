import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_colors.dart';

class AudioTrueFalseVerdictButtons extends StatelessWidget {
  final bool? selectedVerdict;
  final bool isAnswered;
  final bool? isCorrectState;
  final Function(bool) onVerdictSelected;

  const AudioTrueFalseVerdictButtons({
    super.key,
    required this.selectedVerdict,
    required this.isAnswered,
    required this.isCorrectState,
    required this.onVerdictSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return Row(
      children: [
        Expanded(
          child: _buildButton(
            context,
            false,
            "FALSE",
            Icons.close_rounded,
            tokens.gameIncorrect,
            const Key('audio_true_false_btn_false'),
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: _buildButton(
            context,
            true,
            "TRUE",
            Icons.check_rounded,
            tokens.gameCorrect,
            const Key('audio_true_false_btn_true'),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(
    BuildContext context,
    bool value,
    String label,
    IconData icon,
    Color baseColor,
    Key key,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selectedVerdict == value;
    final isCorrect = isAnswered && isSelected && isCorrectState == true;
    final isWrong = isAnswered && isSelected && isCorrectState == false;

    final Color buttonColor = isCorrect
        ? AppColors.gameCorrect
        : (isWrong
              ? AppColors.gameIncorrect
              : (isSelected
                    ? baseColor
                    : (isDark
                          ? baseColor.withValues(alpha: 0.12)
                          : baseColor.withValues(alpha: 0.08))));

    final Color contentColor = isSelected ? Colors.white : baseColor;

    return Semantics(
      label: label,
      button: true,
      selected: isSelected,
      excludeSemantics: true,
      child: ScaleButton(
        key: key,
        onTap: (isAnswered || selectedVerdict != null)
            ? null
            : () => onVerdictSelected(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: double.infinity,
          constraints: BoxConstraints(minHeight: 80.h),
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isSelected
                  ? baseColor
                  : baseColor.withValues(alpha: isDark ? 0.4 : 0.3),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: contentColor, size: 28.r),
              SizedBox(height: 6.h),
              Text(
                label,
                textAlign: TextAlign.center,
                softWrap: false,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: contentColor,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
