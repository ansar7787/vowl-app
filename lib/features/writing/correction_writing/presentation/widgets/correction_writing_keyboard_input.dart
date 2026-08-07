import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class CorrectionWritingKeyboardInput extends StatefulWidget {
  final Color color;
  final bool isDark;
  final ValueChanged<String> onSubmit;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "RETYPE THE CORRECTED SENTENCE:",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: widget.isDark ? Colors.white70 : Colors.black54,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.grey[850] : Colors.grey[200],
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
                  controller: _controller,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    color: widget.isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Type the full sentence here...",
                    hintStyle: TextStyle(
                      fontFamily: 'Outfit',
                      color: widget.isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  onSubmitted: (_) => _submitInput(),
                ),
              ),
              ScaleButton(
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
                    size: 24.sp,
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
