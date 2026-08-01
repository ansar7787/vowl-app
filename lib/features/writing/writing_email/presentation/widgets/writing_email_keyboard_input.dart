import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/custom_snack_bar.dart';

class WritingEmailKeyboardInput extends StatefulWidget {
  final List<String> validOptions;
  final Color color;
  final bool isDark;
  final Function(String) onValidInput;

  const WritingEmailKeyboardInput({
    super.key,
    required this.validOptions,
    required this.color,
    required this.isDark,
    required this.onValidInput,
  });

  @override
  State<WritingEmailKeyboardInput> createState() =>
      _WritingEmailKeyboardInputState();
}

class _WritingEmailKeyboardInputState extends State<WritingEmailKeyboardInput> {
  final _controller = TextEditingController();
  final _hapticService = di.sl<HapticService>();

  void _submitInput() {
    final rawText = _controller.text.trim();
    if (rawText.isEmpty) return;

    if (!RegExp(r'^[A-Z]').hasMatch(rawText)) {
      CustomSnackBar.show(
        context: context,
        message: "Please start your sentence with a capital letter.",
        type: CustomSnackBarType.warning,
      );
      _hapticService.selection();
      return;
    }

    final normalizedInput = _normalizeString(rawText);

    String? matchedOption;
    for (final option in widget.validOptions) {
      if (_normalizeString(option) == normalizedInput) {
        matchedOption = option;
        break;
      }
    }

    if (matchedOption != null) {
      _hapticService.success();
      widget.onValidInput(matchedOption);
      _controller.clear();
      FocusScope.of(context).unfocus();
    } else {
      _hapticService.error();
      CustomSnackBar.show(
        context: context,
        message: "That doesn't quite match any of the required email parts. Check your spelling!",
        type: CustomSnackBarType.warning,
      );
    }
  }

  String _normalizeString(String str) {
    return str
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ''); // Remove all whitespace
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
          "TYPE THE NEXT EMAIL PART:",
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
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Type your answer here...",
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
