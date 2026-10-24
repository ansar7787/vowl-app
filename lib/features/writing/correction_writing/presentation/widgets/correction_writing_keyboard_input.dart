import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Full-sentence keyboard input widget for rewriting sentences on hard mode.
class CorrectionWritingKeyboardInput extends StatefulWidget {
  /// Theme accent color.
  final Color color;

  /// Whether dark theme styling should be applied.
  final bool isDark;

  /// Callback receiving the submitted corrected sentence string.
  final ValueChanged<String> onSubmit;

  /// Creates a [CorrectionWritingKeyboardInput] field.
  const CorrectionWritingKeyboardInput({
    super.key,
    required this.color,
    required this.isDark,
    required this.onSubmit,
  });

  @override
  State<CorrectionWritingKeyboardInput> createState() =>
      _CorrectionWritingKeyboardInputState();
}

class _CorrectionWritingKeyboardInputState
    extends State<CorrectionWritingKeyboardInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  void _submitInput() {
    final rawText = _controller.text.trim();
    if (rawText.isEmpty) return;

    widget.onSubmit(rawText);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(
            'games.correctionWriting.type_sentence',
            fallback: "Type the corrected sentence",
          ),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.75)
                : Colors.black87.withValues(alpha: 0.7),
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('correction_keyboard_input_field'),
                  controller: _controller,
                  focusNode: _focusNode,
                  onTap: () {
                    if (_focusNode.hasFocus) {
                      SystemChannels.textInput.invokeMethod('TextInput.show');
                    }
                  },
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: widget.isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: context.tr(
                      'games.correctionWriting.hint_full_sentence',
                      fallback: "Type the full sentence here...",
                    ),
                    hintStyle: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      color: widget.isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  onSubmitted: (_) => _submitInput(),
                ),
              ),
              SizedBox(width: 8.w),
              ScaleButton(
                key: const Key('correction_keyboard_submit_button'),
                onTap: _submitInput,
                child: Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.white,
                    size: 22.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

