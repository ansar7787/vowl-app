import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

/// Text field and submit button for typing in sentence completions on hard mode.
class CompleteSentenceKeyboardInput extends StatefulWidget {
  /// Theme accent color.
  final Color color;

  /// Whether dark theme styling should be applied.
  final bool isDark;

  /// Callback receiving the typed string submission.
  final ValueChanged<String> onFire;

  /// Creates a [CompleteSentenceKeyboardInput] field.
  const CompleteSentenceKeyboardInput({
    super.key,
    required this.color,
    required this.isDark,
    required this.onFire,
  });

  @override
  State<CompleteSentenceKeyboardInput> createState() =>
      _CompleteSentenceKeyboardInputState();
}

class _CompleteSentenceKeyboardInputState
    extends State<CompleteSentenceKeyboardInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  void _submitInput() {
    final rawText = _controller.text.trim();
    if (rawText.isEmpty) return;

    widget.onFire(rawText);
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
          "TYPE THE MISSING WORD:",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w600,
            color: widget.isDark ? Colors.white60 : Colors.black54,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.grey[850] : Colors.grey[100],
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('complete_sentence_input_field'),
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
                    fontSize: 15.5.sp,
                    fontWeight: FontWeight.w500,
                    color: widget.isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Type your answer here...",
                    hintStyle: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      color: widget.isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  onSubmitted: (_) => _submitInput(),
                ),
              ),
              Semantics(
                button: true,
                label: 'Submit answer',
                child: ScaleButton(
                  key: const Key('complete_sentence_submit_button'),
                  onTap: _submitInput,
                  child: Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 22.sp,
                    ),
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
