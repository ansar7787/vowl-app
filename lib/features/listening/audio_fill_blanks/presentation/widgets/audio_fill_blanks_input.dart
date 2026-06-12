import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// =============================================================================
// AudioFillBlanksInput
// =============================================================================

class AudioFillBlanksInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isAnswered;
  final Color primaryColor;
  final int maxLength;
  final ValueChanged<String>? onSubmitted;

  const AudioFillBlanksInput({
    super.key,
    required this.controller,
    required this.isAnswered,
    required this.primaryColor,
    this.maxLength = 120,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: isAnswered
          ? 'Transcription submitted: ${controller.text}'
          : 'Transcription input. Type the missing audio data.',
      child: TextField(
        controller: controller,
        enabled: !isAnswered,
        textAlign: TextAlign.center,
        textInputAction: TextInputAction.done,
        keyboardType: TextInputType.text,
        // Prevent autocorrect silently changing the player's answer.
        autocorrect: false,
        enableSuggestions: false,
        // Enforce max length without showing the built-in counter.
        maxLength: maxLength,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
        inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
        onSubmitted: onSubmitted,
        style: TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 22.sp,
          fontWeight: FontWeight.w900,
          color: primaryColor,
        ),
        decoration: InputDecoration(
          // Hide the character counter to keep the UI clean.
          counterText: '',
          hintText: 'TYPE THE MISSING DATA',
          hintStyle: TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 14.sp,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.2)),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          // FIX: explicit disabled style so the field looks intentionally
          // locked after answering, not broken / default-grey.
          disabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.1)),
          ),
        ),
      ),
    );
  }
}
