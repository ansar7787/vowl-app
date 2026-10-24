import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Text input alternative allowing users to type sentences directly.
class SentenceBuilderKeyboardInput extends StatefulWidget {
  /// Text editing controller managing typed sentence input.
  final TextEditingController controller;

  /// Theme accent color applied to focus borders.
  final Color color;

  /// Whether the active theme is in dark mode.
  final bool isDark;

  /// Creates a [SentenceBuilderKeyboardInput] widget.
  const SentenceBuilderKeyboardInput({
    super.key,
    required this.controller,
    required this.color,
    required this.isDark,
  });

  @override
  State<SentenceBuilderKeyboardInput> createState() =>
      _SentenceBuilderKeyboardInputState();
}

class _SentenceBuilderKeyboardInputState
    extends State<SentenceBuilderKeyboardInput> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : AppColors.slate900;
    final hintColor = widget.isDark ? Colors.white38 : Colors.black38;
    final isFocused = _focusNode.hasFocus;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.black.withValues(alpha: 0.25)
            : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isFocused
              ? widget.color
              : widget.color.withValues(alpha: 0.25),
          width: isFocused ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(
              alpha: widget.isDark ? (isFocused ? 0.15 : 0.05) : (isFocused ? 0.12 : 0.05),
            ),
            blurRadius: isFocused ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        key: const Key('sentence_builder_text_field'),
        controller: widget.controller,
        focusNode: _focusNode,
        minLines: 3,
        maxLines: 5,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.sentences,
        cursorColor: widget.color,
        cursorWidth: 2.0,
        cursorRadius: Radius.circular(2.r),
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
          height: 1.4,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "Type the complete sentence here...",
          hintStyle: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 15.sp,
            fontWeight: FontWeight.w400,
            color: hintColor,
            height: 1.4,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 18.w,
            vertical: 18.h,
          ),
        ),
      ),
    );
  }
}
