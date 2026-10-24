import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color1a1a1a = Color(0xFF1A1A1A);
}

/// Header instruction component for True/False audio challenges.
class AudioTrueFalseInstruction extends StatelessWidget {
  /// Theme accent color.
  final Color color;

  /// Instruction prompt text.
  final String instruction;

  /// Creates an [AudioTrueFalseInstruction] badge.
  const AudioTrueFalseInstruction({
    super.key,
    required this.color,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String mainText = instruction.trim();
    String subText = '';

    if (mainText.isEmpty) {
      mainText = 'Is this statement True or False?';
      subText = 'Listen carefully.';
    } else {
      // Replace AI buzzwords with natural, human-friendly guidance
      final sanitized = mainText.replaceAll(
        RegExp(r'\bYou make the call\.?', caseSensitive: false),
        'Listen carefully.',
      );

      final match = RegExp(r'([.?!])\s+(.*)').firstMatch(sanitized);
      if (match != null) {
        mainText = sanitized.substring(0, match.start + 1);
        subText = match.group(2) ?? '';
      } else {
        mainText = sanitized;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          mainText,
          key: const Key('audio_true_false_instruction_main'),
          textAlign: TextAlign.center,
          softWrap: true,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : _LocalPalette.color1a1a1a,
            letterSpacing: -0.2,
            height: 1.3,
          ),
        ),
        if (subText.isNotEmpty) ...[
          SizedBox(height: 6.h),
          Text(
            subText,
            key: const Key('audio_true_false_instruction_sub'),
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.75)
                  : const Color(0xFF475569),
              letterSpacing: 0.1,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}
